import '../exceptions.dart';
import '../model.dart';
import '../query_builder.dart';
import 'base.dart';
import 'identifiers.dart';

/// GROUP BY and HAVING clause construction for aggregate queries.
mixin HavingClauses<T extends Model> on QueryBuilderBase<T> {
  /// Groups results by one or more columns.
  ///
  /// Essential for aggregate queries (COUNT, SUM, AVG) that need to partition
  /// results by specific attributes.
  ///
  /// Example:
  /// ```dart
  /// await User().query()
  ///   .select(['role', 'COUNT(*) as count'])
  ///   .groupBy(['role'])
  ///   .get();
  /// ```
  QueryBuilder<T> groupBy(List<dynamic> columns) {
    for (final column in columns) {
      final targetColumn = resolveColumnName(column);
      assertIdentifier(targetColumn, dotted: true, what: 'groupBy column');
      groupByColumns.add(targetColumn);
    }
    return this as QueryBuilder<T>;
  }

  /// Convenience method for grouping by a single column.
  QueryBuilder<T> groupByColumn(dynamic column) {
    return groupBy([column]);
  }

  /// Adds a HAVING clause to filter grouped results.
  ///
  /// HAVING operates on aggregate results (post-GROUP BY), unlike WHERE
  /// which filters individual rows before grouping.
  ///
  /// Example:
  /// ```dart
  /// await Order().query()
  ///   .select(['customer_id', 'SUM(total) as total_spent'])
  ///   .groupBy(['customer_id'])
  ///   .having('SUM(total)', 1000, operator: '>')
  ///   .get();
  /// ```
  QueryBuilder<T> having(
    dynamic column,
    dynamic value, {
    String operator = '=',
    String boolean = 'AND',
  }) {
    final op = normalizeOperator(operator);
    if (!allowedHavingOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for having: $operator');
    }

    final targetColumn = resolveColumnName(column);
    final sqlCol = targetColumn.contains('(')
        ? targetColumn
        : grammar.wrap(targetColumn);
    havingClauses.add({
      'type': boolean,
      'sql': '$sqlCol $op ${grammar.parameter(value)}',
    });
    havingBindings.add(value);
    return this as QueryBuilder<T>;
  }

  /// Adds an OR HAVING clause.
  QueryBuilder<T> orHaving(
    dynamic column,
    dynamic value, {
    String operator = '=',
  }) {
    return having(column, value, operator: operator, boolean: 'OR');
  }

  /// Adds a raw HAVING clause for complex aggregate conditions.
  ///
  /// Use for expressions that cannot be represented with simple column comparisons.
  ///
  /// Example:
  /// ```dart
  /// await Product().query()
  ///   .select(['category', 'AVG(price) as avg_price'])
  ///   .groupBy(['category'])
  ///   .havingRaw('AVG(price) > ? AND COUNT(*) >= ?', bindings: [50, 10])
  ///   .get();
  /// ```
  QueryBuilder<T> havingRaw(
    String sql, {
    List<dynamic> bindings = const [],
    String boolean = 'AND',
  }) {
    havingClauses.add({'type': boolean, 'sql': sql});
    havingBindings.addAll(bindings);
    return this as QueryBuilder<T>;
  }

  /// Adds an OR raw HAVING clause.
  QueryBuilder<T> orHavingRaw(String sql, [List<dynamic> bindings = const []]) {
    return havingRaw(sql, bindings: bindings, boolean: 'OR');
  }

  /// Adds a HAVING clause that checks for NULL.
  QueryBuilder<T> havingNull(dynamic column, {String boolean = 'AND'}) {
    final targetColumn = resolveColumnName(column);
    final sqlCol = targetColumn.contains('(')
        ? targetColumn
        : grammar.wrap(targetColumn);

    havingClauses.add({'type': boolean, 'sql': '$sqlCol IS NULL'});
    return this as QueryBuilder<T>;
  }

  /// Adds a HAVING clause that checks for NOT NULL.
  QueryBuilder<T> havingNotNull(dynamic column, {String boolean = 'AND'}) {
    final targetColumn = resolveColumnName(column);
    final sqlCol = targetColumn.contains('(')
        ? targetColumn
        : grammar.wrap(targetColumn);

    havingClauses.add({'type': boolean, 'sql': '$sqlCol IS NOT NULL'});
    return this as QueryBuilder<T>;
  }

  /// Adds a HAVING BETWEEN clause.
  ///
  /// Useful for filtering aggregates within a range.
  QueryBuilder<T> havingBetween(
    dynamic column,
    dynamic min,
    dynamic max, {
    String boolean = 'AND',
  }) {
    final targetColumn = resolveColumnName(column);
    final sqlCol = targetColumn.contains('(')
        ? targetColumn
        : grammar.wrap(targetColumn);
    havingClauses.add({
      'type': boolean,
      'sql':
          '$sqlCol BETWEEN ${grammar.parameter(min)} AND ${grammar.parameter(max)}',
    });
    havingBindings.addAll([min, max]);
    return this as QueryBuilder<T>;
  }
}
