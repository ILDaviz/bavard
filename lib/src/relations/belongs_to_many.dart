import 'relation.dart';
import '../core/model.dart';
import '../core/pivot.dart';
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

  // --- Pivot Filters ---

  BelongsToMany<R> wherePivot(
    String column, [
    dynamic value,
    String operator = '=',
    String boolean = 'AND',
  ]) {
    return where('$pivotTable.$column', value, operator, boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> orWherePivot(
    String column, [
    dynamic value,
    String operator = '=',
  ]) {
    return wherePivot(column, value, operator, 'OR');
  }

  BelongsToMany<R> wherePivotIn(
    String column,
    List<dynamic> values, {
    String boolean = 'AND',
  }) {
    return whereIn('$pivotTable.$column', values, boolean: boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> orWherePivotIn(String column, List<dynamic> values) {
    return wherePivotIn(column, values, boolean: 'OR');
  }

  BelongsToMany<R> wherePivotNotIn(
    String column,
    List<dynamic> values, {
    String boolean = 'AND',
  }) {
    return where('$pivotTable.$column', values, 'NOT IN', boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> orWherePivotNotIn(String column, List<dynamic> values) {
    return wherePivotNotIn(column, values, boolean: 'OR');
  }

  BelongsToMany<R> wherePivotNull(String column, {String boolean = 'AND'}) {
    return whereNull('$pivotTable.$column', boolean: boolean)
        as BelongsToMany<R>;
  }

  BelongsToMany<R> wherePivotNotNull(String column, {String boolean = 'AND'}) {
    return whereNotNull('$pivotTable.$column', boolean: boolean)
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
    ) as BelongsToMany<R>;
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
      final requiredKeys = {foreignPivotKey, relatedPivotKey, ..._pivotColumns.map((c) => c.name).whereType<String>()};
      final requiredKeyWithWrap = requiredKeys.map((e) => db.grammar.wrap(e)).toList();
      selectClause = requiredKeyWithWrap.join(', ');
    }

    final selectClauseWrap = db.grammar.wrap(selectClause);
    final pivotTableWrap = db.grammar.wrap(pivotTable);
    final foreignPivotKeyWrap = db.grammar.wrap(foreignPivotKey);

    final pivotSql =
        'SELECT $selectClauseWrap FROM $pivotTableWrap WHERE $foreignPivotKeyWrap IN ($placeholders)';

    final pivotRows = await db.getAll(pivotSql, parentIds);

    if (pivotRows.isEmpty) return;

    final relatedIds = pivotRows.map((r) => r[relatedPivotKey]).toSet().toList();

    final pk = creator({}).primaryKey;
    final relatedModels =
        (await creator({})
            .newQuery()
            .withRelations(nested)
            .whereIn(pk, relatedIds)
            .get()).cast<R>();

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
            // In match (separate query), we don't use 'pivot_' prefix aliases.
            // The row comes directly from the pivot table.
            clone.pivot = _pivotCreator!(pivotRow);
          }

          matches.add(clone);
        }
      }

      model.relations[relationName] = matches;
    }
  }
}
