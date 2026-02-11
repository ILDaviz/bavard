import 'package:bavard/testing.dart';
import 'package:bavard_migration/src/migration_repository.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationRepository', () {
    late MockDatabaseSpy db;
    late MigrationRepository repo;

    setUp(() {
      db = MockDatabaseSpy();
      repo = MigrationRepository(db);
    });

    test('prepareTable executes correct DDL', () async {
      await repo.prepareTable();
      expect(db.lastSql, contains('CREATE TABLE IF NOT EXISTS migrations'));
      expect(db.lastSql, contains('id INTEGER PRIMARY KEY AUTOINCREMENT'));
    });

    test('log inserts migration record', () async {
      await repo.log('migration_1', 1);
      expect(db.lastSql, contains('INSERT INTO "migrations"'));
      expect(db.lastArgs![0], equals('migration_1'));
      expect(db.lastArgs![1], equals(1));
    });

    test('getRanMigrations returns list of names', () async {
      db.setMockData({
        'SELECT migration_name': [
          {'migration_name': 'm1'},
          {'migration_name': 'm2'},
        ]
      });

      final result = await repo.getRanMigrations();
      expect(result, equals(['m1', 'm2']));
    });
  });
}
