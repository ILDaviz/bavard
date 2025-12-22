import 'dart:async';
import 'package:bavard/schema.dart';
import '../../bavard.dart';

typedef ScopeCallback = void Function(QueryBuilder builder);

/// Fluent interface for constructing type-safe SQL queries and hydrating results into [Model] instances.
///
/// Abstracts raw SQL generation, manages parameter binding for security (SQL injection prevention),
/// and handles the object lifecycle (hydration, dirty checking initialization) and eager loading.
class QueryBuilder<T extends Model> {
  final String table;
  final T Function(Map<String, dynamic>) creator;

  /// Internal factory for empty instances (used during generic casting or hydration).
  final T Function() _instanceFactory;

  final List<Map<String, dynamic>> _wheres = [];
  final List<dynamic> _bindings = [];
  final List<String> _joins = [];
  final List<String> _with = [];
  List<dynamic> _columns = ['*'];

  final List<String> _groupBy = [];
  final List<Map<String, dynamic>> _havings = [];
  final List<dynamic> _havingBindings = [];

  final Map<String, ScopeCallback> _globalScopes = {};
  bool _ignoreGlobalScopes = false;

  int? _offset;
  String? _orderBy;
  int? _limit;

  /// Validates [table] immediately to prevent identifier injection attacks.
  QueryBuilder(this.table, this.creator, {T Function()? instanceFactory})
    : _instanceFactory =
          instanceFactory ?? (() => creator(const {}).newInstance() as T) {
    _assertIdent(table, dotted: false, what: 'table name');
  }

  /// Helper to access the current database grammar.
  Grammar get _grammar => DatabaseManager().db.grammar;

  // Public getters for Grammar access
  List<Map<String, dynamic>> get wheres => _wheres;
  List<dynamic> get columns => _columns;
  List<String> get joins => _joins;
  List<String> get groups => _groupBy;
  List<Map<String, dynamic>> get havings => _havings;
  String? get orders => _orderBy;
  int? get limitValue => _limit;
  int? get offsetValue => _offset;

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

  static String _operator(String op) => op.trim().toUpperCase();

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
  // DEBUGGING TOOLS
  // ---------------------------------------------------------------------------

  String toRawSql() {
    String sql = _compileSql();
    final allBindings = _grammar.prepareBindings([..._bindings, ..._havingBindings]);

    int index = 0;
    return sql.replaceAllMapped('?', (match) {
      if (index >= allBindings.length) return '?';

      final value = allBindings[index++];
      return _formatValueForDebug(value);
    });
  }

  String _formatValueForDebug(dynamic value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    if (value is DateTime) return "'${value.toIso8601String()}'";
    return "'${value.toString().replaceAll("'", "''")}'";
  }

  QueryBuilder<T> printRawSql() {
    print('\x1B[35m[RAW SQL]\x1B[0m ${toRawSql()}');
    return this;
  }

  QueryBuilder<T> printQueryAndBindings() {
    print('\x1B[34m[QUERY]\x1B[0m ${_compileSql()}');
    print('\x1B[33m[BINDINGS]\x1B[0m ${[..._bindings, ..._havingBindings]}');
    return this;
  }

  void printAndDieRawSql() {
    printRawSql();
    throw Exception('🛑 DIE PRINT RAW SQL EXECUTED');
  }

  // ---------------------------------------------------------------------------
  // SCOPE
  // ---------------------------------------------------------------------------

  QueryBuilder<T> withGlobalScope(String name, ScopeCallback scope) {
    _globalScopes[name] = scope;
    return this;
  }

  QueryBuilder<T> withoutGlobalScopes() {
    _ignoreGlobalScopes = true;
    return this;
  }

  QueryBuilder<T> withoutGlobalScope(String name) {
    _globalScopes.remove(name);
    return this;
  }

  void _applyScopes() {
    if (_ignoreGlobalScopes) return;

    _globalScopes.forEach((name, scope) {
      scope(this);
    });
  }

  // ---------------------------------------------------------------------------
  // WHERE CLAUSES (AND / OR)
  // ---------------------------------------------------------------------------

  /// Appends a condition to the query state.
  ///
  /// Validates [operator] against a whitelist to prevent logic injection.
  QueryBuilder<T> where(
      dynamic column, [
        dynamic value,
        String operator = '=',
        String boolean = 'AND',
      ]) {

    String targetColumn;
    String targetOperator;
    dynamic targetValue;
    String targetBoolean = boolean;

    if (column is WhereCondition) {
      targetColumn = column.column;
      targetOperator = column.operator;
      targetValue = column.value;
      targetBoolean = column.boolean;
    } else {
      if (column is Column) {
        targetColumn = column.name!;
      } else {
        targetColumn = column.toString();
      }
      targetOperator = operator;
      targetValue = value;
    }

    _assertIdent(targetColumn, dotted: true, what: 'column name');

    if (targetValue == null) {
      final checkOp = _operator(targetOperator);
      if (checkOp == '=') {
        return whereNull(targetColumn, boolean: targetBoolean);
      } else if (checkOp == '<>' || checkOp == '!=') {
        return whereNotNull(targetColumn, boolean: targetBoolean);
      }
    }

    final finalOp = _operator(targetOperator);
    if (!_allowedWhereOps.contains(finalOp)) {
      throw InvalidQueryException('Invalid operator for where: $targetOperator');
    }

    String sqlString;
    // We use _grammar.wrap for columns and _grammar.parameter for values

    if (finalOp == 'IN' || finalOp == 'NOT IN') {
      if (targetValue is! List) {
        throw ArgumentError(
            'QueryBuilder Error: L\'operatore "$finalOp" richiede una List come valore. '
                'Ricevuto: ${targetValue.runtimeType}'
        );
      }

      if (targetValue.isEmpty) {
        sqlString = '1 = 0';
      } else {
        final placeholders = List.filled(targetValue.length, _grammar.parameter(null)).join(', ');
        sqlString = '${_grammar.wrap(targetColumn)} $finalOp ($placeholders)';
        _bindings.addAll(targetValue);
      }
    }

    else if (finalOp == 'BETWEEN') {
      if (targetValue is! List || targetValue.length != 2) {
        throw ArgumentError(
            'QueryBuilder Error: L\'operatore "BETWEEN" richiede una List di esattamente 2 elementi [min, max].'
        );
      }
      sqlString = '${_grammar.wrap(targetColumn)} $finalOp ${_grammar.parameter(targetValue[0])} AND ${_grammar.parameter(targetValue[1])}';
      _bindings.addAll(targetValue);
    }

    else {
      if (targetValue is List) {
        throw ArgumentError(
            'QueryBuilder Error: Non puoi usare una List con l\'operatore "$finalOp". '
                'Usa IN, NOT IN o BETWEEN.'
        );
      }

      sqlString = '${_grammar.wrap(targetColumn)} $finalOp ${_grammar.parameter(targetValue)}';
      _bindings.add(targetValue);
    }

    _wheres.add({
      'type': targetBoolean,
      'sql': sqlString,
    });

    return this;
  }

  QueryBuilder<T> orWhere(
      dynamic column, [
        dynamic value,
        String operator = '=',
      ]) {

    return where(column, value, operator, 'OR');
  }

  /// Adds a nested WHERE group wrapped in parentheses: AND (...).
  ///
  /// Example:
  /// query.whereGroup((q) => q.where('a', 1).orWhere('b', 1))
  /// Generates: ... AND (a = 1 OR b = 1)
  QueryBuilder<T> whereGroup(void Function(QueryBuilder<T> query) callback) {
    return _addNestedWhere(callback, 'AND');
  }

  /// Adds a nested WHERE group wrapped in parentheses: OR (...).
  ///
  /// Example:
  /// query.orWhereGroup((q) => q.where('active', 1).where('age', '>', 18))
  /// Generates: ... OR (active = 1 AND age > 18)
  QueryBuilder<T> orWhereGroup(void Function(QueryBuilder<T> query) callback) {
    return _addNestedWhere(callback, 'OR');
  }

  /// Internal helper to process nested queries.
  QueryBuilder<T> _addNestedWhere(
    void Function(QueryBuilder<T> query) callback,
    String boolean,
  ) {
    final nestedBuilder = QueryBuilder<T>(
      table,
      creator,
      instanceFactory: _instanceFactory,
    );

    callback(nestedBuilder);

    final nestedClause = _grammar.compileWheres(nestedBuilder);

    if (nestedClause.isNotEmpty) {
      // Remove 'WHERE ' from the compiled string
      final sqlInside = nestedClause.substring(6);

      _wheres.add({'type': boolean, 'sql': '($sqlInside)'});

      _bindings.addAll(nestedBuilder._bindings);
    }

    return this;
  }

  QueryBuilder<T> whereNull(String column, {String boolean = 'AND'}) {
    _assertIdent(column, dotted: true, what: 'column name');
    _wheres.add({'type': boolean, 'sql': '${_grammar.wrap(column)} IS NULL'});
    return this;
  }

  QueryBuilder<T> orWhereNull(String column) {
    return whereNull(column, boolean: 'OR');
  }

  QueryBuilder<T> whereNotNull(String column, {String boolean = 'AND'}) {
    _assertIdent(column, dotted: true, what: 'column name');
    _wheres.add({'type': boolean, 'sql': '${_grammar.wrap(column)} IS NOT NULL'});
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

    final placeholders = List.filled(values.length, _grammar.parameter(null)).join(', ');
    _wheres.add({'type': boolean, 'sql': '${_grammar.wrap(column)} IN ($placeholders)'});
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
      _groupBy.add(column); // Grammar wraps these in compileGroups
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
    final op = _operator(operator);
    if (!_allowedHavingOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for having: $operator');
    }

    final sqlCol = column.contains('(') ? column : _grammar.wrap(column);
    _havings.add({'type': boolean, 'sql': '$sqlCol $op ${_grammar.parameter(value)}'});
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
    final sqlCol = column.contains('(') ? column : _grammar.wrap(column);

    _havings.add({'type': boolean, 'sql': '$sqlCol IS NULL'});
    return this;
  }

  /// Adds a HAVING clause that checks for NOT NULL.
  QueryBuilder<T> havingNotNull(String column, {String boolean = 'AND'}) {
    final sqlCol = column.contains('(') ? column : _grammar.wrap(column);

    _havings.add({'type': boolean, 'sql': '$sqlCol IS NOT NULL'});
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
    final sqlCol = column.contains('(') ? column : _grammar.wrap(column);
    _havings.add({
      'type': boolean,
      'sql': '$sqlCol BETWEEN ${_grammar.parameter(min)} AND ${_grammar.parameter(max)}'
    });
    _havingBindings.addAll([min, max]);
    return this;
  }

  // ---------------------------------------------------------------------------
  // SELECT & PROJECTION
  // ---------------------------------------------------------------------------

  QueryBuilder<T> select(List<String> columns) {
    _columns = List<dynamic>.from(columns);
    return this;
  }

  /// Adds aggregate columns to the selection without replacing existing columns.
  ///
  /// Convenience method for adding COUNT, SUM, etc. to the query.
  QueryBuilder<T> selectRaw(String expression) {
    if (_columns.length == 1 && _columns.first == '*') {
      _columns = [RawExpression(expression)];
    } else {
      _columns.add(RawExpression(expression));
    }
    return this;
  }

  // ---------------------------------------------------------------------------
  // AGGREGATES & HELPERS
  // ---------------------------------------------------------------------------

  /// Checks existence by fetching a single record (Limit 1 optimization).
  Future<bool> exists() async {
    final clone = cast<T>(creator, instanceFactory: _instanceFactory);
    clone.limit(1);
    final results = await clone.get();
    return results.isNotEmpty;
  }

  Future<bool> notExist() async {
    return !await exists();
  }

  Future<int?> count([String column = '*']) async {
    if (_groupBy.isNotEmpty || _havings.isNotEmpty) {
      final dbManager = DatabaseManager();
      final subQuery = _compileSql();
      final bindings = _grammar.prepareBindings([..._bindings, ..._havingBindings]);
      final wrapperSql =
          'SELECT COUNT(*) as aggregate FROM ($subQuery) as temp_table';
      try {
        final row = await dbManager.get(wrapperSql, bindings);
        if (row.isEmpty || row['aggregate'] == null) return 0;

        final value = row['aggregate'];
        return (value is num) ? value.toInt() : value as int;
      } catch (e) {
        throw QueryException(
          sql: wrapperSql,
          bindings: bindings,
          message: 'Failed to execute count with group by: ${e.toString()}',
          originalError: e,
        );
      }
    }

    return await _scalar<int>('COUNT($column)');
  }

  Future<num> sum(String column) async {
    _guardAgainstGrouping('sum');
    return await _scalar<num>('SUM($column)') ?? 0;
  }

  Future<double?> avg(String column) async {
    _guardAgainstGrouping('avg');
    final result = await _scalar('AVG($column)');
    return result != null ? (result as num).toDouble() : null;
  }

  Future<dynamic> max(String column) async {
    _guardAgainstGrouping('max');
    return await _scalar('MAX($column)');
  }

  Future<dynamic> min(String column) async {
    _guardAgainstGrouping('min');
    return await _scalar('MIN($column)');
  }

  void _guardAgainstGrouping(String method) {
    if (_groupBy.isNotEmpty || _havings.isNotEmpty) {
      throw QueryException(
        sql: _compileSql(),
        bindings: [],
        message:
            'Cannot use $method() with groupBy() or having(). '
            'This would return a single value from a list of groups, which is ambiguous or mathematically wrong. '
            'Use get() to retrieve grouped results.',
      );
    }
  }

  Future<T?> find(dynamic id) {
    final clone = cast<T>(creator, instanceFactory: _instanceFactory);
    return clone.where('id', id).first();
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

    final op = _operator(operator);
    if (!_allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    _joins.add('JOIN ${_grammar.wrap(table)} ON ${_grammar.wrap(one)} $op ${_grammar.wrap(two)}');
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

    final op = _operator(operator);
    if (!_allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    _joins.add('LEFT JOIN ${_grammar.wrap(table)} ON ${_grammar.wrap(one)} $op ${_grammar.wrap(two)}');
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

    final op = _operator(operator);
    if (!_allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    _joins.add('RIGHT JOIN ${_grammar.wrap(table)} ON ${_grammar.wrap(one)} $op ${_grammar.wrap(two)}');
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

    _orderBy = '${_grammar.wrap(column)} $dirUpper';
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
    qb._globalScopes.addAll(_globalScopes);
    qb._ignoreGlobalScopes = _ignoreGlobalScopes;
    qb._orderBy = _orderBy;
    qb._limit = _limit;
    qb._offset = _offset;

    return qb;
  }

  /// Assembles the SQL string.
  ///
  /// Note: [bindings] remain separate to be passed to the driver's prepared statement.
  String _compileSql() {
    return _grammar.compileSelect(this);
  }

  /// Resolves eager loads by delegating to the Model's relation definition.
  ///
  /// Iterates through the result set [models] and matches related records in-memory
  /// or via secondary queries.
  Future<void> _eagerLoad(List<T> models) async {
    if (_with.isEmpty || models.isEmpty) return;

    // Parse nested relations:
    // ['posts', 'posts.comments'] -> {'posts': ['comments']}
    final nestedRelations = <String, List<String>>{};

    for (final relation in _with) {
      final parts = relation.split('.');
      final root = parts[0];
      final nested = parts.length > 1 ? parts.sublist(1).join('.') : null;

      if (!nestedRelations.containsKey(root)) {
        nestedRelations[root] = [];
      }

      if (nested != null) {
        nestedRelations[root]!.add(nested);
      }
    }

    // Eager load related models parallel
    await Future.wait(
      nestedRelations.keys.map((relationName) async {
        final relation = models.first.getRelation(relationName);
        if (relation != null) {
          await relation.match(
            models,
            relationName,
            nested: nestedRelations[relationName] ?? [],
          );
        }
      }),
    );
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
    final clone = cast<T>(creator, instanceFactory: _instanceFactory);
    clone.limit(1);
    final results = await clone.get();
    return results.isNotEmpty ? results.first : null;
  }

  /// Executes the compiled query and hydrates results.
  Future<List<T>> get() async {
    _applyScopes();
    final dbManager = DatabaseManager();
    final sql = _compileSql();
    final allBindings = _grammar.prepareBindings([..._bindings, ..._havingBindings]);

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

  Future<int> update(Map<String, dynamic> values) async {
    _applyScopes();

    if (values.isEmpty) {
      return 0;
    }

    final sql = _grammar.compileUpdate(this, values);
    final allBindings = _grammar.prepareBindings([...values.values, ..._bindings]);

    return await DatabaseManager().execute(sql, allBindings);
  }

  Future<int> delete() async {
    _applyScopes();
    final sql = _grammar.compileDelete(this);
    final bindings = _grammar.prepareBindings(_bindings);

    return await DatabaseManager().execute(sql, bindings);
  }

  /// Executes a raw INSERT into the database.
  ///
  /// WARNING: Bypasses the Model lifecycle (no events, automatic timestamps, or casts).
  /// Returns the ID of the inserted record (if supported by the driver, e.g., autoincrement).
  Future<int> insert(Map<String, dynamic> values) async {
    if (values.isEmpty)
      throw const InvalidQueryException('Insert values cannot be empty');
    values.keys.forEach(
      (k) => _assertIdent(k, dotted: false, what: 'column name'),
    );

    return await DatabaseManager().insert(table, values);
  }

  /// Returns a reactive stream that emits updated results when the table changes.
  ///
  /// Leverages the underlying database adapter's change notifications (e.g., SQLite triggers).
  /// Essential for Flutter reactive UIs (StreamBuilder).
  Stream<List<T>> watch() {
    _applyScopes();
    final db = DatabaseManager().db;
    final sql = _compileSql();
    final allBindings = _grammar.prepareBindings([..._bindings, ..._havingBindings]);

    return db.watch(sql, parameters: allBindings).asyncMap(_hydrate);
  }

  /// Helper for aggregate queries (Count, Sum, etc).
  ///
  /// Modifies the SELECT clause to return a single scalar value.
  Future<T?> _scalar<T>(String expression) async {
    _applyScopes();
    final dbManager = DatabaseManager();

    // Use a temporary modification of columns to compile the scalar query
    final originalColumns = _columns;
    _columns = [RawExpression('$expression as aggregate')];
    
    // We can't just set _columns and call _compileSql because other parts of the grammar 
    // might look at columns, but generally compileSelect uses query.columns.
    // However, to be safe and use the Strategy, we rely on _compileSql which uses Grammar.
    // But wait, _scalar constructs SQL manually in the old version.
    // We should use the grammar.
    
    final sql = _compileSql();
    _columns = originalColumns; // Restore

    final allBindings = _grammar.prepareBindings([..._bindings, ..._havingBindings]);

    try {
      final row = await dbManager.get(sql, allBindings);

      if (row.isEmpty || row['aggregate'] == null) {
        return null;
      }

      final value = row['aggregate'];

      if (T == int && value is num) {
        return value.toInt() as T;
      }
      if (T == double && value is num) {
        return value.toDouble() as T;
      }

      return value as T;
    } catch (e) {
      throw QueryException(
        sql: sql,
        bindings: allBindings,
        message: 'Failed to execute aggregate query: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
