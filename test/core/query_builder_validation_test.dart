import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class TestUser extends Model {
  @override
  String get table => 'users';

  TestUser([super.attributes]);

  @override
  TestUser fromMap(Map<String, dynamic> map) => TestUser(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('WHERE Clauses - Extended', () {
    test('where() with null value generates IS NULL', () async {
      await TestUser().query().where('deleted_at', null).get();

      expect(dbSpy.lastSql, contains('"deleted_at" IS NULL'));
    });

    test('where() with empty string', () async {
      await TestUser().query().where('name', '').get();

      expect(dbSpy.lastSql, contains('"name" = ?'));
      expect(dbSpy.lastArgs, contains(''));
    });

    test('whereIn() with empty list generates 0 = 1', () async {
      await TestUser().query().whereIn('id', []).get();

      expect(dbSpy.lastSql, contains('0 = 1'));
      expect(dbSpy.lastArgs, isEmpty);
    });

    test('whereIn() with single item', () async {
      await TestUser().query().whereIn('id', [42]).get();

      expect(dbSpy.lastSql, contains('"id" IN (?)'));
      expect(dbSpy.lastArgs, equals([42]));
    });

    test('whereIn() with duplicate values', () async {
      await TestUser().query().whereIn('id', [1, 1, 2, 2, 3]).get();

      expect(dbSpy.lastSql, contains('"id" IN (?, ?, ?, ?, ?)'));
      expect(dbSpy.lastArgs, equals([1, 1, 2, 2, 3]));
    });

    test('orWhereNull() generates correct SQL', () async {
      await TestUser()
          .query()
          .where('active', 1)
          .orWhereNull('deleted_at')
          .get();

      expect(dbSpy.lastSql, contains('WHERE "active" = ? OR "deleted_at" IS NULL'));
    });

    test('orWhereNotNull() generates correct SQL', () async {
      await TestUser()
          .query()
          .where('active', 0)
          .orWhereNotNull('verified_at')
          .get();

      expect(
        dbSpy.lastSql,
        contains('WHERE "active" = ? OR "verified_at" IS NOT NULL'),
      );
    });

    test('where with LIKE operator and wildcards', () async {
      await TestUser().query().where('name', '%David%', 'LIKE').get();

      expect(dbSpy.lastSql, contains('"name" LIKE ?'));
      expect(dbSpy.lastArgs, contains('%David%'));
    });

    test('where with NOT LIKE operator', () async {
      await TestUser()
          .query()
          .where('email', '%spam%', 'NOT LIKE')
          .get();

      expect(dbSpy.lastSql, contains('"email" NOT LIKE ?'));
      expect(dbSpy.lastArgs, contains('%spam%'));
    });

    test('multiple chained where clauses with mixed operators', () async {
      await TestUser()
          .query()
          .where('age', 18, '>=')
          .where('age', 65, '<=')
          .where('status', 'active')
          .orWhere('role', 'admin')
          .get();

      expect(
        dbSpy.lastSql,
        contains('WHERE "age" >= ? AND "age" <= ? AND "status" = ? OR "role" = ?'),
      );
      expect(dbSpy.lastArgs, equals([18, 65, 'active', 'admin']));
    });

    test('It handles nested where groups (parentheses)', () async {
      await TestUser().query().where('status', 'active').whereGroup((q) {
        q.where('role', 'admin').orWhere('role', 'editor');
      }).get();

      expect(
        dbSpy.lastSql,
        contains('WHERE "status" = ? AND ("role" = ? OR "role" = ?)'),
      );
      expect(dbSpy.lastArgs, ['active', 'admin', 'editor']);
    });

    test('It handles nested OR groups with correct binding order', () async {
      await TestUser().query().where('age', 18, '>').orWhereGroup((
        q,
      ) {
        q
            .where('status', 'pending')
            .where('created_at', '2023-01-01', '>');
      }).get();

      expect(
        dbSpy.lastSql,
        contains('WHERE "age" > ? OR ("status" = ? AND "created_at" > ?)'),
      );
      expect(dbSpy.lastArgs, [18, 'pending', '2023-01-01']);
    });

    test('It supports deep nesting', () async {
      await TestUser().query().where('a', 1).whereGroup((q1) {
        q1.where('b', 2).orWhereGroup((q2) {
          q2.where('c', 3).where('d', 4);
        });
      }).get();

      expect(
        dbSpy.lastSql,
        contains('WHERE "a" = ? AND ("b" = ? OR ("c" = ? AND "d" = ?))'),
      );
      expect(dbSpy.lastArgs, [1, 2, 3, 4]);
    });
  });

  group('Aggregates - Extended', () {
    test('count() with column name', () async {
      final countMock = MockDatabaseSpy([], {
        'SELECT COUNT(email) as aggregate': [
          {'aggregate': 50},
        ],
      });
      DatabaseManager().setDatabase(countMock);

      final count = await TestUser().query().count('email');

      expect(count, 50);
      expect(countMock.lastSql, contains('COUNT(email)'));
    });

    test('count() with WHERE clause', () async {
      final countMock = MockDatabaseSpy([], {
        'SELECT COUNT(*) as aggregate': [
          {'aggregate': 10},
        ],
      });
      DatabaseManager().setDatabase(countMock);

      final count = await TestUser().query().where('active', 1).count();

      expect(count, 10);
      expect(countMock.lastSql, contains('WHERE "active" = ?'));
    });

    test('sum() returns 0 for empty result', () async {
      final sumMock = MockDatabaseSpy([], {
        'SELECT SUM(amount) as aggregate': [
          {'aggregate': null},
        ],
      });
      DatabaseManager().setDatabase(sumMock);

      final sum = await TestUser().query().sum('amount');

      expect(sum, 0);
    });

    test('sum() with null values in column', () async {
      final sumMock = MockDatabaseSpy([], {
        'SELECT SUM(score) as aggregate': [
          {'aggregate': 150},
        ],
      });
      DatabaseManager().setDatabase(sumMock);

      final sum = await TestUser().query().sum('score');

      expect(sum, 150);
    });

    test('avg() with empty result returns null', () async {
      final avgMock = MockDatabaseSpy([], {
        'SELECT AVG(rating) as aggregate': [
          {'aggregate': null},
        ],
      });
      DatabaseManager().setDatabase(avgMock);

      final avg = await TestUser().query().avg('rating');

      expect(avg, null);
    });

    test('avg() with integer column', () async {
      final avgMock = MockDatabaseSpy([], {
        'SELECT AVG(age) as aggregate': [
          {'aggregate': 35},
        ],
      });
      DatabaseManager().setDatabase(avgMock);

      final avg = await TestUser().query().avg('age');

      expect(avg, 35.0);
      expect(avg, isA<double>());
    });

    test('min() with empty result', () async {
      final minMock = MockDatabaseSpy([], {
        'SELECT MIN(price) as aggregate': [
          {'aggregate': null},
        ],
      });
      DatabaseManager().setDatabase(minMock);

      final min = await TestUser().query().min('price');

      expect(min, isNull);
    });

    test('max() with empty result', () async {
      final maxMock = MockDatabaseSpy([], {
        'SELECT MAX(score) as aggregate': [
          {'aggregate': null},
        ],
      });
      DatabaseManager().setDatabase(maxMock);

      final max = await TestUser().query().max('score');

      expect(max, isNull);
    });

    test('min() with datetime column', () async {
      final minMock = MockDatabaseSpy([], {
        'SELECT MIN(created_at) as aggregate': [
          {'aggregate': '2020-01-01T00:00:00.000'},
        ],
      });
      DatabaseManager().setDatabase(minMock);

      final min = await TestUser().query().min('created_at');

      expect(min, '2020-01-01T00:00:00.000');
    });

    test('max() with string column', () async {
      final maxMock = MockDatabaseSpy([], {
        'SELECT MAX(name) as aggregate': [
          {'aggregate': 'Zoe'},
        ],
      });
      DatabaseManager().setDatabase(maxMock);

      final max = await TestUser().query().max('name');

      expect(max, 'Zoe');
    });
  });

  group('Query Methods - Extended', () {
    test('first() returns null on empty result', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final user = await TestUser().query().first();

      expect(user, isNull);
    });

    test('find() with non-existent id returns null', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final user = await TestUser().query().find(999);

      expect(user, isNull);
    });

    test('find() with string id', () async {
      final mockDb = MockDatabaseSpy([], {
        'LIMIT 1': [
          {'id': 'abc-123', 'name': 'David'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = await TestUser().query().find('abc-123');

      expect(user, isNotNull);
      expect(mockDb.lastArgs, contains('abc-123'));
    });

    test('find() with UUID', () async {
      final uuid = '550e8400-e29b-41d4-a716-446655440000';
      final mockDb = MockDatabaseSpy([], {
        'LIMIT 1': [
          {'id': uuid, 'name': 'David'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = await TestUser().query().find(uuid);

      expect(user, isNotNull);
      expect(mockDb.lastArgs, contains(uuid));
    });

    test('exists() returns false on empty table', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final exists = await TestUser().query().exists();

      expect(exists, isFalse);
    });

    test('notExist() returns true on empty table', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final notExist = await TestUser().query().notExist();

      expect(notExist, isTrue);
    });

    test('toSql() returns complete SQL string', () async {
      final sql = TestUser()
          .query()
          .select(['id', 'name'])
          .where('active', 1)
          .orderBy('name')
          .limit(10)
          .offset(5)
          .toSql();

      expect(sql, contains('SELECT "id", "name" FROM "users"'));
      expect(sql, contains('WHERE "active" = ?'));
      expect(sql, contains('ORDER BY "name" ASC'));
      expect(sql, contains('LIMIT 10'));
      expect(sql, contains('OFFSET 5'));
    });

    test('select() with table prefix (users.name)', () async {
      await TestUser().query().select(['users.id', 'users.name']).get();

      expect(dbSpy.lastSql, contains('SELECT "users"."id", "users"."name"'));
    });

    test('select() with alias (name AS user_name)', () async {
      await TestUser().query().select([
        'id',
        'name AS user_name',
        'email AS contact',
      ]).get();

      expect(
        dbSpy.lastSql,
        contains('SELECT "id", "name" AS "user_name", "email" AS "contact"'),
      );
    });
  });

  group('Joins - Extended', () {
    test('multiple joins in single query', () async {
      await TestUser()
          .query()
          .join('profiles', 'users.id', '=', 'profiles.user_id')
          .join('roles', 'users.role_id', '=', 'roles.id')
          .get();

      expect(
        dbSpy.lastSql,
        contains('JOIN "profiles" ON "users"."id" = "profiles"."user_id"'),
      );
      expect(dbSpy.lastSql, contains('JOIN "roles" ON "users"."role_id" = "roles"."id"'));
    });

    test('join with different operators (>, <, !=)', () async {
      await TestUser()
          .query()
          .join('scores', 'users.min_score', '<', 'scores.value')
          .get();

      expect(
        dbSpy.lastSql,
        contains('JOIN "scores" ON "users"."min_score" < "scores"."value"'),
      );
    });

    test('leftJoin generates LEFT JOIN', () async {
      await TestUser()
          .query()
          .leftJoin('profiles', 'users.id', '=', 'profiles.user_id')
          .get();

      expect(
        dbSpy.lastSql,
        contains('LEFT JOIN "profiles" ON "users"."id" = "profiles"."user_id"'),
      );
    });

    test('rightJoin generates RIGHT JOIN', () async {
      await TestUser()
          .query()
          .rightJoin('profiles', 'users.id', '=', 'profiles.user_id')
          .get();

      expect(
        dbSpy.lastSql,
        contains('RIGHT JOIN "profiles" ON "users"."id" = "profiles"."user_id"'),
      );
    });
  });

  group('Validation & Security', () {
    test('where() rejects invalid column names', () {
      expect(
        () => TestUser().query().where('column; DROP TABLE users', 'value'),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('whereIn() rejects invalid column names', () {
      expect(
        () => TestUser().query().whereIn('id; DELETE FROM', [1, 2]),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('join() rejects invalid table names', () {
      expect(
        () => TestUser().query().join('users; DROP TABLE', 'a.id', '=', 'b.id'),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('join() rejects invalid operators', () {
      expect(
        () => TestUser().query().join(
          'profiles',
          'users.id',
          'INVALID',
          'profiles.user_id',
        ),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('orderBy() rejects invalid direction', () {
      expect(
        () => TestUser().query().orderBy('name', direction: 'RANDOM'),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('groupBy() rejects invalid column names', () {
      expect(
        () => TestUser().query().groupBy(['status; DROP TABLE']),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('having() rejects invalid operators', () {
      expect(
        () => TestUser()
            .query()
            .groupBy(['status'])
            .having('COUNT(*)', 5, operator: 'INJECT'),
        throwsA(isA<InvalidQueryException>()),
      );
    });
  });
}
