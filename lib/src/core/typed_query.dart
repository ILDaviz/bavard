import 'model.dart';
import 'query_builder.dart';

/// Bridge to obtain a strongly-typed `QueryBuilder<T>` from a Model instance.
extension TypedQuery<T extends Model> on T {
  /// Bootstraps the builder chain.
  ///
  /// Downcasts the base `QueryBuilder<Model>` to `QueryBuilder<T>` to ensure
  /// `get()` returns concrete `List<T>` instead of generic `List<Model>`.
  QueryBuilder<T> query() {
    final base = (this as Model).newQuery();
    return base.cast<T>(
          (map) => fromMap(map) as T,
      instanceFactory: () => (this as Model).newInstance() as T,
    );
  }
}