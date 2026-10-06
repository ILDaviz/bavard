import '../model.dart';
import '../query_builder.dart';
import 'base.dart';

/// Debugging helpers that render the compiled SQL with inlined bindings.
mixin DumpsRawSql<T extends Model> on QueryBuilderBase<T> {
  String toRawSql() {
    applyScopes();
    String sql = compileSql();
    final allBindings = grammar.prepareBindings(getAllBindings());

    int index = 0;
    StringBuffer result = StringBuffer();
    bool inString = false;
    String? quoteChar;

    for (int i = 0; i < sql.length; i++) {
      String char = sql[i];

      // Handle string literals to avoid replacing '?' inside them
      if ((char == "'" || char == '"') && (i == 0 || sql[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          quoteChar = char;
        } else if (char == quoteChar) {
          inString = false;
          quoteChar = null;
        }
        result.write(char);
      } else if (char == '?' && !inString) {
        if (index < allBindings.length) {
          result.write(_formatValueForDebug(allBindings[index++]));
        } else {
          result.write('?');
        }
      } else {
        result.write(char);
      }
    }
    return result.toString();
  }

  String _formatValueForDebug(dynamic value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return grammar.formatBoolForDebug(value);
    if (value is DateTime) return "'${value.toIso8601String()}'";
    return "'${value.toString().replaceAll("'", "''")}'";
  }

  QueryBuilder<T> printRawSql() {
    print('\x1B[35m[RAW SQL]\x1B[0m ${toRawSql()}');
    return this as QueryBuilder<T>;
  }

  QueryBuilder<T> printQueryAndBindings() {
    print('\x1B[34m[QUERY]\x1B[0m ${compileSql()}');
    print('\x1B[33m[BINDINGS]\x1B[0m ${getAllBindings()}');
    return this as QueryBuilder<T>;
  }

  void printAndDieRawSql() {
    printRawSql();
    throw Exception('🛑 DIE PRINT RAW SQL EXECUTED');
  }
}
