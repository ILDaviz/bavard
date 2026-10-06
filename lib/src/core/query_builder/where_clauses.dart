import '../../schema/columns.dart';
import '../exceptions.dart';
import '../model.dart';
import '../query_builder.dart';
import 'base.dart';
import 'identifiers.dart';

/// WHERE clause construction: basic AND/OR conditions, nested groups, NULL
/// checks, IN/BETWEEN ranges, EXISTS sub-queries, raw fragments and
/// column-to-column comparisons.
mixin WhereClauses<T extends Model> on QueryBuilderBase<T> {
  /// Appends a condition to the query state.
  ///
  /// Validates [operator] against a whitelist to prevent logic injection.
  QueryBuilder<T> where(
    dynamic column, [
    dynamic value,
    String operator = '=',
    String boolean = 'AND',
  ]) {
    String targetColumn;
    String targetOperator;
    dynamic targetValue;
    String targetBoolean = boolean;

    if (column is WhereCondition) {
      targetColumn = column.column;
      // If the column name is empty (due to optional name in Schema), resolve it now using the sourceColumn
      if (targetColumn.isEmpty && column.sourceColumn != null) {
        targetColumn = resolveColumnName(column.sourceColumn);
      }

      targetOperator = column.operator;
      targetValue = column.value;
      targetBoolean = column.boolean;
    } else {
      targetColumn = resolveColumnName(column);
      targetOperator = operator;
      targetValue = value;
    }

    assertIdentifier(targetColumn, dotted: true, what: 'column name');

    if (targetValue == null) {
      final checkOp = normalizeOperator(targetOperator);
      if (checkOp == '=' || checkOp == 'IS') {
        return whereNull(targetColumn, boolean: targetBoolean);
      } else if (checkOp == '<>' || checkOp == '!=' || checkOp == 'IS NOT') {
        return whereNotNull(targetColumn, boolean: targetBoolean);
      }
    }

    final finalOp = normalizeOperator(targetOperator);
    if (!allowedWhereOps.contains(finalOp)) {
      throw InvalidQueryException(
        'Invalid operator for where: $targetOperator',
      );
    }

    String sqlString;

    if (finalOp == 'IN' || finalOp == 'NOT IN') {
      if (targetValue is! List) {
        throw ArgumentError(
          'QueryBuilder error: operator "$finalOp" requires a List as its value. '
          'Received: ${targetValue.runtimeType}',
        );
      }

      if (targetValue.isEmpty) {
        sqlString = '1 = 0';
      } else {
        final placeholders = List.filled(
          targetValue.length,
          grammar.parameter(null),
        ).join(', ');
        sqlString = '${grammar.wrap(targetColumn)} $finalOp ($placeholders)';
        whereBindings.addAll(targetValue);
      }
    } else if (finalOp == 'BETWEEN') {
      if (targetValue is! List || targetValue.length != 2) {
        throw ArgumentError(
          'QueryBuilder error: operator "BETWEEN" requires a List of exactly 2 elements [min, max].',
        );
      }
      sqlString =
          '${grammar.wrap(targetColumn)} $finalOp ${grammar.parameter(targetValue[0])} AND ${grammar.parameter(targetValue[1])}';
      whereBindings.addAll(targetValue);
    } else {
      if (targetValue is List) {
        throw ArgumentError(
          'QueryBuilder error: you cannot use a List with operator "$finalOp". '
          'Use IN, NOT IN or BETWEEN.',
        );
      }

      sqlString =
          '${grammar.wrap(targetColumn)} $finalOp ${grammar.parameter(targetValue)}';
      whereBindings.add(targetValue);
    }

    whereClauses.add({'type': targetBoolean, 'sql': sqlString});

    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> orWhere(
    dynamic column, [
    dynamic value,
    String operator = '=',
  ]) {
    return where(column, value, operator, 'OR');
  }

  /// Adds a nested WHERE group wrapped in parentheses: AND (...).
  ///
  /// Example:
  /// query.whereGroup((q) => q.where('a', 1).orWhere('b', 1))
  /// Generates: ... AND (a = 1 OR b = 1)
  QueryBuilder<T> whereGroup(void Function(QueryBuilder<T> query) callback) {
    return _addNestedWhere(callback, 'AND');
  }

  /// Adds a nested WHERE group wrapped in parentheses: OR (...).
  ///
  /// Example:
  /// query.orWhereGroup((q) => q.where('active', 1).where('age', '>', 18))
  /// Generates: ... OR (active = 1 AND age > 18)
  QueryBuilder<T> orWhereGroup(void Function(QueryBuilder<T> query) callback) {
    return _addNestedWhere(callback, 'OR');
  }

  /// Internal helper to process nested queries.
  QueryBuilder<T> _addNestedWhere(
    void Function(QueryBuilder<T> query) callback,
    String boolean,
  ) {
    final nestedBuilder = QueryBuilder<T>(
      table,
      creator,
      instanceFactory: instanceFactory,
    );

    callback(nestedBuilder);

    final nestedClause = grammar.compileWheres(nestedBuilder);

    if (nestedClause.isNotEmpty) {
      final sqlInside = nestedClause.substring(6);

      whereClauses.add({'type': boolean, 'sql': '($sqlInside)'});

      whereBindings.addAll(nestedBuilder.whereBindings);
    }

    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> whereNull(dynamic column, {String boolean = 'AND'}) {
    final targetColumn = resolveColumnName(column);
    assertIdentifier(targetColumn, dotted: true, what: 'column name');
    whereClauses.add({
      'type': boolean,
      'sql': '${grammar.wrap(targetColumn)} IS NULL',
    });
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> orWhereNull(dynamic column) {
    return whereNull(column, boolean: 'OR');
  }

  QueryBuilder<T> whereNotNull(dynamic column, {String boolean = 'AND'}) {
    final targetColumn = resolveColumnName(column);
    assertIdentifier(targetColumn, dotted: true, what: 'column name');
    whereClauses.add({
      'type': boolean,
      'sql': '${grammar.wrap(targetColumn)} IS NOT NULL',
    });
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> orWhereNotNull(dynamic column) {
    return whereNotNull(column, boolean: 'OR');
  }

  /// Appends an `IN` clause.
  ///
  /// Optimization: If [values] is empty, generates `0 = 1` to short-circuit the query safely.
  QueryBuilder<T> whereIn(
    dynamic column,
    List<dynamic> values, {
    String boolean = 'AND',
  }) {
    final targetColumn = resolveColumnName(column);
    assertIdentifier(targetColumn, dotted: true, what: 'column name');
    if (values.isEmpty) {
      whereClauses.add({'type': boolean, 'sql': '0 = 1'});
      return this as QueryBuilder<T>;
    }

    final placeholders = List.filled(
      values.length,
      grammar.parameter(null),
    ).join(', ');
    whereClauses.add({
      'type': boolean,
      'sql': '${grammar.wrap(targetColumn)} IN ($placeholders)',
    });
    whereBindings.addAll(values);
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> orWhereIn(dynamic column, List<dynamic> values) {
    return whereIn(column, values, boolean: 'OR');
  }

  /// Adds a "between" where clause to the query.
  QueryBuilder<T> whereBetween(
    dynamic column,
    List<dynamic> values, {
    String boolean = 'AND',
    bool not = false,
  }) {
    if (values.length != 2) {
      throw ArgumentError(
        'whereBetween expects a list with exactly two values [min, max].',
      );
    }

    final targetColumn = resolveColumnName(column);
    assertIdentifier(targetColumn, dotted: true, what: 'column name');

    final type = not ? 'NOT BETWEEN' : 'BETWEEN';

    final sql =
        '${grammar.wrap(targetColumn)} $type ${grammar.parameter(values[0])} AND ${grammar.parameter(values[1])}';

    whereClauses.add({'type': boolean, 'sql': sql});
    whereBindings.addAll(values);

    return this as QueryBuilder<T>;
  }

  /// Adds an "or between" where clause to the query.
  QueryBuilder<T> orWhereBetween(dynamic column, List<dynamic> values) {
    return whereBetween(column, values, boolean: 'OR');
  }

  /// Adds a "not between" where clause to the query.
  QueryBuilder<T> whereNotBetween(
    dynamic column,
    List<dynamic> values, {
    String boolean = 'AND',
  }) {
    return whereBetween(column, values, boolean: boolean, not: true);
  }

  /// Adds an "or not between" where clause to the query.
  QueryBuilder<T> orWhereNotBetween(dynamic column, List<dynamic> values) {
    return whereBetween(column, values, boolean: 'OR', not: true);
  }

  /// Nested query support via `EXISTS`.
  ///
  /// Merges the bindings of the sub-query [query] into the parent builder.
  QueryBuilder<T> whereExists(
    QueryBuilder query, {
    String boolean = 'AND',
    bool not = false,
  }) {
    final type = not ? 'NOT EXISTS' : 'EXISTS';
    final subSql = query.toSql();

    whereClauses.add({'type': boolean, 'sql': '$type ($subSql)'});

    whereBindings.addAll(query.whereBindings);
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> orWhereExists(QueryBuilder query) {
    return whereExists(query, boolean: 'OR');
  }

  QueryBuilder<T> whereNotExists(QueryBuilder query) {
    return whereExists(query, not: true);
  }

  QueryBuilder<T> orWhereNotExists(QueryBuilder query) {
    return whereExists(query, boolean: 'OR', not: true);
  }

  /// Raw SQL escape hatch. Use with caution.
  ///
  /// [bindings] must be provided manually if user input is involved.
  QueryBuilder<T> whereRaw(
    String sql, {
    List<dynamic> bindings = const [],
    String boolean = 'AND',
  }) {
    whereClauses.add({'type': boolean, 'sql': sql});
    whereBindings.addAll(bindings);
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> orWhereRaw(String sql, [List<dynamic> bindings = const []]) {
    return whereRaw(sql, bindings: bindings, boolean: 'OR');
  }

  /// Adds a comparison between two columns to the query.
  ///
  /// Example:
  /// ```dart
  /// query.whereColumn('first_name', 'last_name')
  /// // Generates: ... AND "first_name" = "last_name"
  ///
  /// query.whereColumn('updated_at', 'created_at', '>')
  /// // Generates: ... AND "updated_at" > "created_at"
  ///
  /// query.whereColumn([['first_name', 'last_name'], ['updated_at', '>', 'created_at']])
  /// ```
  QueryBuilder<T> whereColumn(
    dynamic first, [
    dynamic second,
    String? operator,
    String boolean = 'AND',
  ]) {
    if (first is List) {
      for (final condition in first) {
        if (condition is List) {
          if (condition.length == 2) {
            whereColumn(condition[0], condition[1], '=', boolean);
          } else if (condition.length >= 3) {
            whereColumn(condition[0], condition[2], condition[1], boolean);
          }
        }
      }
      return this as QueryBuilder<T>;
    }

    final targetFirst = first.toString();
    final targetSecond = second?.toString();
    final targetOperator = operator ?? '=';

    if (targetSecond == null) {
      throw ArgumentError('whereColumn requires at least two columns.');
    }

    assertIdentifier(targetFirst, dotted: true, what: 'column name');
    assertIdentifier(targetSecond, dotted: true, what: 'column name');

    final finalOp = normalizeOperator(targetOperator);
    if (!allowedColumnOps.contains(finalOp)) {
      throw InvalidQueryException(
        'Invalid operator for whereColumn: $targetOperator',
      );
    }

    final sqlString =
        '${grammar.wrap(targetFirst)} $finalOp ${grammar.wrap(targetSecond)}';
    whereClauses.add({'type': boolean, 'sql': sqlString});

    return this as QueryBuilder<T>;
  }

  /// Adds an OR comparison between two columns to the query.
  QueryBuilder<T> orWhereColumn(
    dynamic first, [
    dynamic second,
    String? operator,
  ]) {
    return whereColumn(first, second, operator, 'OR');
  }
}
