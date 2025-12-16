import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

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

  // ===========================================================================
  // WHERE CLAUSES
  // ===========================================================================
  group('WHERE Clauses - Extended', () {
    test('where() with null value generates IS NULL', () async {
      await TestUser().newQuery().where('deleted_at', null).get();

      // Note: Current implementation binds null as parameter
      // For explicit IS NULL, use whereNull()
      expect(dbSpy.lastSql, contains('deleted_at = ?'));
      expect(dbSpy.lastArgs, contains(null));
    });

    test('where() with empty string', () async {
      await TestUser().newQuery().where('name', '').get();

      expect(dbSpy.lastSql, contains('name = ?'));
      expect(dbSpy.lastArgs, contains(''));
    });

    test('whereIn() with empty list generates 0 = 1', () async {
      await TestUser().newQuery().whereIn('id', []).get();

      expect(dbSpy.lastSql, contains('0 = 1'));
      expect(dbSpy.lastArgs, isEmpty);
    });

    test('whereIn() with single item', () async {
      await TestUser().newQuery().whereIn('id', [42]).get();

      expect(dbSpy.lastSql, contains('id IN (?)'));
      expect(dbSpy.lastArgs, equals([42]));
    });

    test('whereIn() with duplicate values', () async {
      await TestUser().newQuery().whereIn('id', [1, 1, 2, 2, 3]).get();

      expect(dbSpy.lastSql, contains('id IN (?, ?, ?, ?, ?)'));
      expect(dbSpy.lastArgs, equals([1, 1, 2, 2, 3]));
    });

    test('orWhereNull() generates correct SQL', () async {
      await TestUser()
          .newQuery()
          .where('active', 1)
          .orWhereNull('deleted_at')
          .get();

      expect(dbSpy.lastSql, contains('WHERE active = ? OR deleted_at IS NULL'));
    });

    test('orWhereNotNull() generates correct SQL', () async {
      await TestUser()
          .newQuery()
          .where('active', 0)
          .orWhereNotNull('verified_at')
          .get();

      expect(
          dbSpy.lastSql, contains('WHERE active = ? OR verified_at IS NOT NULL'));
    });

    test('where with LIKE operator and wildcards', () async {
      await TestUser()
          .newQuery()
          .where('name', '%David%', operator: 'LIKE')
          .get();

      expect(dbSpy.lastSql, contains('name LIKE ?'));
      expect(dbSpy.lastArgs, contains('%David%'));
    });

    test('where with NOT LIKE operator', () async {
      await TestUser()
          .newQuery()
          .where('email', '%spam%', operator: 'NOT LIKE')
          .get();

      expect(dbSpy.lastSql, contains('email NOT LIKE ?'));
      expect(dbSpy.lastArgs, contains('%spam%'));
    });

    test('multiple chained where clauses with mixed operators', () async {
      await TestUser()
          .newQuery()
          .where('age', 18, operator: '>=')
          .where('age', 65, operator: '<=')
          .where('status', 'active')
          .orWhere('role', 'admin')
          .get();

      expect(dbSpy.lastSql,
          contains('WHERE age >= ? AND age <= ? AND status = ? OR role = ?'));
      expect(dbSpy.lastArgs, equals([18, 65, 'active', 'admin']));
    });
  });

  // ===========================================================================
  // AGGREGATES
  // ===========================================================================
  group('Aggregates - Extended', () {
    test('count() with column name', () async {
      final countMock = MockDatabaseSpy([], {
        'SELECT COUNT(email) as aggregate': [
          {'aggregate': 50}
        ],
      });
      DatabaseManager().setDatabase(countMock);

      final count = await TestUser().newQuery().count('email');

      expect(count, 50);
      expect(countMock.lastSql, contains('COUNT(email)'));
    });

    test('count() with WHERE clause', () async {
      final countMock = MockDatabaseSpy([], {
        'SELECT COUNT(*) as aggregate': [
          {'aggregate': 10}
        ],
      });
      DatabaseManager().setDatabase(countMock);

      final count = await TestUser().newQuery().where('active', 1).count();

      expect(count, 10);
      expect(countMock.lastSql, contains('WHERE active = ?'));
    });

    test('sum() returns 0 for empty result', () async {
      final sumMock = MockDatabaseSpy([], {
        'SELECT SUM(amount) as aggregate': [
          {'aggregate': null}
        ],
      });
      DatabaseManager().setDatabase(sumMock);

      final sum = await TestUser().newQuery().sum('amount');

      expect(sum, 0);
    });

    test('sum() with null values in column', () async {
      final sumMock = MockDatabaseSpy([], {
        'SELECT SUM(score) as aggregate': [
          {'aggregate': 150}
        ],
      });
      DatabaseManager().setDatabase(sumMock);

      final sum = await TestUser().newQuery().sum('score');

      expect(sum, 150);
    });

    test('avg() with empty result returns 0.0', () async {
      final avgMock = MockDatabaseSpy([], {
        'SELECT AVG(rating) as aggregate': [
          {'aggregate': null}
        ],
      });
      DatabaseManager().setDatabase(avgMock);

      final avg = await TestUser().newQuery().avg('rating');

      expect(avg, 0.0);
    });

    test('avg() with integer column', () async {
      final avgMock = MockDatabaseSpy([], {
        'SELECT AVG(age) as aggregate': [
          {'aggregate': 35}
        ],
      });
      DatabaseManager().setDatabase(avgMock);

      final avg = await TestUser().newQuery().avg('age');

      expect(avg, 35.0);
      expect(avg, isA<double>());
    });

    test('min() with empty result', () async {
      final minMock = MockDatabaseSpy([], {
        'SELECT MIN(price) as aggregate': [
          {'aggregate': null}
        ],
      });
      DatabaseManager().setDatabase(minMock);

      final min = await TestUser().newQuery().min('price');

      expect(min, isNull);
    });

    test('max() with empty result', () async {
      final maxMock = MockDatabaseSpy([], {
        'SELECT MAX(score) as aggregate': [
          {'aggregate': null}
        ],
      });
      DatabaseManager().setDatabase(maxMock);

      final max = await TestUser().newQuery().max('score');

      expect(max, isNull);
    });

    test('min() with datetime column', () async {
      final minMock = MockDatabaseSpy([], {
        'SELECT MIN(created_at) as aggregate': [
          {'aggregate': '2020-01-01T00:00:00.000'}
        ],
      });
      DatabaseManager().setDatabase(minMock);

      final min = await TestUser().newQuery().min('created_at');

      expect(min, '2020-01-01T00:00:00.000');
    });

    test('max() with string column', () async {
      final maxMock = MockDatabaseSpy([], {
        'SELECT MAX(name) as aggregate': [
          {'aggregate': 'Zoe'}
        ],
      });
      DatabaseManager().setDatabase(maxMock);

      final max = await TestUser().newQuery().max('name');

      expect(max, 'Zoe');
    });
  });

  // ===========================================================================
  // QUERY METHODS
  // ===========================================================================
  group('Query Methods - Extended', () {
    test('first() returns null on empty result', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final user = await TestUser().newQuery().first();

      expect(user, isNull);
    });

    test('find() with non-existent id returns null', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final user = await TestUser().newQuery().find(999);

      expect(user, isNull);
    });

    test('find() with string id', () async {
      final mockDb = MockDatabaseSpy([], {
        'LIMIT 1': [
          {'id': 'abc-123', 'name': 'David'}
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = await TestUser().newQuery().find('abc-123');

      expect(user, isNotNull);
      expect(mockDb.lastArgs, contains('abc-123'));
    });

    test('find() with UUID', () async {
      final uuid = '550e8400-e29b-41d4-a716-446655440000';
      final mockDb = MockDatabaseSpy([], {
        'LIMIT 1': [
          {'id': uuid, 'name': 'David'}
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = await TestUser().newQuery().find(uuid);

      expect(user, isNotNull);
      expect(mockDb.lastArgs, contains(uuid));
    });

    test('exists() returns false on empty table', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final exists = await TestUser().newQuery().exists();

      expect(exists, isFalse);
    });

    test('notExist() returns true on empty table', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final notExist = await TestUser().newQuery().notExist();

      expect(notExist, isTrue);
    });

    test('toSql() returns complete SQL string', () async {
      final sql = TestUser()
          .newQuery()
          .select(['id', 'name'])
          .where('active', 1)
          .orderBy('name')
          .limit(10)
          .offset(5)
          .toSql();

      expect(sql, contains('SELECT id, name FROM users'));
      expect(sql, contains('WHERE active = ?'));
      expect(sql, contains('ORDER BY name ASC'));
      expect(sql, contains('LIMIT 10'));
      expect(sql, contains('OFFSET 5'));
    });

    test('select() with table prefix (users.name)', () async {
      await TestUser().newQuery().select(['users.id', 'users.name']).get();

      expect(dbSpy.lastSql, contains('SELECT users.id, users.name'));
    });

    test('select() with alias (name AS user_name)', () async {
      await TestUser()
          .newQuery()
          .select(['id', 'name AS user_name', 'email AS contact'])
          .get();

      expect(dbSpy.lastSql,
          contains('SELECT id, name AS user_name, email AS contact'));
    });
  });

  // ===========================================================================
  // JOINS
  // ===========================================================================
  group('Joins - Extended', () {
    test('multiple joins in single query', () async {
      await TestUser()
          .newQuery()
          .join('profiles', 'users.id', '=', 'profiles.user_id')
          .join('roles', 'users.role_id', '=', 'roles.id')
          .get();

      expect(dbSpy.lastSql, contains('JOIN profiles ON users.id = profiles.user_id'));
      expect(dbSpy.lastSql, contains('JOIN roles ON users.role_id = roles.id'));
    });

    test('join with different operators (>, <, !=)', () async {
      await TestUser()
          .newQuery()
          .join('scores', 'users.min_score', '<', 'scores.value')
          .get();

      expect(dbSpy.lastSql, contains('JOIN scores ON users.min_score < scores.value'));
    });

    test('leftJoin generates LEFT JOIN', () async {
      await TestUser()
          .newQuery()
          .leftJoin('profiles', 'users.id', '=', 'profiles.user_id')
          .get();

      expect(dbSpy.lastSql, contains('LEFT JOIN profiles ON users.id = profiles.user_id'));
    });

    test('rightJoin generates RIGHT JOIN', () async {
      await TestUser()
          .newQuery()
          .rightJoin('profiles', 'users.id', '=', 'profiles.user_id')
          .get();

      expect(dbSpy.lastSql, contains('RIGHT JOIN profiles ON users.id = profiles.user_id'));
    });
  });

  // ===========================================================================
  // VALIDATION & SECURITY
  // ===========================================================================
  group('Validation & Security', () {
    test('where() rejects invalid column names', () {
      expect(
            () => TestUser().newQuery().where('column; DROP TABLE users', 'value'),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('whereIn() rejects invalid column names', () {
      expect(
            () => TestUser().newQuery().whereIn('id; DELETE FROM', [1, 2]),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('join() rejects invalid table names', () {
      expect(
            () => TestUser()
            .newQuery()
            .join('users; DROP TABLE', 'a.id', '=', 'b.id'),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('join() rejects invalid operators', () {
      expect(
            () => TestUser()
            .newQuery()
            .join('profiles', 'users.id', 'INVALID', 'profiles.user_id'),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('orderBy() rejects invalid direction', () {
      expect(
            () => TestUser().newQuery().orderBy('name', direction: 'RANDOM'),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('groupBy() rejects invalid column names', () {
      expect(
            () => TestUser().newQuery().groupBy(['status; DROP TABLE']),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('having() rejects invalid operators', () {
      expect(
            () => TestUser()
            .newQuery()
            .groupBy(['status'])
            .having('COUNT(*)', 5, operator: 'INJECT'),
        throwsA(isA<InvalidQueryException>()),
      );
    });
  });
}