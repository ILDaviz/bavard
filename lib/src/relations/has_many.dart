import 'relation.dart';
import '../core/model.dart';

/// Defines a one-to-many relationship where the foreign key resides on the related model [R].
///
/// e.g. A `User` has many `Post`s (the `posts` table contains a `user_id` column).
class HasMany<R extends Model> extends Relation<R> {
  /// The column on the related model [R] that references the parent.
  final String foreignKey;

  /// The column on the current parent model acting as the reference (usually 'id').
  final String localKey;

  HasMany(super.parent, super.creator, this.foreignKey, this.localKey) {
    addConstraints();
  }

  /// Filters the query to return only children belonging to the current parent instance.
  @override
  void addConstraints() {
    where(foreignKey, parent.attributes[localKey]);
  }

  Future<R> create(Map<String, dynamic> values) async {
    values[foreignKey] = parent.attributes[localKey];

    final instance = creator(values);
    await instance.save();
    return instance;
  }

  /// Eagerly loads related models for a list of parents to prevent N+1 performance issues.
  ///
  /// Fetches all related children in a single `WHERE IN` query and distributes them
  /// to the corresponding parents in-memory.
  @override
  Future<void> match(
    List<Model> models,
    String relationName, {
    List<String> nested = const [],
  }) async {
    final ids = getKeys(models, localKey);

    final results =
        (await creator({})
            .newQuery()
            .withRelations(nested)
            .whereIn(foreignKey, ids)
            .get()).cast<R>();

    for (var model in models) {
      final myKey = normKey(model.attributes[localKey]);
      // Filters the fetched results to find children belonging to this specific parent.
      final children = results
          .where((r) => normKey(r.attributes[foreignKey]) == myKey)
          .toList();

      model.relations[relationName] = children;
    }
  }
}
