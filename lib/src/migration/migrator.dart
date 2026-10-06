import '../core/database_adapter.dart';
import '../schema/schema.dart';
import 'migration.dart';
import 'migration_repository.dart';

/// A named [Migration] registered with a [Migrator].
///
/// The [name] identifies the migration in the `migrations` tracking table.
/// By convention it matches the file name (e.g.
/// `2026_02_11_000001_create_users_table`) so migrations run in a stable,
/// chronological order.
class MigrationRegistryEntry {
  final String name;
  final Migration instance;

  MigrationRegistryEntry(this.instance, [String? name])
    : name = name ?? _toSnakeCase(instance.runtimeType.toString());

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match m) => '${m[1]}_${m[2]}',
        )
        .toLowerCase();
  }
}

/// Runs [Migration]s against a database, tracking progress in a
/// `migrations` table so each change is applied exactly once.
///
/// This is the runtime engine behind offline-first schema upgrades: register
/// your migrations in code and run [runUp] once during app startup. On
/// subsequent launches (and app updates) only the new migrations are executed.
class Migrator {
  final DatabaseAdapter _adapter;
  final MigrationRepository _repo;
  late final Schema _schema;

  Migrator(this._adapter, this._repo) {
    _schema = Schema(_adapter);
  }

  /// Runs every migration in [migrations] that has not been executed yet.
  ///
  /// Entries are processed in ascending [MigrationRegistryEntry.name] order,
  /// so timestamp-prefixed names preserve chronological execution.
  Future<void> runUp(List<MigrationRegistryEntry> migrations) async {
    await _repo.prepareTable();
    final ran = await _repo.getRanMigrations();

    migrations.sort((a, b) => a.name.compareTo(b.name));

    final batch = await _repo.getNextBatchNumber();

    for (final migration in migrations) {
      if (!ran.contains(migration.name)) {
        print('Migrating: ${migration.name}');
        try {
          await migration.instance.up(_schema);
          await _repo.log(migration.name, batch);
          print('Migrated:  ${migration.name}');
        } catch (e) {
          print('Error migrating ${migration.name}: $e');
          rethrow;
        }
      }
    }
  }

  /// Reverts the last batch of migrations that was run.
  ///
  /// Intended for development workflows; on user devices the schema should
  /// only ever move forward.
  Future<void> runDown(List<MigrationRegistryEntry> migrations) async {
    await _repo.prepareTable();
    final lastBatch = await _repo.getLastBatch();

    if (lastBatch.isEmpty) {
      print('No migrations to rollback.');
      return;
    }

    for (final row in lastBatch) {
      final name = row['migration_name'] as String;

      try {
        final entry = migrations.firstWhere((m) => m.name == name);
        print('Rolling back: $name');
        await entry.instance.down(_schema);
        await _repo.delete(name);
        print('Rolled back:  $name');
      } catch (e) {
        if (e is StateError) {
          print(
            'Migration $name found in DB but file missing locally. Skipping rollback logic for it, but removing from DB? No, unsafe.',
          );
          throw Exception('Migration $name not found locally.');
        }
        rethrow;
      }
    }
  }
}
