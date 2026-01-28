import 'package:bavard/bavard.dart';

class Schema {
  final DatabaseAdapter _adapter;

  Schema(this._adapter);

  /// Create a new table with the provided blueprint.
  Future<void> create(String table, void Function(Blueprint) callback) async {
    final blueprint = Blueprint(table);
    callback(blueprint);
    
    final createSql = _adapter.grammar.compileCreateTable(blueprint);
    await _adapter.execute(table, createSql);

    final indexStatements = _adapter.grammar.compileIndexes(blueprint);
    for (final sql in indexStatements) {
      await _adapter.execute(table, sql);
    }
  }

  /// Modify an existing table (add/drop columns, indexes, etc.).
  Future<void> table(String table, void Function(Blueprint) callback) async {
    final blueprint = Blueprint(table);
    callback(blueprint);

    final grammar = _adapter.grammar;
    final commands = <String>[];

    if (blueprint.dropForeigns.isNotEmpty) {
      commands.addAll(grammar.compileDropForeign(blueprint));
    }
    
    if (blueprint.commands.where((c) => c.type.startsWith('dropIndex') || c.type.startsWith('dropUnique') || c.type.startsWith('dropPrimary')).isNotEmpty) {
       commands.addAll(grammar.compileDropIndex(blueprint));
    }

    if (blueprint.commands.where((c) => c.type == 'dropColumn').isNotEmpty) {
      commands.addAll(grammar.compileDropColumn(blueprint));
    }

    if (blueprint.columns.where((c) => !c.isChange).isNotEmpty) {
      commands.addAll(grammar.compileAdd(blueprint));
    }

    if (blueprint.columns.where((c) => c.isChange).isNotEmpty) {
      commands.addAll(grammar.compileChange(blueprint));
    }

    if (blueprint.commands.where((c) => c.type == 'renameColumn').isNotEmpty) {
      commands.addAll(grammar.compileRenameColumn(blueprint));
    }

    if (blueprint.commands.where((c) => c.type == 'index' || c.type == 'unique' || c.type == 'fulltext' || c.type == 'spatial').isNotEmpty) {
      commands.addAll(grammar.compileIndexes(blueprint));
    }

    for (final sql in commands) {
      await _adapter.execute(table, sql);
    }
  }

  /// Drop an existing table.
  Future<void> drop(String table) async {
    final sql = _adapter.grammar.compileDropTable(table);
    await _adapter.execute(table, sql);
  }

  /// Drop an existing table if it exists.
  Future<void> dropIfExists(String table) async {
    await _adapter.execute(table, 'DROP TABLE IF EXISTS $table');
  }
}
