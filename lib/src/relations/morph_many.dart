import 'relation.dart';
import '../core/model.dart';
import '../core/query_builder.dart';

/// Defines a polymorphic one-to-many relationship.
///
/// Allows a child model to belong to multiple types of parent models using a composite key
/// (ID + Type), rather than specific foreign keys.
/// e.g. A `Comment` belongs to either a `Post` or `Video` via `commentable_id` and `commentable_type`.
class MorphMany<R extends Model> extends Relation<R> {
  /// The prefix for the polymorphic columns (e.g., "commentable" implies `commentable_id` and `commentable_type`).
  final String name;

  /// The discriminator value stored in the `{name}_type` column (defaults to the parent's table name).
  final String type;

  final String id;

  MorphMany(super.parent, super.creator, this.name)
    : type = parent.table,
      id = parent.id.toString() {
    addConstraints();
  }

  /// Filters by both the discriminator type and the foreign ID.
  ///
  /// Both constraints are required because foreign IDs are not unique across different parent tables.
  @override
  void addConstraints() {
    where('${name}_type', type);
    where('${name}_id', id);
  }

  /// Eagerly loads polymorphic children for a list of parents.
  ///
  /// Queries the child table for records matching the specific parent [type]
  /// and the list of parent IDs, then distributes them in-memory.
  @override
  Future<void> match(List<Model> models, String relationName) async {
    final ids = getKeys(models, parent.primaryKey);

    final results = (await creator({}).newQuery()
        .where('${name}_type', type)
        .whereIn('${name}_id', ids)
        .get()).cast<R>();

    for (var model in models) {
      final myId = normKey(model.id);

      model.relations[relationName] = results
          .where(
            (r) =>
                normKey(r.attributes['${name}_id']) == myId &&
                r.attributes['${name}_type'] == type,
          )
          .toList();
    }
  }
}
