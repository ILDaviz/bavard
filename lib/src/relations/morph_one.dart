import 'morph_many.dart';
import '../core/model.dart';

/// Defines a polymorphic one-to-one relationship.
///
/// Structurally identical to [MorphMany] (uses composite ID+Type keys) but logically
/// restricts the result to a single model instance.
class MorphOne<R extends Model> extends MorphMany<R> {
  MorphOne(super.parent, super.creator, super.name);

  /// Eagerly loads the relationship by delegating batch fetching to [MorphMany.match],
  /// then unwraps the resulting list into a single instance (or null).
  @override
  Future<void> match(
    List<Model> models,
    String relationName, {
    List<String> nested = const [],
  }) async {
    // Reuse MorphMany to fetch and group data into lists efficiently.
    await super.match(models, relationName, nested: nested);

    for (var model in models) {
      final list = model.relations[relationName] as List?;
      model.relations[relationName] =
          (list != null && list.isNotEmpty) ? list.first : null;
    }
  }
}
