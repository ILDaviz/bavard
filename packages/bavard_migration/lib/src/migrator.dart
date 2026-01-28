import 'dart:io';
import 'package:bavard/bavard.dart';
import 'migration.dart';
import 'migration_repository.dart';
import 'schema/schema.dart';
import 'package:path/path.dart' as p;

class MigrationRegistryEntry {
  final String name;
  final Migration instance;
  MigrationRegistryEntry(this.name, this.instance);
}

class Migrator {
  final DatabaseAdapter _adapter;
  final MigrationRepository _repo;
  late final Schema _schema;

  Migrator(this._adapter, this._repo) {
    _schema = Schema(_adapter);
  }

  List<File> scan(String directory) {
    final dir = Directory(directory);
    if (!dir.existsSync()) return [];
    
    return dir.listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
  }

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
              print('Migration $name found in DB but file missing locally. Skipping rollback logic for it, but removing from DB? No, unsafe.');
              throw Exception('Migration $name not found locally.');
          }
          rethrow;
      }
    }
  }
}
