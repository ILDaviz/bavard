import '../core/model.dart';
import '../core/query_builder.dart';

/// Base class for all database relationships.
///
/// Extends [QueryBuilder] to allow fluent chaining of additional constraints
/// directly on the relationship (e.g., `user.posts().where('active', 1).get()`).
abstract class Relation<R extends Model> extends QueryBuilder<R> {
  /// The model instance that spawned this relationship query.
  final Model parent;

  Relation(this.parent, R Function(Map<String, dynamic>) creator)
    : super(
        creator(const {}).table,
        creator,
        instanceFactory: () => creator(const {}).newInstance() as R,
      ) {
    final instance = creator(const {});
    instance.registerGlobalScopes(this);
  }

  /// Applies the initial SQL filtering (e.g., `WHERE user_id = ?`) to scope
  /// the query to the current [parent].
  void addConstraints();

  /// Eager loading contract: fetches related records for a batch of [models]
  /// in a single query (solving N+1) and injects them into the `relations` map.
  Future<void> match(
    List<Model> models,
    String relationName, {
    List<String> nested = const [],
  });

  /// Extracts unique attribute values from a list of models, used to build
  /// `WHERE IN` clauses for batch fetching.
  List<dynamic> getKeys(List<Model> models, String key) {
    return models.map((m) => m.attributes[key]).toSet().toList();
  }

  /// Normalizes keys to Strings to prevent map lookup failures caused by
  /// Type mismatches (e.g. `int` vs `String`) during result matching.
  String? normKey(dynamic v) => v?.toString();
}
