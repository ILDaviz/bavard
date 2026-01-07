import '../core/grammar.dart';
import '../core/query_builder.dart';

class PostgresGrammar extends Grammar {
  @override
  String compileSelect(QueryBuilder query) {
    return concatenate(compileComponents(query));
  }

  @override
  String compileInsert(QueryBuilder query, List<Map<String, dynamic>> values) {
    if (values.isEmpty) return '';

    final columns = values.first.keys.toList()..sort();

    final columnsSql = wrapArray(columns).join(', ');
    final rowPlaceholders =
        '(' + List.filled(columns.length, '?').join(', ') + ')';
    final valuesSql = List.filled(values.length, rowPlaceholders).join(', ');

    return 'INSERT INTO ${wrap(query.table)} ($columnsSql) VALUES $valuesSql';
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
    if (value.startsWith('"') && value.endsWith('"')) return value;
    return '"$value"';
  }

  @override
  String parameter(dynamic value) {
    return '?';
  }

  @override
  String formatBoolForDebug(bool value) => value ? 'TRUE' : 'FALSE';

  @override
  List<dynamic> prepareBindings(List<dynamic> bindings) {
    return bindings.map((value) {
      // Postgres handles boolean natively, no need to convert to 0/1
      if (value is DateTime) return value.toIso8601String();
      return value;
    }).toList();
  }
}
