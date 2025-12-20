import '../model.dart';
import '../query_builder.dart';
import '../scope.dart';

/// Injects default query constraints (scopes) into the Model's query builder lifecycle.
///
/// Implements cross-cutting concerns like "Soft Deletes" or "Multi-tenancy"
/// by automatically applying WHERE clauses to every new query instance.
mixin HasGlobalScopes on Model {
  List<Scope> get globalScopes => [];

  @override
  void registerGlobalScopes(QueryBuilder<Model> builder) {
    super.registerGlobalScopes(builder);

    for (final scope in globalScopes) {
      builder.withGlobalScope(
          scope.runtimeType.toString(),
              (b) => scope.apply(b, this)
      );
    }
  }

  QueryBuilder<Model> withoutGlobalScopes() {
    return newQuery().withoutGlobalScopes();
  }

  QueryBuilder<Model> withoutGlobalScope<T extends Scope>() {
    return newQuery().withoutGlobalScope(T.toString());
  }
}
