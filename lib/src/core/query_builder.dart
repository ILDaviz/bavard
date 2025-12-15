import 'dart:async';
import 'database_manager.dart';
import 'model.dart';
import 'exceptions.dart';

/// Fluent interface for constructing type-safe SQL queries and hydrating results into [Model] instances.
///
/// Abstracts raw SQL generation, manages parameter binding for security (SQL injection prevention),
/// and handles the object lifecycle (hydration, dirty checking initialization) and eager loading.
class QueryBuilder<T extends Model> {
  final String table;
  final T Function(Map<String, dynamic>) creator;

  /// Internal factory for empty instances (used during generic casting or hydration).
  final T Function() _instanceFactory;

  final List<Map<String, String>> _wheres = [];
  final List<dynamic> _bindings = [];
  final List<String> _joins = [];
  final List<String> _with = [];
  List<String> _columns = ['*'];

  final List<String> _groupBy = [];
  final List<Map<String, String>> _havings = [];
  final List<dynamic> _havingBindings = [];

  int? _offset;
  String? _orderBy;
  int? _limit;

  /// Validates [table] immediately to prevent identifier injection attacks.
  QueryBuilder(this.table, this.creator, {T Function()? instanceFactory})
    : _instanceFactory =
          instanceFactory ?? (() => creator(const {}).newInstance() as T) {
    _assertIdent(table, dotted: false, what: 'table name');
  }

  /// Returns the raw SQL string compiled from current state.
  String toSql() => _compileSql();

  static final RegExp _tableIdent = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static final RegExp _dottedIdent = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$',
  );

  static const Set<String> _allowedWhereOps = {
    '=',
    '!=',
    '<>',
    '>',
    '<',
    '>=',
    '<=',
    'LIKE',
    'NOT LIKE',
  };

  static const Set<String> _allowedJoinOps = {
    '=',
    '!=',
    '<>',
    '>',
    '<',
    '>=',
    '<=',
  };

  static const Set<String> _allowedHavingOps = {
    '=',
    '!=',
    '<>',
    '>',
    '<',
    '>=',
    '<=',
  };

  static String _op(String op) => op.trim().toUpperCase();

  /// Security Check: Ensures identifiers (tables, columns) match a strict regex.
  ///
  /// Necessary because identifiers cannot be parameterized in SQL, making them
  /// vulnerable to injection if not sanitized.
  static void _assertIdent(
    String v, {
    required bool dotted,
    required String what,
  }) {
    final ok = dotted ? _dottedIdent.hasMatch(v) : _tableIdent.hasMatch(v);
    if (!ok) {
      throw InvalidQueryException('Invalid $what: $v');
    }
  }

  // ---------------------------------------------------------------------------
  // WHERE CLAUSES (AND / OR)
  // ---------------------------------------------------------------------------

  /// Appends a condition to the query state.
  ///
  /// Validates [operator] against a whitelist to prevent logic injection.
  QueryBuilder<T> where(
    String column,
    dynamic value, {
    String operator = '=',
    String boolean = 'AND',
  }) {
    _assertIdent(column, dotted: true, what: 'column name');
    final op = _op(operator);
    if (!_allowedWhereOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for where: $operator');
    }

    _wheres.add({'type': boolean, 'sql': '$column $op ?'});
    _bindings.add(value);
    return this;
  }

  QueryBuilder<T> orWhere(
    String column,
    dynamic value, {
    String operator = '=',
  }) {
    return where(column, value, operator: operator, boolean: 'OR');
  }

  QueryBuilder<T> whereNull(String column, {String boolean = 'AND'}) {
    _assertIdent(column, dotted: true, what: 'column name');
    _wheres.add({'type': boolean, 'sql': '$column IS NULL'});
    return this;
  }

  QueryBuilder<T> orWhereNull(String column) {
    return whereNull(column, boolean: 'OR');
  }

  QueryBuilder<T> whereNotNull(String column, {String boolean = 'AND'}) {
    _assertIdent(column, dotted: true, what: 'column name');
    _wheres.add({'type': boolean, 'sql': '$column IS NOT NULL'});
    return this;
  }

  QueryBuilder<T> orWhereNotNull(String column) {
    return whereNotNull(column, boolean: 'OR');
  }

  /// Appends an `IN` clause.
  ///
  /// Optimization: If [values] is empty, generates `0 = 1` to short-circuit the query safely.
  QueryBuilder<T> whereIn(
    String column,
    List<dynamic> values, {
    String boolean = 'AND',
  }) {
    _assertIdent(column, dotted: true, what: 'column name');
    if (values.isEmpty) {
      _wheres.add({'type': boolean, 'sql': '0 = 1'});
      return this;
    }

    final placeholders = List.filled(values.length, '?').join(', ');
    _wheres.add({'type': boolean, 'sql': '$column IN ($placeholders)'});
    _bindings.addAll(values);
    return this;
  }

  QueryBuilder<T> orWhereIn(String column, List<dynamic> values) {
    return whereIn(column, values, boolean: 'OR');
  }

  /// Nested query support via `EXISTS`.
  ///
  /// Merges the bindings of the sub-query [query] into the parent builder.
  QueryBuilder<T> whereExists(
    QueryBuilder query, {
    String boolean = 'AND',
    bool not = false,
  }) {
    final type = not ? 'NOT EXISTS' : 'EXISTS';
    final subSql = query.toSql();

    _wheres.add({'type': boolean, 'sql': '$type ($subSql)'});

    _bindings.addAll(query._bindings);
    return this;
  }

  QueryBuilder<T> orWhereExists(QueryBuilder query) {
    return whereExists(query, boolean: 'OR');
  }

  QueryBuilder<T> whereNotExists(QueryBuilder query) {
    return whereExists(query, not: true);
  }

  QueryBuilder<T> orWhereNotExists(QueryBuilder query) {
    return whereExists(query, boolean: 'OR', not: true);
  }

  /// Raw SQL escape hatch. Use with caution.
  ///
  /// [bindings] must be provided manually if user input is involved.
  QueryBuilder<T> whereRaw(
    String sql, {
    List<dynamic> bindings = const [],
    String boolean = 'AND',
  }) {
    _wheres.add({'type': boolean, 'sql': sql});
    _bindings.addAll(bindings);
    return this;
  }

  QueryBuilder<T> orWhereRaw(String sql, [List<dynamic> bindings = const []]) {
    return whereRaw(sql, bindings: bindings, boolean: 'OR');
  }

  // ---------------------------------------------------------------------------
  // GROUP BY / HAVING CLAUSES
  // ---------------------------------------------------------------------------

  /// Groups results by one or more columns.
  ///
  /// Essential for aggregate queries (COUNT, SUM, AVG) that need to partition
  /// results by specific attributes.
  ///
  /// Example:
  /// ```dart
  /// await User().query()
  ///   .select(['role', 'COUNT(*) as count'])
  ///   .groupBy(['role'])
  ///   .get();
  /// ```
  QueryBuilder<T> groupBy(List<String> columns) {
    for (final column in columns) {
      _assertIdent(column, dotted: true, what: 'groupBy column');
      _groupBy.add(column);
    }
    return this;
  }

  /// Convenience method for grouping by a single column.
  QueryBuilder<T> groupByColumn(String column) {
    return groupBy([column]);
  }

  /// Adds a HAVING clause to filter grouped results.
  ///
  /// HAVING operates on aggregate results (post-GROUP BY), unlike WHERE
  /// which filters individual rows before grouping.
  ///
  /// Example:
  /// ```dart
  /// await Order().query()
  ///   .select(['customer_id', 'SUM(total) as total_spent'])
  ///   .groupBy(['customer_id'])
  ///   .having('SUM(total)', 1000, operator: '>')
  ///   .get();
  /// ```
  QueryBuilder<T> having(
    String column,
    dynamic value, {
    String operator = '=',
    String boolean = 'AND',
  }) {
    final op = _op(operator);
    if (!_allowedHavingOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for having: $operator');
    }

    _havings.add({'type': boolean, 'sql': '$column $op ?'});
    _havingBindings.add(value);
    return this;
  }

  /// Adds an OR HAVING clause.
  QueryBuilder<T> orHaving(
    String column,
    dynamic value, {
    String operator = '=',
  }) {
    return having(column, value, operator: operator, boolean: 'OR');
  }

  /// Adds a raw HAVING clause for complex aggregate conditions.
  ///
  /// Use for expressions that cannot be represented with simple column comparisons.
  ///
  /// Example:
  /// ```dart
  /// await Product().query()
  ///   .select(['category', 'AVG(price) as avg_price'])
  ///   .groupBy(['category'])
  ///   .havingRaw('AVG(price) > ? AND COUNT(*) >= ?', bindings: [50, 10])
  ///   .get();
  /// ```
  QueryBuilder<T> havingRaw(
    String sql, {
    List<dynamic> bindings = const [],
    String boolean = 'AND',
  }) {
    _havings.add({'type': boolean, 'sql': sql});
    _havingBindings.addAll(bindings);
    return this;
  }

  /// Adds an OR raw HAVING clause.
  QueryBuilder<T> orHavingRaw(String sql, [List<dynamic> bindings = const []]) {
    return havingRaw(sql, bindings: bindings, boolean: 'OR');
  }

  /// Adds a HAVING clause that checks for NULL.
  QueryBuilder<T> havingNull(String column, {String boolean = 'AND'}) {
    _havings.add({'type': boolean, 'sql': '$column IS NULL'});
    return this;
  }

  /// Adds a HAVING clause that checks for NOT NULL.
  QueryBuilder<T> havingNotNull(String column, {String boolean = 'AND'}) {
    _havings.add({'type': boolean, 'sql': '$column IS NOT NULL'});
    return this;
  }

  /// Adds a HAVING BETWEEN clause.
  ///
  /// Useful for filtering aggregates within a range.
  QueryBuilder<T> havingBetween(
    String column,
    dynamic min,
    dynamic max, {
    String boolean = 'AND',
  }) {
    _havings.add({'type': boolean, 'sql': '$column BETWEEN ? AND ?'});
    _havingBindings.addAll([min, max]);
    return this;
  }

  // ---------------------------------------------------------------------------
  // SELECT & PROJECTION
  // ---------------------------------------------------------------------------

  QueryBuilder<T> select(List<String> columns) {
    _columns = columns;
    return this;
  }

  /// Adds aggregate columns to the selection without replacing existing columns.
  ///
  /// Convenience method for adding COUNT, SUM, etc. to the query.
  QueryBuilder<T> selectRaw(String expression) {
    if (_columns.length == 1 && _columns.first == '*') {
      _columns = [expression];
    } else {
      _columns.add(expression);
    }
    return this;
  }

  // ---------------------------------------------------------------------------
  // AGGREGATES & HELPERS
  // ---------------------------------------------------------------------------

  /// Checks existence by fetching a single record (Limit 1 optimization).
  Future<bool> exists() async {
    limit(1);
    final results = await get();
    return results.isNotEmpty;
  }

  Future<bool> notExist() async {
    return !await exists();
  }

  Future<int?> count([String column = '*']) async {
    return await _scalar<int>('COUNT($column)');
  }

  Future<num> sum(String column) async {
    return await _scalar<num>('SUM($column)') ?? 0;
  }

  Future<dynamic> max(String column) async {
    return await _scalar('MAX($column)');
  }

  Future<dynamic> min(String column) async {
    return await _scalar('MIN($column)');
  }

  Future<double> avg(String column) async {
    final result = await _scalar('AVG($column)');
    return result != null ? (result as num).toDouble() : 0.0;
  }

  Future<T?> find(dynamic id) {
    return where('id', id).first();
  }

  /// Finds a model by ID or throws [ModelNotFoundException].
  Future<T> findOrFail(dynamic id) async {
    final result = await find(id);
    if (result == null) {
      // Use the table name as a proxy for model name
      throw ModelNotFoundException(model: table, id: id);
    }
    return result;
  }

  /// Returns the first result or throws [ModelNotFoundException].
  Future<T> firstOrFail() async {
    final result = await first();
    if (result == null) {
      throw ModelNotFoundException(model: table);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // JOINS & RELATIONS
  // ---------------------------------------------------------------------------

  QueryBuilder<T> join(String table, String one, String operator, String two) {
    _assertIdent(table, dotted: false, what: 'join table name');
    _assertIdent(one, dotted: true, what: 'join lhs');
    _assertIdent(two, dotted: true, what: 'join rhs');

    final op = _op(operator);
    if (!_allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    _joins.add('JOIN $table ON $one $op $two');
    return this;
  }

  /// Adds a LEFT JOIN clause.
  QueryBuilder<T> leftJoin(
    String table,
    String one,
    String operator,
    String two,
  ) {
    _assertIdent(table, dotted: false, what: 'join table name');
    _assertIdent(one, dotted: true, what: 'join lhs');
    _assertIdent(two, dotted: true, what: 'join rhs');

    final op = _op(operator);
    if (!_allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    _joins.add('LEFT JOIN $table ON $one $op $two');
    return this;
  }

  /// Adds a RIGHT JOIN clause.
  QueryBuilder<T> rightJoin(
    String table,
    String one,
    String operator,
    String two,
  ) {
    _assertIdent(table, dotted: false, what: 'join table name');
    _assertIdent(one, dotted: true, what: 'join lhs');
    _assertIdent(two, dotted: true, what: 'join rhs');

    final op = _op(operator);
    if (!_allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    _joins.add('RIGHT JOIN $table ON $one $op $two');
    return this;
  }

  /// Queues relationships for eager loading after the main query execution.
  ///
  /// Critical for performance optimization (mitigates N+1 queries).
  QueryBuilder<T> withRelations(List<String> relations) {
    _with.addAll(relations);
    return this;
  }

  // ---------------------------------------------------------------------------
  // ORDERING & LIMITS
  // ---------------------------------------------------------------------------

  QueryBuilder<T> orderBy(String column, {String direction = 'ASC'}) {
    _assertIdent(column, dotted: true, what: 'orderBy column');

    final dirUpper = direction.toUpperCase();
    if (dirUpper != 'ASC' && dirUpper != 'DESC') {
      throw InvalidQueryException('Invalid direction for orderBy: $direction');
    }

    _orderBy = '$column $dirUpper';
    return this;
  }

  QueryBuilder<T> limit(int limit) {
    _limit = limit;
    return this;
  }

  QueryBuilder<T> offset(int offset) {
    _offset = offset;
    return this;
  }

  // ---------------------------------------------------------------------------
  // INTERNALS
  // ---------------------------------------------------------------------------

  /// Transitions the builder to a new Model type [U] while preserving query constraints.
  ///
  /// Used when query logic (like a generic scope or mixin) needs to operate on a subclass
  /// or a different entity that shares the same table/structure.
  QueryBuilder<U> cast<U extends Model>(
    U Function(Map<String, dynamic>) newCreator, {
    U Function()? instanceFactory,
  }) {
    final qb = QueryBuilder<U>(
      table,
      newCreator,
      instanceFactory: instanceFactory,
    );

    qb._columns = _columns;
    qb._wheres.addAll(_wheres);
    qb._bindings.addAll(_bindings);
    qb._joins.addAll(_joins);
    qb._with.addAll(_with);
    qb._groupBy.addAll(_groupBy);
    qb._havings.addAll(_havings);
    qb._havingBindings.addAll(_havingBindings);
    qb._orderBy = _orderBy;
    qb._limit = _limit;
    qb._offset = _offset;

    return qb;
  }

  /// Assembles the SQL string.
  ///
  /// Note: [bindings] remain separate to be passed to the driver's prepared statement.
  String _compileSql() {
    final cols = _columns.map((c) => c == '*' ? '$table.*' : c).join(', ');
    var sql = 'SELECT $cols FROM $table';

    if (_joins.isNotEmpty) sql += ' ${_joins.join(' ')}';

    if (_wheres.isNotEmpty) {
      sql += _buildWhereClause();
    }

    if (_groupBy.isNotEmpty) {
      sql += ' GROUP BY ${_groupBy.join(', ')}';
    }

    if (_havings.isNotEmpty) {
      sql += _buildHavingClause();
    }

    if (_orderBy != null) sql += ' ORDER BY $_orderBy';
    if (_limit != null) sql += ' LIMIT $_limit';
    if (_offset != null) sql += ' OFFSET $_offset';
    return sql;
  }

  /// Builds the HAVING clause from accumulated conditions.
  String _buildHavingClause() {
    if (_havings.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < _havings.length; i++) {
      final h = _havings[i];
      if (i > 0) buffer.write(' ${h['type']} ');
      buffer.write(h['sql']);
    }
    return ' HAVING $buffer';
  }

  /// Resolves eager loads by delegating to the Model's relation definition.
  ///
  /// Iterates through the result set [models] and matches related records in-memory
  /// or via secondary queries.
  Future<void> _eagerLoad(List<T> models) async {
    if (_with.isEmpty || models.isEmpty) return;

    for (var relationName in _with) {
      // Assumes all models in list are of same type T and share the relation definition.
      final relation = models.first.getRelation(relationName);
      if (relation != null) {
        await relation.match(models, relationName);
      }
    }
  }

  /// Maps raw DB rows to concrete Model instances.
  ///
  /// Handles lifecycle initialization:
  /// - Sets [exists] to true.
  /// - Takes a snapshot for dirty checking ([syncOriginal]).
  /// - Triggers eager loading.
  Future<List<T>> _hydrate(List<Map<String, dynamic>> rows) async {
    final models = <T>[];

    for (final row in rows) {
      final model = creator(row);
      model.exists = true;
      model.syncOriginal();
      models.add(model);
    }

    await _eagerLoad(models);
    return models;
  }

  Future<T?> first() async {
    limit(1);
    final results = await get();
    return results.isNotEmpty ? results.first : null;
  }

  /// Executes the compiled query and hydrates results.
  Future<List<T>> get() async {
    final dbManager = DatabaseManager();
    final sql = _compileSql();
    final allBindings = [..._bindings, ..._havingBindings];

    try {
      final resultRows = await dbManager.getAll(sql, allBindings);
      return _hydrate(resultRows);
    } catch (e) {
      throw QueryException(
        sql: sql,
        bindings: allBindings,
        message: 'Failed to execute query: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Returns a reactive stream that emits updated results when the table changes.
  ///
  /// Leverages the underlying database adapter's change notifications (e.g., SQLite triggers).
  /// Essential for Flutter reactive UIs (StreamBuilder).
  Stream<List<T>> watch() {
    final db = DatabaseManager().db;
    final sql = _compileSql();
    final allBindings = [..._bindings, ..._havingBindings];

    return db.watch(sql, parameters: allBindings).asyncMap(_hydrate);
  }

  /// Helper for aggregate queries (Count, Sum, etc).
  ///
  /// Modifies the SELECT clause to return a single scalar value.
  Future<T?> _scalar<T>(String expression) async {
    final dbManager = DatabaseManager();

    var sql = 'SELECT $expression as aggregate FROM $table';

    if (_joins.isNotEmpty) sql += ' ${_joins.join(' ')}';

    if (_wheres.isNotEmpty) {
      sql += _buildWhereClause();
    }

    if (_groupBy.isNotEmpty) {
      sql += ' GROUP BY ${_groupBy.join(', ')}';
    }

    if (_havings.isNotEmpty) {
      sql += _buildHavingClause();
    }

    final allBindings = [..._bindings, ..._havingBindings];

    try {
      final row = await dbManager.get(sql, allBindings);

      if (row.isEmpty || row['aggregate'] == null) {
        return null;
      }

      return row['aggregate'] as T;
    } catch (e) {
      throw QueryException(
        sql: sql,
        bindings: allBindings,
        message: 'Failed to execute aggregate query: ${e.toString()}',
        originalError: e,
      );
    }
  }

  String _buildWhereClause() {
    if (_wheres.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < _wheres.length; i++) {
      final w = _wheres[i];
      if (i > 0) buffer.write(' ${w['type']} ');
      buffer.write(w['sql']);
    }
    return ' WHERE $buffer';
  }
}
