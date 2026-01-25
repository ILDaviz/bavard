import '../schema/blueprint.dart';
import '../core/grammar.dart';
import '../core/query_builder.dart';

class PostgresGrammar extends Grammar {
  @override
  String compileCreateTable(Blueprint blueprint) {
    final columns = blueprint.columns.map((col) {
      String def = '${wrap(col.name)} ${getType(col)}';
      
      if (col.isPrimaryKey) {
        def += ' PRIMARY KEY';
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
        
        switch (c.type) {
          case 'fulltext':
            final lang = c.languageValue ?? 'english';
            // Simple GIN tsvector index
            final tsVector = c.columns.map((col) => "to_tsvector('$lang', ${wrap(col)})").join(' || ');
            return 'CREATE INDEX ${wrap(name)} ON ${wrap(blueprint.table)} USING GIN ($tsVector)';
          case 'spatial':
             return 'CREATE INDEX ${wrap(name)} ON ${wrap(blueprint.table)} USING GIST ($cols)';
          default:
             return 'CREATE INDEX ${wrap(name)} ON ${wrap(blueprint.table)} ($cols)';
        }
      }).toList();
  }

  String _createIndexName(String table, String type, List<String> columns) {
    final colStr = columns.join('_');
    return '${table}_${colStr}_$type';
  }

  String getType(ColumnDefinition col) {
    if (col.isAutoIncrement) {
        if (col.type == 'bigInteger' || col.type == 'unsignedBigInteger') return 'BIGSERIAL';
        return 'SERIAL';
    }
  
    switch (col.type) {
      // Strings
      case 'char': return 'CHAR(${col.length ?? 255})';
      case 'string': return 'VARCHAR(${col.length ?? 255})';
      case 'text': return 'TEXT';
      case 'mediumText': return 'TEXT';
      case 'longText': return 'TEXT';
      
      // Integers
      case 'integer': 
      case 'unsignedInteger': return 'INTEGER';
      case 'tinyInteger': 
      case 'unsignedTinyInteger': return 'SMALLINT'; // PG doesn't have TINYINT
      case 'smallInteger': 
      case 'unsignedSmallInteger': return 'SMALLINT';
      case 'mediumInteger': 
      case 'unsignedMediumInteger': return 'INTEGER';
      case 'bigInteger': 
      case 'unsignedBigInteger': return 'BIGINT';
      
      // Floats
      case 'float': return 'DOUBLE PRECISION';
      case 'double': return 'DOUBLE PRECISION';
      case 'decimal': return 'DECIMAL(${col.precision ?? 8}, ${col.scale ?? 2})';
      
      // Boolean
      case 'boolean': return 'BOOLEAN';
      
      // Date & Time
      case 'date': return 'DATE';
      case 'time': return 'TIME';
      case 'timeTz': return 'TIME WITH TIME ZONE';
      case 'dateTime': return 'TIMESTAMP';
      case 'dateTimeTz': return 'TIMESTAMP WITH TIME ZONE';
      case 'timestamp': return 'TIMESTAMP';
      case 'timestampTz': return 'TIMESTAMP WITH TIME ZONE';
      
      // Binary
      case 'binary': return 'BYTEA';
      
      // JSON
      case 'json': return 'JSON';
      case 'jsonb': return 'JSONB';
      
      // UUID
      case 'uuid': return 'UUID';
      
      // Specialty
      case 'ipAddress': return 'INET';
      case 'macAddress': return 'MACADDR';
      case 'enum': 
        return 'VARCHAR(255)';

      default: return 'VARCHAR(255)';
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
