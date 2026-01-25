import 'package:bavard/testing.dart';
import 'package:bavard_migration/src/schema/schema.dart';
import 'package:test/test.dart';

void main() {
  group('Schema', () {
    late MockDatabaseSpy db;
    late Schema schema;

    setUp(() {
      db = MockDatabaseSpy();
      schema = Schema(db);
    });

    test('create generates correct SQL with SQLite grammar', () async {
      await schema.create('users', (table) {
        table.id();
        table.string('name');
        table.integer('age').nullable();
        table.timestamps();
      });

      final sql = db.lastSql;
      expect(sql, startsWith('CREATE TABLE "users"'));
      expect(sql, contains('"id" INTEGER PRIMARY KEY AUTOINCREMENT'));
      expect(sql, contains('"name" TEXT NOT NULL'));
      expect(sql, contains('"age" INTEGER'));
      expect(sql, isNot(contains('"age" INTEGER NOT NULL')));
      expect(sql, contains('"created_at" TEXT'));
    });

    test('create generates composite keys and indexes', () async {
      await schema.create('posts', (table) {
        table.integer('id');
        table.integer('user_id');
        table.string('slug').unique();
        table.primary(['id', 'user_id']);
        table.index('slug', 'custom_slug_index');
      });

      // Check CREATE TABLE (includes PRIMARY KEY and UNIQUE)
      expect(db.history[0], contains('PRIMARY KEY ("id", "user_id")'));
      expect(db.history[0], contains('"slug" TEXT UNIQUE'));

      // Check separate CREATE INDEX
      expect(db.history[1], contains('CREATE INDEX "custom_slug_index" ON "posts" ("slug")'));
    });

    test('drop generates correct SQL', () async {
      await schema.drop('users');
      expect(db.lastSql, equals('DROP TABLE "users"'));
    });
  });
}
