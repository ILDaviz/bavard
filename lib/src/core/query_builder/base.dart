import 'package:meta/meta.dart';
import 'package:bavard/schema.dart';

import '../concerns/has_timestamps.dart';
import '../database_manager.dart';
import '../grammar.dart';
import '../model.dart';
import '../query_builder.dart';
import 'identifiers.dart';

/// Shared state and core plumbing behind [QueryBuilder].
///
/// Holds every mutable clause buffer (wheres, joins, bindings...) plus the
/// helpers each concern mixin builds upon: column resolution, global scope
/// application, SQL compilation, eager-load bookkeeping and state cloning via
/// [cast]. Public getters expose a read-only view consumed by [Grammar].
///
/// Concrete behavior is composed by [QueryBuilder] through the thematic
/// mixins under `src/core/query_builder/`, mirroring the `concerns/` pattern
/// used by [Model].
abstract class QueryBuilderBase<T extends Model> {
  final String table;

  /// This create empty instance of the model.
  /// Example : creator({}).newQuery()
  final T Function(Map<String, dynamic>) creator;

  /// Internal factory for empty instances (used during generic casting or hydration).
  @protected
  final T Function() instanceFactory;

  late final T _modelInstance;

  @protected
  final List<Map<String, dynamic>> whereClauses = [];

  @protected
  final List<dynamic> whereBindings = [];

  @protected
  final List<String> joinClauses = [];

  @protected
  final Map<String, ScopeCallback?> eagerLoads = {};

  @protected
  List<dynamic> selectColumns = ['*'];

  @protected
  final List<String> groupByColumns = [];

  @protected
  final List<Map<String, dynamic>> havingClauses = [];

  @protected
  final List<dynamic> havingBindings = [];

  @protected
  final List<Map<String, dynamic>> unionQueries = [];

  @protected
  bool isDistinct = false;

  @protected
  final Map<String, ScopeCallback> globalScopes = {};

  @protected
  bool ignoreGlobalScopes = false;

  @protected
  bool scopesApplied = false;

  @protected
  int? queryOffset;

  @protected
  String? orderBySql;

  /// Resolved column behind [orderBySql] and its direction, tracked separately
  /// so `QueryBuilder.cursor` can build keyset pagination predicates on a
  /// stable sort key.
  @protected
  String? orderByColumn;

  @protected
  String orderByDirection = 'ASC';

  @protected
  int? queryLimit;

  /// Validates [table] immediately to prevent identifier injection attacks.
  QueryBuilderBase(this.table, this.creator, {T Function()? instanceFactory})
    : instanceFactory = instanceFactory ?? (() => creator(const {}).newInstance() as T) {
    assertIdentifier(table, dotted: false, what: 'table name');
    _modelInstance = this.instanceFactory();
  }

  /// Helper to access the current database grammar.
  @protected
  Grammar get grammar => DatabaseManager().db.grammar;

  List<Map<String, dynamic>> get wheres => whereClauses;
  List<dynamic> get columns => selectColumns;
  List<String> get joins => joinClauses;
  List<String> get groups => groupByColumns;
  List<Map<String, dynamic>> get havings => havingClauses;
  List<Map<String, dynamic>> get unions => unionQueries;
  bool get distinctValue => isDistinct;
  String? get orders => orderBySql;
  int? get limitValue => queryLimit;
  int? get offsetValue => queryOffset;

  /// Returns the raw SQL string compiled from current state.
  String toSql() {
    applyScopes();
    return compileSql();
  }

  // ---------------------------------------------------------------------------
  // GLOBAL SCOPES
  // ---------------------------------------------------------------------------

  QueryBuilder<T> withGlobalScope(String name, ScopeCallback scope) {
    globalScopes[name] = scope;
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> withoutGlobalScopes() {
    ignoreGlobalScopes = true;
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> withoutGlobalScope(String name) {
    globalScopes.remove(name);
    return this as QueryBuilder<T>;
  }

  @protected
  void applyScopes() {
    if (ignoreGlobalScopes || scopesApplied) return;

    globalScopes.forEach((name, scope) {
      scope(this as QueryBuilder);
    });

    scopesApplied = true;
  }

  // ---------------------------------------------------------------------------
  // COLUMN RESOLUTION
  // ---------------------------------------------------------------------------

  @protected
  String resolveColumnNameForWrite(dynamic column) {
    if (column is WhereCondition) {
      throw ArgumentError(
        'You passed a WhereCondition to a method expecting a Column or String name. '
        'Did you mean to use the column directly (e.g. User.schema.field)?',
      );
    }
    if (column is Column) {
      return column.name ?? column.toString();
    }
    return column.toString();
  }

  @protected
  String resolveColumnName(dynamic column) {
    if (column is WhereCondition) {
      throw ArgumentError(
        'You passed a WhereCondition to a method expecting a Column or String name. '
        'Did you mean to use the column directly (e.g. User.schema.field)?',
      );
    }
    if (column is Column) {
      final name = column.name ?? _resolveDefaultColumnName(column);

      if (!name.contains('.') && !name.contains('(')) {
        return '$table.$name';
      }
      return name;
    }
    return column.toString();
  }

  String _resolveDefaultColumnName(Column column) {
    if (column is IdColumn) {
      return _modelInstance.primaryKey;
    } else if (column is CreatedAtColumn) {
      if (_modelInstance is HasTimestamps) {
        return (_modelInstance as HasTimestamps).createdAtColumn;
      }
      return 'created_at';
    } else if (column is UpdatedAtColumn) {
      if (_modelInstance is HasTimestamps) {
        return (_modelInstance as HasTimestamps).updatedAtColumn;
      }
      return 'updated_at';
    } else if (column is DeletedAtColumn) {
      return 'deleted_at';
    }
    return '';
  }

  // ---------------------------------------------------------------------------
  // CLONING & COMPILATION
  // ---------------------------------------------------------------------------

  /// Transitions the builder to a new Model type [U] while preserving query constraints.
  ///
  /// Used when query logic (like a generic scope or mixin) needs to operate on a subclass
  /// or a different entity that shares the same table/structure.
  QueryBuilder<U> cast<U extends Model>(
    U Function(Map<String, dynamic>) newCreator, {
    U Function()? instanceFactory,
  }) {
    final qb = QueryBuilder<U>(
      table,
      newCreator,
      instanceFactory: instanceFactory,
    );

    qb.selectColumns = selectColumns;
    qb.whereClauses.addAll(whereClauses);
    qb.whereBindings.addAll(whereBindings);
    qb.joinClauses.addAll(joinClauses);
    qb.eagerLoads.addAll(eagerLoads);
    qb.groupByColumns.addAll(groupByColumns);
    qb.havingClauses.addAll(havingClauses);
    qb.havingBindings.addAll(havingBindings);
    qb.unionQueries.addAll(unionQueries);
    qb.globalScopes.addAll(globalScopes);
    qb.ignoreGlobalScopes = ignoreGlobalScopes;
    qb.orderBySql = orderBySql;
    qb.orderByColumn = orderByColumn;
    qb.orderByDirection = orderByDirection;
    qb.queryLimit = queryLimit;
    qb.queryOffset = queryOffset;
    qb.isDistinct = isDistinct;

    return qb;
  }

  /// Assembles the SQL string.
  ///
  /// Note: bindings remain separate to be passed to the driver's prepared statement.
  @protected
  String compileSql() {
    return grammar.compileSelect(this as QueryBuilder);
  }

  /// Recursively collects bindings from this query and all attached unions.
  @protected
  List<dynamic> getAllBindings() {
    final bindings = [...whereBindings, ...havingBindings];
    for (final union in unionQueries) {
      final query = union['query'] as QueryBuilder;
      bindings.addAll(query.getAllBindings());
    }
    return bindings;
  }
}
