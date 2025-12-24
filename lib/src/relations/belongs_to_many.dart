import 'relation.dart';
import '../core/model.dart';
import '../core/pivot.dart';
import '../core/query_builder.dart';
import '../schema/columns.dart';
import '../core/database_manager.dart';

/// Manages many-to-many relationships via an intermediate pivot table.
///
/// Requires [foreignPivotKey] (points to current parent) and [relatedPivotKey]
/// (points to related model [R]) on the [pivotTable].
class BelongsToMany<R extends Model> extends Relation<R> {
  final String pivotTable;
  final String foreignPivotKey;
  final String relatedPivotKey;

  Pivot Function(Map<String, dynamic>)? _pivotCreator;
  List<Column> _pivotColumns = [];

  BelongsToMany(
    super.parent,
    super.creator,
    this.pivotTable,
    this.foreignPivotKey,
    this.relatedPivotKey,
  ) {
    addConstraints();
  }

  /// Configures the relationship to return strongly-typed [Pivot] instances.
  ///
  /// [factory]: Constructor/Factory for the Pivot class (e.g. `UserRole.new`).
  /// [columns]: List of columns to retrieve from the pivot table (e.g. `UserRole.columns`).
  BelongsToMany<R> using<P extends Pivot>(
    P Function(Map<String, dynamic>) factory,
    List<Column> columns,
  ) {
    _pivotCreator = factory;
    _pivotColumns = columns;
    return this;
  }

  /// Adds simple columns to be retrieved from the pivot table.
  ///
  /// Useful for retrieving extra data without defining a full [Pivot] class.
  /// The attributes will be available via `model.pivot.attributes`.
  BelongsToMany<R> withPivot(List<dynamic> columns) {
    _pivotColumns.addAll(
      columns.map((c) {
        if (c is Column) return c;
        return TextColumn(c.toString());
      }),
    );
    // Ensure we have a pivot creator if not set
    _pivotCreator ??= (map) => GenericPivot(map);
    return this;
  }

  /// Attaches a related model to the parent by inserting a record into the pivot table.
  ///
  /// [id] can be a primary key value or a [Model] instance.
  /// [attributes] are extra columns to save in the pivot table (e.g. timestamps).
  Future<void> attach(
    dynamic id, [
    Map<String, dynamic> attributes = const {},
  ]) async {
    if (parent.id == null) {
      throw Exception(
        'Cannot attach to a model with no ID. Save the parent model first.',
      );
    }

    final relatedId = _parseId(id);

    final data = {
      foreignPivotKey: parent.id,
      relatedPivotKey: relatedId,
      ...attributes,
    };

    await DatabaseManager().insert(pivotTable, data);
  }

  /// Detaches related models from the parent by deleting records from the pivot table.
  ///
  /// [ids] can be:
  /// - `null`: Detach ALL related models.
  /// - `single value` (ID or Model): Detach specific record.
  /// - `List` (IDs or Models): Detach multiple records.
  Future<int> detach([dynamic ids]) async {
    if (parent.id == null) {
      throw Exception('Cannot detach from a model with no ID.');
    }

    final query = QueryBuilder<_PivotHelperModel>(
      pivotTable,
          (map) => _PivotHelperModel(pivotTable, map),
    );

    query.where(foreignPivotKey, parent.id);

    if (ids != null) {
      final list = (ids is List) ? ids : [ids];
      final parsedIds = list.map(_parseId).toList();
      query.whereIn(relatedPivotKey, parsedIds);
    }

    return await query.delete();
  }

  /// Helper to extract ID from Model or return raw value.
  dynamic _parseId(dynamic value) {
    if (value is Model) {
      if (value.id == null) {
        throw Exception(
          'Cannot use a model with no ID in a relationship operation.',
        );
      }
      return value.id;
    }
    return value;
  }

  /// Configures the INNER JOIN between the related table and pivot table,
  /// filtering results to match the current parent's ID.
  @override
  void addConstraints() {
    final relatedTable = table;
    // Instantiate dummy model to resolve the primary key name dynamically.
    final relatedKey = creator({}).primaryKey;

    join(
      pivotTable,
      '$relatedTable.$relatedKey',
      '=',
      '$pivotTable.$relatedPivotKey',
    );

    where('$pivotTable.$foreignPivotKey', parent.id);
  }

  String _resolvePivotColumnName(dynamic column) {
    if (column is WhereCondition) {
      throw ArgumentError(
        'You passed a WhereCondition to a pivot method expecting a Column or String name.',
      );
    }
    if (column is Column) {
      return column.name ?? column.toString();
    }
    return column.toString();
  }

  // --- Pivot Filters ---

  BelongsToMany<R> wherePivot(
    dynamic column, [
    dynamic value,
    String operator = '=',
    String boolean = 'AND',
  ]) {
    final colName = _resolvePivotColumnName(column);
    return where('$pivotTable.$colName', value, operator, boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> orWherePivot(
    dynamic column, [
    dynamic value,
    String operator = '=',
  ]) {
    return wherePivot(column, value, operator, 'OR');
  }

  BelongsToMany<R> wherePivotIn(
    dynamic column,
    List<dynamic> values, {
    String boolean = 'AND',
  }) {
    final colName = _resolvePivotColumnName(column);
    return whereIn('$pivotTable.$colName', values, boolean: boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> orWherePivotIn(dynamic column, List<dynamic> values) {
    return wherePivotIn(column, values, boolean: 'OR');
  }

  BelongsToMany<R> wherePivotNotIn(
    dynamic column,
    List<dynamic> values, {
    String boolean = 'AND',
  }) {
    final colName = _resolvePivotColumnName(column);
    return where('$pivotTable.$colName', values, 'NOT IN', boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> orWherePivotNotIn(dynamic column, List<dynamic> values) {
    return wherePivotNotIn(column, values, boolean: 'OR');
  }

  BelongsToMany<R> wherePivotNull(dynamic column, {String boolean = 'AND'}) {
    final colName = _resolvePivotColumnName(column);
    return whereNull('$pivotTable.$colName', boolean: boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> wherePivotNotNull(dynamic column, {String boolean = 'AND'}) {
    final colName = _resolvePivotColumnName(column);
    return whereNotNull('$pivotTable.$colName', boolean: boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> wherePivotCondition(
    WhereCondition condition, {
    String boolean = 'AND',
  }) {
    return where(
          '$pivotTable.${condition.column}',
          condition.value,
          condition.operator,
          boolean,
        )
        as BelongsToMany<R>;
  }

  BelongsToMany<R> orWherePivotCondition(WhereCondition condition) {
    return wherePivotCondition(condition, boolean: 'OR');
  }

  @override
  Future<List<R>> get() async {
    // 1. Add specific selects if pivot columns are requested
    if (_pivotColumns.isNotEmpty) {
      // Ensure we select related model fields to avoid them being clobbered
      final selects = <String>['$table.*'];

      // Select pivot columns with alias to prevent collision (e.g. created_at)
      for (final col in _pivotColumns) {
        if (col.name != null) {
          selects.add('$pivotTable.${col.name} as pivot_${col.name}');
        }
      }
      select(selects);
    }

    // 2. Execute the query
    final models = await super.get();

    // 3. Hydrate Pivot instances
    if (_pivotCreator != null) {
      for (final model in models) {
        _hydratePivot(model);
      }
    }

    return models;
  }

  /// Extracts 'pivot_' prefixed attributes, creates the Pivot object,
  /// and attaches it to the model.
  void _hydratePivot(Model model) {
    final pivotData = <String, dynamic>{};
    final keysToRemove = <String>[];

    model.attributes.forEach((key, value) {
      if (key.startsWith('pivot_')) {
        final cleanKey = key.substring(6); // remove 'pivot_'
        pivotData[cleanKey] = value;
        keysToRemove.add(key);
      }
    });

    // Clean up the model attributes so they don't look dirty
    for (var k in keysToRemove) model.attributes.remove(k);

    model.pivot = _pivotCreator!(pivotData);
  }

  /// Eagerly loads relationships to solve N+1 issues.
  ///
  /// Strategy:
  /// 1. Fetch pivot rows via raw SQL (bypassing QueryBuilder for the intermediate table).
  /// 2. Fetch related models in a single batch.
  /// 3. Stitch results back to parents in-memory.
  @override
  Future<void> match(
    List<Model> models,
    String relationName, {
    List<String> nested = const [],
  }) async {
    final parentIds = getKeys(models, parent.primaryKey);
    if (parentIds.isEmpty) return;

    final db = DatabaseManager().db;

    final placeholders = List.filled(parentIds.length, '?').join(',');

    String selectClause = '*';

    if (_pivotColumns.isNotEmpty) {
      final requiredKeys = {
        foreignPivotKey,
        relatedPivotKey,
        ..._pivotColumns.map((c) => c.name).whereType<String>(),
      };
      final requiredKeyWithWrap = requiredKeys
          .map((e) => db.grammar.wrap(e))
          .toList();
      selectClause = requiredKeyWithWrap.join(', ');
    }

    final selectClauseWrap = db.grammar.wrap(selectClause);
    final pivotTableWrap = db.grammar.wrap(pivotTable);
    final foreignPivotKeyWrap = db.grammar.wrap(foreignPivotKey);

    final pivotSql =
        'SELECT $selectClauseWrap FROM $pivotTableWrap WHERE $foreignPivotKeyWrap IN ($placeholders)';

    final pivotRows = await db.getAll(pivotSql, parentIds);

    if (pivotRows.isEmpty) return;

    final relatedIds = pivotRows
        .map((r) => r[relatedPivotKey])
        .toSet()
        .toList();

    final pk = creator({}).primaryKey;
    final relatedModels = (await creator(
      {},
    ).newQuery().withRelations(nested).whereIn(pk, relatedIds).get()).cast<R>();

    final relatedDict = {for (var m in relatedModels) normKey(m.id)!: m};

    for (var model in models) {
      final myId = normKey(model.id);

      // Filter pivots belonging to this specific parent
      final myPivots = pivotRows.where(
        (r) => normKey(r[foreignPivotKey]) == myId,
      );

      final matches = <R>[];
      for (var pivotRow in myPivots) {
        final rId = normKey(pivotRow[relatedPivotKey]);
        if (rId != null && relatedDict.containsKey(rId)) {
          // CLONE the model so we can attach unique pivot data to this instance
          // without affecting other parents who might share the same related model.
          final original = relatedDict[rId]!;

          // Re-hydrate a fresh instance
          final clone = creator(original.attributes);
          clone.exists = true;
          clone.syncOriginal();

          // Manually copy relations if they were eager loaded on the original
          clone.relations.addAll(original.relations);

          // Attach Pivot
          if (_pivotCreator != null) {
            matches.add(clone);
            // In match (separate query), we don't use 'pivot_' prefix aliases.
            // The row comes directly from the pivot table.
            clone.pivot = _pivotCreator != null
                ? _pivotCreator!(pivotRow)
                : GenericPivot(pivotRow);
          }

          matches.add(clone);
        }
      }

      model.relations[relationName] = matches;
    }
  }
}

class _PivotHelperModel extends Model {
  final String _table;

  _PivotHelperModel(this._table, [super.attributes]);

  @override
  String get table => _table;

  @override
  _PivotHelperModel fromMap(Map<String, dynamic> map) => _PivotHelperModel(_table, map);
}
