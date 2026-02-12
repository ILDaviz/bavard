import 'package:bavard/bavard.dart';

/// Manages the persistence of migration metadata in the database.
class MigrationRepository {
  final DatabaseAdapter _adapter;
  final String _table = 'migrations';

  MigrationRepository(this._adapter);

  /// Ensures the migrations tracking table exists.
  Future<void> prepareTable() async {
    final grammar = _adapter.grammar;

    // Default to SQLite syntax for auto-incrementing IDs
    String idDef = 'id INTEGER PRIMARY KEY AUTOINCREMENT';

    // Use Postgres-specific syntax if applicable
    if (grammar is! SQLiteGrammar) {
      idDef = 'id SERIAL PRIMARY KEY';
    }

    final sql =
        '''
      CREATE TABLE IF NOT EXISTS $_table (
        $idDef,
        migration_name VARCHAR(255) NOT NULL,
        batch INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''';

    await _adapter.execute(_table, sql);
  }

  /// Retrieves the names of all migrations that have already been executed.
  Future<List<String>> getRanMigrations() async {
    try {
      final results = await _adapter.getAll(
        'SELECT migration_name FROM $_table ORDER BY batch ASC, id ASC',
      );

      return results.map((row) => row['migration_name'] as String).toList();
    } catch (e) {
      // Return empty if the table doesn't exist yet
      return [];
    }
  }

  /// Gets all migration records from the very last batch.
  Future<List<Map<String, dynamic>>> getLastBatch() async {
    try {
      final results = await _adapter.getAll(
        'SELECT * FROM $_table WHERE batch = (SELECT MAX(batch) FROM $_table) ORDER BY id DESC',
      );
      return results;
    } catch (e) {
      return [];
    }
  }

  /// Calculates the next batch number to be used for new migrations.
  Future<int> getNextBatchNumber() async {
    try {
      final result = await _adapter.get(
        'SELECT MAX(batch) as batch FROM $_table',
      );
      final batch = result['batch'];
      if (batch == null) return 1;
      return (batch as int) + 1;
    } catch (e) {
      return 1;
    }
  }

  /// Records a successful migration in the tracking table.
  Future<void> log(String name, int batch) async {
    await _adapter.insert(_table, {
      'migration_name': name,
      'batch': batch,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Removes a migration record from the tracking table.
  Future<void> delete(String name) async {
    await _adapter.execute(
      _table,
      'DELETE FROM $_table WHERE migration_name = ?',
      [name],
    );
  }
}
