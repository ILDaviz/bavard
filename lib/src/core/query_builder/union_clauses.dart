import '../model.dart';
import '../query_builder.dart';
import 'base.dart';

/// Compound queries: UNION, UNION ALL, INTERSECT and EXCEPT.
mixin UnionClauses<T extends Model> on QueryBuilderBase<T> {
  /// Combines the result with another query using UNION.
  QueryBuilder<T> union(QueryBuilder query) {
    unionQueries.add({'type': 'UNION', 'query': query});
    return this as QueryBuilder<T>;
  }

  /// Combines the result with another query using UNION ALL.
  QueryBuilder<T> unionAll(QueryBuilder query) {
    unionQueries.add({'type': 'UNION ALL', 'query': query});
    return this as QueryBuilder<T>;
  }

  /// Combines the result with another query using INTERSECT.
  QueryBuilder<T> intersect(QueryBuilder query) {
    unionQueries.add({'type': 'INTERSECT', 'query': query});
    return this as QueryBuilder<T>;
  }

  /// Combines the result with another query using EXCEPT.
  QueryBuilder<T> except(QueryBuilder query) {
    unionQueries.add({'type': 'EXCEPT', 'query': query});
    return this as QueryBuilder<T>;
  }
}
