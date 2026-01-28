import '../schema/blueprint.dart';
import '../core/grammar.dart';
import '../core/query_builder.dart';

class SQLiteGrammar extends Grammar {
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
  String compileCreateTable(Blueprint blueprint) {
    final columns = blueprint.columns.map(_compileColumn).toList();

    final constraints = blueprint.commands
        .whereType<IndexDefinition>()
        .where((c) => c.type == 'primary' || c.type == 'unique')
        .map((c) {
          final cols = c.columns.map(wrap).join(', ');
          if (c.type == 'primary') return 'PRIMARY KEY ($cols)';
          if (c.type == 'unique') return 'UNIQUE ($cols)';
          return '';
        })
        .where((s) => s.isNotEmpty);

    final foreignKeys = _compileForeignKeys(blueprint);

    final all = [...columns, ...constraints, ...foreignKeys].join(', ');

    return 'CREATE TABLE ${wrap(blueprint.table)} ($all)';
  }

  String _compileColumn(ColumnDefinition col) {
    String def = '${wrap(col.name)} ${_getType(col)}';

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
  }

  List<String> _compileForeignKeys(Blueprint blueprint) {
    return blueprint.commands.whereType<ForeignKeyDefinition>().map((fk) {
      String sql =
          'FOREIGN KEY (${wrap(fk.column)}) REFERENCES ${wrap(fk.onTable!)} (${wrap(fk.referencesColumn!)})';
      if (fk.onDeleteValue != null) sql += ' ON DELETE ${fk.onDeleteValue}';
      if (fk.onUpdateValue != null) sql += ' ON UPDATE ${fk.onUpdateValue}';
      return sql;
    }).toList();
  }

  @override
  List<String> compileIndexes(Blueprint blueprint) {
    return blueprint.commands
        .whereType<IndexDefinition>()
        .where(
          (command) => command.type != 'primary' && command.type != 'unique',
        )
        .map((command) {
          final colStr = command.columns.join('_');
          final name =
              command.name ?? '${blueprint.table}_${colStr}_${command.type}';
          final cols = command.columns.map(wrap).join(', ');

          return 'CREATE INDEX ${wrap(name)} ON ${wrap(blueprint.table)} ($cols)';
        })
        .toList();
  }

  @override
  List<String> compileAdd(Blueprint blueprint) {
    return blueprint.columns.map((col) {
      return 'ALTER TABLE ${wrap(blueprint.table)} ADD COLUMN ${_compileColumn(col)}';
    }).toList();
  }

  @override
  List<String> compileDropColumn(Blueprint blueprint) {
    throw UnimplementedError(
      'DROP COLUMN is not supported natively by SQLite. Use compileTableRebuild.',
    );
  }

  @override
  List<String> compileRenameColumn(Blueprint blueprint) {
    return blueprint.commands.whereType<RenameColumnCommand>().map((cmd) {
      return 'ALTER TABLE ${wrap(blueprint.table)} RENAME COLUMN ${wrap(cmd.from)} TO ${wrap(cmd.to)}';
    }).toList();
  }

  @override
  List<String> compileDropIndex(Blueprint blueprint) {
    return blueprint.commands.whereType<DropIndexCommand>().map((cmd) {
      return 'DROP INDEX ${wrap(cmd.name)}';
    }).toList();
  }

  @override
  List<String> compileDropForeign(Blueprint blueprint) {
    throw UnimplementedError(
      'DROP FOREIGN KEY is not supported natively by SQLite. Use compileTableRebuild.',
    );
  }

  /// Compiles a table rebuild to support operations not natively supported by SQLite ALTER TABLE.
  ///
  /// The [blueprint] should represent the *new* structure of the table.
  /// The [oldTable] is the name of the existing table to copy data from.
  List<String> compileTableRebuild(Blueprint blueprint, String oldTable) {
    final originalTableName = blueprint.table;
    final tempTableName = 'temp_$originalTableName';

    String createSql = compileCreateTable(blueprint);
    createSql = createSql.replaceFirst(
      wrap(originalTableName),
      wrap(tempTableName),
    );

    final columnNames = blueprint.columns.map((c) => wrap(c.name)).join(', ');
    final copySql =
        'INSERT INTO ${wrap(tempTableName)} ($columnNames) SELECT $columnNames FROM ${wrap(oldTable)}';

    return [
      'PRAGMA foreign_keys=OFF',
      createSql,
      copySql,
      'DROP TABLE ${wrap(oldTable)}',
      'ALTER TABLE ${wrap(tempTableName)} RENAME TO ${wrap(originalTableName)}',
      'PRAGMA foreign_keys=ON',
    ];
  }

  String _getType(ColumnDefinition col) {
    switch (col.type) {
      // Boolean
      case 'boolean':
        return 'INTEGER';

      // Strings
      case 'char':
      case 'string':
      case 'text':
      case 'mediumText':
      case 'longText':
        return 'TEXT';

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
      case 'unsignedBigInteger':
        return 'INTEGER';

      // Floats
      case 'float':
      case 'double':
      case 'decimal':
        return 'REAL';

      // Date & Time
      case 'date':
      case 'time':
      case 'timeTz':
      case 'dateTime':
      case 'dateTimeTz':
      case 'timestamp':
      case 'timestampTz':
        return 'TEXT';

      // Binary
      case 'binary':
        return 'BLOB';

      // JSON (Stored as TEXT)
      case 'json':
      case 'jsonb':
        return 'TEXT';

      // UUID (Stored as TEXT)
      case 'uuid':
        return 'TEXT';

      // Specialty
      case 'ipAddress':
      case 'macAddress':
      case 'enum':
        return 'TEXT';

      default:
        return 'TEXT';
    }
  }

  @override
  String compileDropTable(String table) {
    return 'DROP TABLE ${wrap(table)}';
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
