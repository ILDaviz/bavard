import 'package:bavard/bavard.dart';

class MigrationRepository {
  final DatabaseAdapter _adapter;
  final String _table = 'migrations';

  MigrationRepository(this._adapter);

  Future<void> prepareTable() async {
    final grammar = _adapter.grammar;
    String idDef = 'id INTEGER PRIMARY KEY AUTOINCREMENT';
    
    // Check if it's Postgres (assuming PostgresGrammar exists and exports correctly)
    // Since I can't easily import PostgresGrammar dynamically if I don't know the exact path 
    // or if I don't want strict dependency on it, I'll rely on checking class name string 
    // or just checking if it is NOT SQLiteGrammar.
    
    if (grammar is! SQLiteGrammar) {
        // Assume Postgres for now as it's the only other supported dialect in Bavard context
        idDef = 'id SERIAL PRIMARY KEY';
    }

    final sql = '''
      CREATE TABLE IF NOT EXISTS $_table (
        $idDef,
        migration_name VARCHAR(255) NOT NULL,
        batch INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''';

    await _adapter.execute(_table, sql);
  }

  Future<List<String>> getRanMigrations() async {
    // We can't rely on 'migrations' table existence check easily in standard SQL 
    // without catching error or checking schema_information.
    // So we try-catch or assume prepareTable was called.
    
    try {
      final results = await _adapter.getAll(
        'SELECT migration_name FROM $_table ORDER BY batch ASC, id ASC'
      );
      
      return results.map((row) => row['migration_name'] as String).toList();
    } catch (e) {
      // Table might not exist yet?
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getLastBatch() async {
     try {
      final results = await _adapter.getAll(
        'SELECT * FROM $_table WHERE batch = (SELECT MAX(batch) FROM $_table) ORDER BY id DESC'
      );
      return results;
    } catch (e) {
      return [];
    }
  }
  
  Future<int> getNextBatchNumber() async {
    try {
      final result = await _adapter.get(
        'SELECT MAX(batch) as batch FROM $_table'
      );
      final batch = result['batch'];
      if (batch == null) return 1;
      return (batch as int) + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> log(String name, int batch) async {
    await _adapter.insert(_table, {
      'migration_name': name,
      'batch': batch,
      'created_at': DateTime.now().toIso8601String(), // Adapter should handle conversion
    });
  }

  Future<void> delete(String name) async {
    await _adapter.execute(
      _table, 
      'DELETE FROM $_table WHERE migration_name = ?',
      [name]
    );
  }
}
