import 'relation.dart';
import '../core/model.dart';
import '../core/query_builder.dart';

/// Defines an inverse one-to-one or many-to-one relationship where the foreign key
/// resides on the child model (the [parent] of this relation instance).
///
/// e.g. A `Comment` belongs to a `Post` (Comment has `post_id`).
class BelongsTo<R extends Model> extends Relation<R> {
  final String foreignKey;
  final String ownerKey;

  BelongsTo(super.parent, super.creator, this.foreignKey, this.ownerKey) {
    addConstraints();
  }

  /// Applies constraints for lazy loading: filters the query where the
  /// [ownerKey] matches the current model's [foreignKey].
  @override
  void addConstraints() {
    where('$table.$ownerKey', parent.attributes[foreignKey]);
  }

  Future<R?> getResult() => first();

  /// Eagerly loads related models in a single batch query to prevent N+1 performance issues.
  ///
  /// Matches the fetched owners back to the [models] list via an in-memory dictionary lookup.
  @override
  Future<void> match(
    List<Model> models,
    String relationName, {
    ScopeCallback? scope,
    Map<String, ScopeCallback?> nested = const {},
  }) async {
    final ids = getKeys(models, foreignKey).where((id) => id != null).toList();

    final query = creator({}).newQuery();
    query.withRelations(nested);
    query.whereIn(ownerKey, ids);

    if (scope != null) {
      scope(query);
    }

    final results = await query.get();

    // Map results by owner ID for O(1) assignment back to child models.
    final dictionary = {
      for (var r in results) normKey(r.attributes[ownerKey]): r,
    };

    for (var model in models) {
      final key = normKey(model.attributes[foreignKey]);
      if (key != null && dictionary.containsKey(key)) {
        model.relations[relationName] = dictionary[key];
      }
    }
  }
}
