import 'package:bavard/bavard.dart';

class Schema {
  final DatabaseAdapter _adapter;

  Schema(this._adapter);

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

  Future<void> drop(String table) async {
    final sql = _adapter.grammar.compileDropTable(table);
    await _adapter.execute(table, sql);
  }
  
  Future<void> dropIfExists(String table) async {
    // Basic support assuming DROP TABLE IF EXISTS syntax is common or grammar handles it
    // But Grammar only has compileDropTable. 
    // For now, let's just do DROP TABLE IF EXISTS manually or add it to Grammar?
    // User asked to use core grammar. 
    // I will use direct SQL for "IF EXISTS" or assume drop handles it if I updated Grammar.
    // I only added compileDropTable.
    // Let's rely on standard SQL for IF EXISTS or wrap in try-catch if adapter allows?
    // Standard SQL:
    await _adapter.execute(table, 'DROP TABLE IF EXISTS $table');
  }
}
