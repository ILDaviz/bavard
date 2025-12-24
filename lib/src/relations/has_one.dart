import 'has_many.dart';
import '../core/model.dart';

/// Defines a one-to-one relationship where the foreign key resides on the related model [R].
///
/// Inherits from [HasMany] to reuse query construction and batch fetching logic,
/// effectively treating the relation as a "collection of one" at the database level.
class HasOne<R extends Model> extends HasMany<R> {
  HasOne(super.parent, super.creator, super.foreignKey, super.localKey);

  Future<R?> getResult() => first();

  /// Eagerly loads the relationship by leveraging [HasMany.match] for batch fetching,
  /// then unwraps the resulting list into a single instance (or null).
  @override
  Future<void> match(
    List<Model> models,
    String relationName, {
    List<String> nested = const [],
  }) async {
    // Reuse HasMany to fetch and group data into lists.
    await super.match(models, relationName, nested: nested);

    for (var model in models) {
      final list = model.relations[relationName] as List?;
      model.relations[relationName] = (list != null && list.isNotEmpty)
          ? list.first
          : null;
    }
  }
}
