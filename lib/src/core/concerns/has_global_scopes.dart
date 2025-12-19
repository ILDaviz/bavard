import '../model.dart';
import '../query_builder.dart';
import '../scope.dart';

/// Injects default query constraints (scopes) into the Model's query builder lifecycle.
///
/// Implements cross-cutting concerns like "Soft Deletes" or "Multi-tenancy"
/// by automatically applying WHERE clauses to every new query instance.
mixin HasGlobalScopes on Model {
  /// The list of default constraints to apply.
  ///
  /// Override this to register scopes (e.g., `[MyCustomScope()]`).
  List<Scope> get globalScopes => [];

  /// Bootstraps the query builder with defined scopes.
  ///
  /// Intercepts the standard builder creation to ensure invariants
  /// are applied before any user-defined `where` clauses.
  @override
  QueryBuilder<Model> newQuery() {
    final builder = super.newQuery();

    for (final scope in globalScopes) {
      scope.apply(builder, this);
    }

    return builder;
  }

  /// Returns a builder with NO default constraints applied.
  ///
  /// Bypasses the local [newQuery] override. Essential for administrative
  /// tasks (e.g., restoring deleted records, auditing across tenants).
  QueryBuilder<Model> withoutGlobalScopes() {
    // Direct super call skips the loop in newQuery().
    return super.newQuery();
  }

  /// Returns a builder with a specific constraint [T] removed.
  ///
  /// Useful for selective bypassing (e.g., ignoring `TenantScope` for
  /// super-admin access while maintaining `SoftDeletesScope`).
  QueryBuilder<Model> withoutGlobalScope<T extends Scope>() {
    final builder = super.newQuery();

    for (final scope in globalScopes) {
      if (scope is! T) {
        scope.apply(builder, this);
      }
    }

    return builder;
  }
}
