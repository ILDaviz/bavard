import 'model.dart';

import 'query_builder/aggregate_queries.dart';
import 'query_builder/base.dart';
import 'query_builder/dumps_query.dart';
import 'query_builder/executes_queries.dart';
import 'query_builder/having_clauses.dart';
import 'query_builder/join_clauses.dart';
import 'query_builder/select_clauses.dart';
import 'query_builder/streams_results.dart';
import 'query_builder/union_clauses.dart';
import 'query_builder/where_clauses.dart';

typedef ScopeCallback = void Function(QueryBuilder builder);

/// Fluent interface for constructing type-safe SQL queries and hydrating results into [Model] instances.
///
/// Abstracts raw SQL generation, manages parameter binding for security (SQL injection prevention),
/// and handles the object lifecycle (hydration, dirty checking initialization) and eager loading.
///
/// The implementation is composed from thematic mixins under `src/core/query_builder/`
/// (shared state lives in [QueryBuilderBase]), mirroring the `concerns/` pattern used by [Model]:
/// - [WhereClauses]: WHERE conditions, groups, IN/BETWEEN, EXISTS, raw fragments.
/// - [HavingClauses]: GROUP BY and HAVING clauses.
/// - [JoinClauses]: JOIN clauses and eager-load queueing (`withRelations`).
/// - [SelectClauses]: projection, ordering, limits and DISTINCT.
/// - [UnionClauses]: UNION/INTERSECT/EXCEPT compound queries.
/// - [AggregateQueries]: COUNT/SUM/AVG/MAX/MIN and existence checks.
/// - [ExecutesQueries]: get/first/find plus UPDATE/DELETE/INSERT and hydration.
/// - [StreamsResults]: reactive `watch` and keyset-paginated `cursor`.
/// - [DumpsRawSql]: raw SQL debugging output.
class QueryBuilder<T extends Model> extends QueryBuilderBase<T>
    with
        WhereClauses<T>,
        HavingClauses<T>,
        JoinClauses<T>,
        SelectClauses<T>,
        UnionClauses<T>,
        AggregateQueries<T>,
        ExecutesQueries<T>,
        StreamsResults<T>,
        DumpsRawSql<T> {
  /// Validates [table] immediately to prevent identifier injection attacks.
  QueryBuilder(super.table, super.creator, {super.instanceFactory});
}
