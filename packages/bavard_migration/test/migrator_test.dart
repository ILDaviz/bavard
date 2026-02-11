import 'package:bavard/bavard.dart'; // For DatabaseAdapter
import 'package:bavard/testing.dart';
import 'package:bavard_migration/src/migration.dart';
import 'package:bavard_migration/src/migration_repository.dart';
import 'package:bavard_migration/src/migrator.dart';
import 'package:bavard_migration/src/schema/schema.dart';
import 'package:test/test.dart';

class TestMigration extends Migration {
  bool upCalled = false;
  bool downCalled = false;

  @override
  Future<void> up(Schema schema) async {
    upCalled = true;
  }

  @override
  Future<void> down(Schema schema) async {
    downCalled = true;
  }
}

void main() {
  group('Migrator', () {
    late MockDatabaseSpy db;
    late MigrationRepository repo;
    late Migrator migrator;

    setUp(() {
      db = MockDatabaseSpy();
      repo = MigrationRepository(db);
      migrator = Migrator(db, repo);
    });

    test('runUp executes new migrations', () async {
      final m1 = TestMigration();
      final m2 = TestMigration();

      db.setMockData({
        'SELECT migration_name': [],
        'SELECT MAX(batch)': [
          {'batch': 0},
        ],
      });

      await migrator.runUp([
        MigrationRegistryEntry(m1, 'm1'),
        MigrationRegistryEntry(m2, 'm2'),
      ]);

      expect(m1.upCalled, isTrue);
      expect(m2.upCalled, isTrue);

      final inserts = db.history.where(
        (sql) => sql.startsWith('INSERT INTO "migrations"'),
      );
      expect(inserts.length, equals(2));
    });

    test('runUp skips existing migrations', () async {
      final m1 = TestMigration();
      final m2 = TestMigration();

      db.setMockData({
        'SELECT migration_name': [
          {'migration_name': 'm1'},
        ],
        'SELECT MAX(batch)': [
          {'batch': 1},
        ],
      });

      await migrator.runUp([
        MigrationRegistryEntry(m1, 'm1'),
        MigrationRegistryEntry(m2, 'm2'),
      ]);

      expect(m1.upCalled, isFalse);
      expect(m2.upCalled, isTrue);
    });

    test('runDown reverts last batch', () async {
      final m1 = TestMigration();

      db.setMockData({
        'SELECT * FROM migrations WHERE batch': [
          {'migration_name': 'm1'},
        ],
      });

      await migrator.runDown([MigrationRegistryEntry(m1, 'm1')]);

      expect(m1.downCalled, isTrue);
      expect(
        db.history.any((sql) => sql.startsWith('DELETE FROM migrations')),
        isTrue,
      );
    });
  });
}
