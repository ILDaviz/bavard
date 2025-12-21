import 'query_builder.dart';

class RawExpression {
  final String value;
  const RawExpression(this.value);
  @override
  String toString() => value;
}

abstract class Grammar {
  /// Compiles a SELECT query into a SQL string.
  String compileSelect(QueryBuilder query);

  /// Compiles an INSERT query into a SQL string.
  String compileInsert(QueryBuilder query, Map<String, dynamic> values);

  /// Compiles an UPDATE query into a SQL string.
  String compileUpdate(QueryBuilder query, Map<String, dynamic> values);

  /// Compiles a DELETE query into a SQL string.
  String compileDelete(QueryBuilder query);

  /// Wraps a value (table or column name) in quotes.
  String wrap(String value);

  /// Wraps an array of values.
  List<String> wrapArray(List<String> values) => values.map(wrap).toList();

  /// Returns a parameter placeholder.
  String parameter(dynamic value);

  /// Normalizes bindings for the specific database driver.
  List<dynamic> prepareBindings(List<dynamic> bindings);

  /// Concatenates components of a SELECT query.
  String concatenate(List<String> components) {
    return components.where((component) => component.isNotEmpty).join(' ');
  }

  /// Compiles components for a SELECT query.
  /// Subclasses can override this to change the order or components.
  List<String> compileComponents(QueryBuilder query) {
    return [
      'SELECT',
      compileColumns(query, query.columns),
      'FROM',
      wrap(query.table),
      ...compileJoins(query, query.joins),
      compileWheres(query),
      compileGroups(query, query.groups),
      compileHavings(query),
      compileOrders(query, query.orders),
      compileLimit(query, query.limitValue),
      compileOffset(query, query.offsetValue),
    ];
  }

  String compileColumns(QueryBuilder query, List<dynamic> columns) {
    final needsPrefixing = query.joins.isNotEmpty;

    return columns.map((column) {
      if (column is RawExpression) return column.value;
      
      final colStr = column.toString();
      if (colStr == '*') return '${wrap(query.table)}.*';

      if (colStr.toLowerCase().contains(' as ')) {
        final parts = colStr.split(RegExp(r'\s+as\s+', caseSensitive: false));
        if (parts.length == 2) {
          return '${wrap(parts[0])} AS ${wrap(parts[1])}';
        }
      }
      
      if (needsPrefixing && !colStr.contains('.') && !colStr.contains('(')) {
         return wrap('${query.table}.$colStr');
      }
      
      return wrap(colStr);
    }).join(', ');
  }

  List<String> compileJoins(QueryBuilder query, List<String> joins) {
    return joins; // Joins are currently stored as raw strings in QueryBuilder
  }

  String compileWheres(QueryBuilder query) {
    if (query.wheres.isEmpty) return '';

    final sql = query.wheres.map((where) {
      final boolean = where['type'];
      final querySql = where['sql'];
      return '$boolean $querySql';
    }).join(' ');
    
    // Remove the leading logic operator (AND/OR)
    return 'WHERE ' + sql.replaceFirst(RegExp(r'^(AND|OR)\s+'), '');
  }

  String compileGroups(QueryBuilder query, List<String> groups) {
    if (groups.isEmpty) return '';
    return 'GROUP BY ' + groups.map(wrap).join(', ');
  }

  String compileHavings(QueryBuilder query) {
    if (query.havings.isEmpty) return '';

    final sql = query.havings.map((having) {
      final boolean = having['type'];
      final querySql = having['sql'];
      return '$boolean $querySql';
    }).join(' ');

    return 'HAVING ' + sql.replaceFirst(RegExp(r'^(AND|OR)\s+'), '');
  }

  String compileOrders(QueryBuilder query, String? orderBy) {
    if (orderBy == null) return '';
    return 'ORDER BY $orderBy';
  }

  String compileLimit(QueryBuilder query, int? limit) {
    if (limit == null) return '';
    return 'LIMIT $limit';
  }

  String compileOffset(QueryBuilder query, int? offset) {
    if (offset == null) return '';
    return 'OFFSET $offset';
  }
}
