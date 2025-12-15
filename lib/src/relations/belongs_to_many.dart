import 'relation.dart';
import '../core/model.dart';
import '../core/database_manager.dart';
import '../core/query_builder.dart';

/// Manages many-to-many relationships via an intermediate pivot table.
///
/// Requires [foreignPivotKey] (points to current parent) and [relatedPivotKey]
/// (points to related model [R]) on the [pivotTable].
class BelongsToMany<R extends Model> extends Relation<R> {
  final String pivotTable;
  final String foreignPivotKey;
  final String relatedPivotKey;

  BelongsToMany(
      super.parent,
      super.creator,
      this.pivotTable,
      this.foreignPivotKey,
      this.relatedPivotKey,
      ) {
    addConstraints();
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

  /// Eagerly loads relationships to solve N+1 issues.
  ///
  /// Strategy:
  /// 1. Fetch pivot rows via raw SQL (bypassing QueryBuilder for the intermediate table).
  /// 2. Fetch related models in a single batch.
  /// 3. Stitch results back to parents in-memory.
  @override
  Future<void> match(List<Model> models, String relationName) async {
    final parentIds = getKeys(models, parent.primaryKey);
    if (parentIds.isEmpty) return;

    final db = DatabaseManager().db;

    final placeholders = List.filled(parentIds.length, '?').join(',');
    final pivotSql =
        'SELECT * FROM $pivotTable WHERE $foreignPivotKey IN ($placeholders)';
    final pivotRows = await db.getAll(pivotSql, parentIds);

    if (pivotRows.isEmpty) return;

    final relatedIds = pivotRows
        .map((r) => r[relatedPivotKey])
        .toSet()
        .toList();

    final pk = creator({}).primaryKey;
    final relatedModels = await QueryBuilder<R>(
      table,
      creator,
    ).whereIn(pk, relatedIds).get();

    // Map for O(1) lookup: related_id -> model instance
    final relatedDict = {
      for (var m in relatedModels) normKey(m.id)!: m,
    };

    for (var model in models) {
      final myId = normKey(model.id);

      // Filter pivots belonging to this specific parent
      final myPivots = pivotRows.where(
            (r) => normKey(r[foreignPivotKey]) == myId,
      );

      final matches = <R>[];
      for (var pivot in myPivots) {
        final rId = normKey(pivot[relatedPivotKey]);
        if (rId != null && relatedDict.containsKey(rId)) {
          matches.add(relatedDict[rId]!);
        }
      }

      model.relations[relationName] = matches;
    }
  }
}