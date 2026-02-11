import 'package:bavard/testing.dart';
import 'package:bavard_migration/src/schema/schema.dart';
import 'package:test/test.dart';

void main() {
  group('Schema.table', () {
    late MockDatabaseSpy db;
    late Schema schema;

    setUp(() {
      db = MockDatabaseSpy();
      schema = Schema(db);
    });

    test('adds columns correctly', () async {
      await schema.table('users', (table) {
        table.string('email');
        table.integer('age').nullable();
      });

      expect(db.history.any((sql) => sql.contains('ALTER TABLE "users" ADD COLUMN "email" TEXT NOT NULL')), isTrue);
      expect(db.history.any((sql) => sql.contains('ALTER TABLE "users" ADD COLUMN "age" INTEGER')), isTrue);
    });

    test('renames columns correctly', () async {
      await schema.table('users', (table) {
        table.renameColumn('name', 'full_name');
      });

      expect(db.history.any((sql) => sql.contains('ALTER TABLE "users" RENAME COLUMN "name" TO "full_name"')), isTrue);
    });

    test('drops indexes correctly', () async {
      await schema.table('users', (table) {
        table.dropIndex('users_email_unique');
      });

      expect(db.history.any((sql) => sql.contains('DROP INDEX "users_email_unique"')), isTrue);
    });
  });
}
