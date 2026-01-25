import '../schema/blueprint.dart';
import '../core/grammar.dart';
import '../core/query_builder.dart';

class SQLiteGrammar extends Grammar {
  @override
  String compileCreateTable(Blueprint blueprint) {
    final columns = blueprint.columns.map((col) {
      String def = '${wrap(col.name)} ${getType(col)}';
      
      if (col.isPrimaryKey) {
        def += ' PRIMARY KEY';
        if (col.isAutoIncrement) def += ' AUTOINCREMENT';
      }
      
      if (col.isUnique) {
        def += ' UNIQUE';
      }
      
      if (!col.isNullable && !col.isPrimaryKey) {
         def += ' NOT NULL';
      }
      
      if (col.defaultValue != null) {
        def += ' DEFAULT ${parameter(col.defaultValue)}';
      } else if (col.useCurrent) {
        def += ' DEFAULT CURRENT_TIMESTAMP';
      }
      
      if (col.type == 'enum' && col.allowedValues != null) {
         final values = col.allowedValues!.map((v) => "'$v'").join(', ');
         def += ' CHECK (${wrap(col.name)} IN ($values))';
      }
      
      return def;
    });

    final constraints = blueprint.commands
      .where((c) => c.type == 'primary' || c.type == 'unique')
      .map((c) {
        final cols = c.columns.map(wrap).join(', ');
        if (c.type == 'primary') return 'PRIMARY KEY ($cols)';
        if (c.type == 'unique') return 'UNIQUE ($cols)';
        return '';
      }).where((s) => s.isNotEmpty);

    final all = [...columns, ...constraints].join(', ');
    
    return 'CREATE TABLE ${wrap(blueprint.table)} ($all)';
  }

  @override
  List<String> compileIndexes(Blueprint blueprint) {
    return blueprint.commands
      .where((c) => c.type != 'primary' && c.type != 'unique')
      .map((c) {
        final name = c.name ?? _createIndexName(blueprint.table, c.type, c.columns);
        final cols = c.columns.map(wrap).join(', ');
        
        // SQLite doesn't natively support fulltext/spatial in standard CREATE INDEX
        // but we can create a normal index as a fallback or skip.
        // For simplicity, we create a normal index for 'index' and 'fulltext'.
        return 'CREATE INDEX ${wrap(name)} ON ${wrap(blueprint.table)} ($cols)';
      }).toList();
  }

  String _createIndexName(String table, String type, List<String> columns) {
    final colStr = columns.join('_');
    return '${table}_${colStr}_$type';
  }

  String getType(ColumnDefinition col) {
    switch (col.type) {
      // Boolean
      case 'boolean': return 'INTEGER';
      
      // Strings
      case 'char': 
      case 'string': 
      case 'text':
      case 'mediumText':
      case 'longText': return 'TEXT';
      
      // Integers
      case 'integer': 
      case 'tinyInteger': 
      case 'smallInteger': 
      case 'mediumInteger': 
      case 'bigInteger': 
      case 'unsignedInteger': 
      case 'unsignedTinyInteger': 
      case 'unsignedSmallInteger': 
      case 'unsignedMediumInteger': 
      case 'unsignedBigInteger': return 'INTEGER';
      
      // Floats
      case 'float': 
      case 'double': 
      case 'decimal': return 'REAL';
      
      // Date & Time (SQLite uses ISO8601 Strings or Unix Time Integers. We default to TEXT for readability/compat)
      case 'date': 
      case 'time': 
      case 'timeTz': 
      case 'dateTime': 
      case 'dateTimeTz': 
      case 'timestamp': 
      case 'timestampTz': return 'TEXT';
      
      // Binary
      case 'binary': return 'BLOB';
      
      // JSON (Stored as TEXT)
      case 'json': 
      case 'jsonb': return 'TEXT';
      
      // UUID (Stored as TEXT)
      case 'uuid': return 'TEXT';
      
      // Specialty
      case 'ipAddress': 
      case 'macAddress': 
      case 'enum': return 'TEXT';

      default: return 'TEXT';
    }
  }

  @override
  String compileDropTable(String table) {
    return 'DROP TABLE ${wrap(table)}';
  }

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
  List<dynamic> prepareBindings(List<dynamic> bindings) {
    return bindings.map((value) {
      if (value is bool) return value ? 1 : 0;
      if (value is DateTime) return value.toIso8601String();
      return value;
    }).toList();
  }
}
