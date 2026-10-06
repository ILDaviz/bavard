import '../exceptions.dart';
import '../grammar.dart';
import '../model.dart';
import '../query_builder.dart';
import 'base.dart';
import 'identifiers.dart';

/// Projection (SELECT), ordering, limiting and DISTINCT control.
mixin SelectClauses<T extends Model> on QueryBuilderBase<T> {
  QueryBuilder<T> select(List<dynamic> columns) {
    selectColumns = columns.map(resolveColumnName).toList();
    return this as QueryBuilder<T>;
  }

  /// Adds aggregate columns to the selection without replacing existing columns.
  ///
  /// Convenience method for adding COUNT, SUM, etc. to the query.
  QueryBuilder<T> selectRaw(String expression) {
    if (selectColumns.length == 1 && selectColumns.first == '*') {
      selectColumns = [RawExpression(expression)];
    } else {
      selectColumns.add(RawExpression(expression));
    }
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> orderBy(dynamic column, {String direction = 'ASC'}) {
    final targetColumn = resolveColumnName(column);
    assertIdentifier(targetColumn, dotted: true, what: 'orderBy column');

    final dirUpper = direction.toUpperCase();
    if (dirUpper != 'ASC' && dirUpper != 'DESC') {
      throw InvalidQueryException('Invalid direction for orderBy: $direction');
    }

    orderByColumn = targetColumn;
    orderByDirection = dirUpper;
    orderBySql = '${grammar.wrap(targetColumn)} $dirUpper';
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> limit(int limit) {
    queryLimit = limit;
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> offset(int offset) {
    queryOffset = offset;
    return this as QueryBuilder<T>;
  }

  /// Forces the query to return distinct results.
  QueryBuilder<T> distinct() {
    isDistinct = true;
    return this as QueryBuilder<T>;
  }
}
