import 'query_builder.dart';
import 'model.dart';

/// Interface for cross-cutting query constraints (e.g., SoftDeletes, Multi-tenancy).
///
/// Global scopes intercept the `QueryBuilder` lifecycle to inject invariants
/// (WHERE clauses) before query execution.
abstract class Scope {
  /// Modifies [builder] to enforce the scope's constraints on the target [model].
  void apply(QueryBuilder builder, Model model);
}