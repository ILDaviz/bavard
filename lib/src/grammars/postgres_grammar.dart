import '../core/grammar.dart';
import '../core/query_builder.dart';

class PostgresGrammar extends Grammar {
  @override
  String compileSelect(QueryBuilder query) {
    return concatenate(compileComponents(query));
  }

  @override
  String compileInsert(QueryBuilder query, Map<String, dynamic> values) {
    final columns = wrapArray(values.keys.toList()).join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    return 'INSERT INTO ${wrap(query.table)} ($columns) VALUES ($placeholders) RETURNING id';
  }

  @override
  String compileUpdate(QueryBuilder query, Map<String, dynamic> values) {
    final columns = values.keys.map((key) => '${wrap(key)} = ?').join(', ');
    final where = compileWheres(query);
    return 'UPDATE ${wrap(query.table)} SET $columns $where'.trim();
  }

  @override
  String compileDelete(QueryBuilder query) {
    final where = compileWheres(query);
    return 'DELETE FROM ${wrap(query.table)} $where'.trim();
  }

  @override
  String wrap(String value) {
    if (value == '*') return value;
    if (value.contains('.')) {
      return value.split('.').map((segment) => wrap(segment)).join('.');
    }
    // Don't wrap if already wrapped
    if (value.startsWith('"') && value.endsWith('"')) return value;
    return '"$value"';
  }

  @override
  String parameter(dynamic value) {
    // Note: Parameter binding for Postgres ($1, $2...) is typically handled
    // by the driver (e.g. 'postgres' package) or needs stateful compilation.
    // For this implementation, we rely on the driver transforming ? or @
    // or we return '?' and let the adapter handle substitution if needed.
    // Standard SQL uses '?' or named parameters.
    // If strict $1 is needed during string generation, this method would
    // need a counter. For now, we assume the underlying driver or a
    // post-processing step handles ? -> $i conversion if the driver doesn't support ?.
    return '?';
  }

  @override
  List<dynamic> prepareBindings(List<dynamic> bindings) {
    return bindings.map((value) {
      // Postgres handles boolean natively, no need to convert to 0/1
      if (value is DateTime) return value.toIso8601String();
      return value;
    }).toList();
  }
}
