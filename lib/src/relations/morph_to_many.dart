import 'relation.dart';
import '../core/model.dart';
import '../core/database_manager.dart';
import '../core/utils.dart';

/// Defines a polymorphic many-to-many relationship.
///
/// Allows a model to belong to multiple other models of different types via a single pivot table
/// that tracks both ID and Type (e.g., a `Tag` system used by both `Post` and `Video`).
///
/// Schema convention (e.g. name='taggable'):
/// - Pivot table: `taggables`
/// - Columns: `tag_id` (Related), `taggable_id` (Parent ID), `taggable_type` (Parent Table).
class MorphToMany<R extends Model> extends Relation<R> {
  final String name;

  MorphToMany(super.parent, super.creator, this.name) {
    addConstraints();
  }

  // --- Convention-based Pivot Configuration ---

  String get pivotTable => '${name}s';

  /// Column referencing the related model (e.g., `tag_id`).
  String get pivotRelatedId => Utils.foreignKey(table);

  /// Column storing the parent's ID (e.g., `taggable_id`).
  String get pivotMorphId => '${name}_id';

  /// Column storing the parent's discriminator type (e.g., `taggable_type`).
  String get pivotMorphType => '${name}_type';

  /// Configures the INNER JOIN and filters by both Parent ID and Parent Type.
  ///
  /// The type check (`pivotMorphType`) is strictly required to differentiate between
  /// parents from different tables that might share the same numeric ID.
  @override
  void addConstraints() {
    join(pivotTable, '$table.id', '=', '$pivotTable.$pivotRelatedId');
    where('$pivotTable.$pivotMorphId', parent.id);
    where('$pivotTable.$pivotMorphType', parent.table);
  }

  /// Eagerly loads relationships to solve N+1 performance issues.
  ///
  /// Strategy:
  /// 1. Query the pivot table directly using raw SQL to filter by the specific parent Type
  ///    and the list of Parent IDs.
  /// 2. Batch fetch the related models using the IDs extracted from the pivot results.
  /// 3. Reconstruct the many-to-many mappings in-memory.
  @override
  Future<void> match(List<Model> models, String relationName) async {
    final parentIds = getKeys(models, parent.primaryKey);
    final db = DatabaseManager().db;

    final relatedForeignKey = Utils.foreignKey(table);

    // Raw SQL required to combine static Type filtering with dynamic ID IN-clause.
    final pivotSql =
        "SELECT * FROM $pivotTable WHERE $pivotMorphType = ? AND ${name}_id IN (${parentIds.map((_) => '?').join(',')})";

    final params = [parent.table, ...parentIds];
    final pivotRows = await db.getAll(pivotSql, params);

    if (pivotRows.isEmpty) return;

    final relatedIds = pivotRows
        .map((r) => r[relatedForeignKey])
        .toSet()
        .toList();

    // Dynamically resolve the primary key of the related model (do not assume 'id').
    final relatedPk = creator({}).primaryKey;

    final relatedModels = (await creator(
      {},
    ).newQuery().whereIn(relatedPk, relatedIds).get()).cast<R>();

    // Map: related_id -> model instance
    final relatedDict = {for (var m in relatedModels) normKey(m.id)!: m};

    for (var model in models) {
      final myId = normKey(model.id);

      final myPivots = pivotRows.where(
        (r) =>
            normKey(r[pivotMorphId]) == myId &&
            r[pivotMorphType] == parent.table,
      );

      final list = <R>[];
      for (var pivot in myPivots) {
        final rId = normKey(pivot[relatedForeignKey]);
        if (rId != null && relatedDict.containsKey(rId)) {
          list.add(relatedDict[rId]!);
        }
      }

      model.relations[relationName] = list;
    }
  }
}
