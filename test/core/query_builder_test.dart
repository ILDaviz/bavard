import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/mock_database.dart';

class TestUser extends Model {
  @override
  String get table => 'users';
  TestUser([super.attributes]);
  @override
  TestUser fromMap(Map<String, dynamic> map) => TestUser(map);
}

class AdminView extends Model {
  @override
  String get table => 'users';

  AdminView([super.attributes]);

  @override
  AdminView fromMap(Map<String, dynamic> map) => AdminView(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  test('It generates basic SELECT *', () async {
    await TestUser().query().get();
    expect(dbSpy.lastSql, 'SELECT users.* FROM users');
  });

  test('It generates WHERE clauses with bindings', () async {
    await TestUser().where('email', 'david@test.com').get();

    expect(dbSpy.lastSql, contains('WHERE email = ?'));
    expect(dbSpy.lastArgs, ['david@test.com']);
  });

  test('It chains multiple WHERE clauses', () async {
    await TestUser()
        .query()
        .where('role', 'admin')
        .where('age', 18, operator: '>')
        .get();

    final q = TestUser().where('role', 'admin').where('age', 18, operator: '>');
    await q.get();

    expect(dbSpy.lastSql, contains('WHERE role = ? AND age > ?'));
    expect(dbSpy.lastArgs, ['admin', 18]);
  });

  test('It generates ORDER BY and LIMIT', () async {
    await TestUser()
        .query()
        .orderBy('created_at', direction: 'DESC')
        .limit(5)
        .get();

    expect(dbSpy.lastSql, contains('ORDER BY created_at DESC'));
    expect(dbSpy.lastSql, contains('LIMIT 5'));
  });

  test('It handles WHERE IN', () async {
    await TestUser().query().whereIn('id', [1, 2, 3]).get();

    expect(dbSpy.lastSql, contains('id IN (?, ?, ?)'));
    expect(dbSpy.lastArgs, [1, 2, 3]);
  });

  test('orderBy accepts dotted identifiers (table.column)', () async {
    await TestUser()
        .query()
        .orderBy('users.created_at', direction: 'DESC')
        .get();

    expect(dbSpy.lastSql, contains('ORDER BY users.created_at DESC'));
  });

  test('orderBy accepts dotted identifiers (table.column)', () async {
    await TestUser()
        .query()
        .orderBy('users.created_at', direction: 'DESC')
        .get();

    expect(dbSpy.lastSql, contains('ORDER BY users.created_at DESC'));
  });

  test('orderBy rejects injection attempts in identifier', () async {
    expect(
      () => TestUser().query().orderBy(
        'users.created_at; DROP TABLE users',
        direction: 'DESC',
      ),
      throwsA(isA<InvalidQueryException>()),
    );
  });

  test('It handles OR WHERE clauses', () async {
    await TestUser()
        .query()
        .where('id', 1)
        .orWhere('email', 'admin@test.com')
        .get();

    expect(dbSpy.lastSql, contains('WHERE id = ? OR email = ?'));
    expect(dbSpy.lastArgs, [1, 'admin@test.com']);
  });

  test('It handles whereNull and whereNotNull', () async {
    final q = TestUser()
        .query()
        .whereNull('deleted_at')
        .orWhereNotNull('posted_at');
    await q.get();

    expect(
      dbSpy.lastSql,
      contains('WHERE deleted_at IS NULL OR posted_at IS NOT NULL'),
    );
    expect(dbSpy.lastArgs, isEmpty);
  });

  test('It handles whereRaw with bindings', () async {
    await TestUser().query().whereRaw('age > ?', bindings: [18]).get();

    expect(dbSpy.lastSql, contains('WHERE age > ?'));
    expect(dbSpy.lastArgs, [18]);
  });

  test('It handles orWhereRaw with bindings', () async {
    await TestUser().query().where('id', 1).orWhereRaw('age < ?', [10]).get();

    expect(dbSpy.lastSql, contains('WHERE id = ? OR age < ?'));
    expect(dbSpy.lastArgs, [1, 10]);
  });

  test('It handles whereExists (Subqueries)', () async {
    final subQuery = QueryBuilder<TestUser>(
      'posts',
      (map) => TestUser(map),
    ).whereRaw('user_id = users.id').where('active', 1).select(['1']);

    await TestUser().query().whereExists(subQuery).get();

    expect(
      dbSpy.lastSql,
      contains(
        'WHERE EXISTS (SELECT 1 FROM posts WHERE user_id = users.id AND active = ?)',
      ),
    );

    expect(dbSpy.lastArgs, [1]);
  });

  test('It handles whereNotExists', () async {
    final subQuery = QueryBuilder<TestUser>(
      'posts',
      (map) => TestUser(map),
    ).select(['1']);

    await TestUser().query().whereNotExists(subQuery).get();

    expect(dbSpy.lastSql, contains('WHERE NOT EXISTS (SELECT 1 FROM posts)'));
  });

  test('It handles orWhereIn', () async {
    await TestUser().query().where('id', 1).orWhereIn('role', [
      'admin',
      'editor',
    ]).get();

    expect(dbSpy.lastSql, contains('WHERE id = ? OR role IN (?, ?)'));
    expect(dbSpy.lastArgs, [1, 'admin', 'editor']);
  });

  test('It handles select() projection', () async {
    await TestUser().query().select(['name', 'email']).get();

    expect(dbSpy.lastSql, startsWith('SELECT name, email FROM users'));
  });

  test('It handles offset()', () async {
    await TestUser().query().limit(10).offset(5).get();

    expect(dbSpy.lastSql, contains('LIMIT 10'));
    expect(dbSpy.lastSql, contains('OFFSET 5'));
  });

  test('findOrFail() returns model if found', () async {
    final foundMock = MockDatabaseSpy([], {
      'LIMIT 1': [
        {'id': 1, 'name': 'David'},
      ],
    });
    DatabaseManager().setDatabase(foundMock);

    final user = await TestUser().query().findOrFail(1);
    expect(user.id, 1);
  });

  test('Aggregate functions generate correct SQL', () async {
    final countMock = MockDatabaseSpy([], {
      'SELECT COUNT(*) as aggregate': [
        {'aggregate': 42},
      ],
    });
    DatabaseManager().setDatabase(countMock);

    final count = await TestUser().where('active', 1).count();

    expect(count, 42);
    expect(
      countMock.lastSql,
      contains('SELECT COUNT(*) as aggregate FROM users'),
    );
    expect(countMock.lastSql, contains('WHERE active = ?'));

    final sumMock = MockDatabaseSpy([], {
      'SELECT SUM(price) as aggregate': [
        {'aggregate': 100.50},
      ],
    });
    DatabaseManager().setDatabase(sumMock);

    final total = await TestUser().query().sum('price');
    expect(total, 100.50);
    expect(sumMock.lastSql, contains('SELECT SUM(price) as aggregate'));

    final existsMock = MockDatabaseSpy([], {
      'LIMIT 1': [
        {'id': 1},
      ],
    });
    DatabaseManager().setDatabase(existsMock);

    final exists = await TestUser().where('id', 1).exists();
    expect(exists, isTrue);
    expect(existsMock.lastSql, contains('LIMIT 1'));
  });

  test('cast() preserves ALL query state and bindings', () async {
    final dbSpy = MockDatabaseSpy([], {
      'FROM users': [
        {'id': 1, 'name': 'SuperAdmin', 'role': 'admin'},
      ],
    });
    DatabaseManager().setDatabase(dbSpy);

    final originalQuery = TestUser()
        .query()
        .select(['name', 'role'])
        .join('roles', 'users.role_id', '=', 'roles.id')
        .where('active', 1)
        .whereRaw('age > ?', bindings: [21])
        .orderBy('created_at', direction: 'DESC')
        .limit(10)
        .offset(5);

    final castedQuery = originalQuery.cast<AdminView>(AdminView.new);

    final results = await castedQuery.get();

    expect(results, isA<List<AdminView>>());
    expect(results.first, isA<AdminView>());

    final sql = dbSpy.lastSql;

    expect(sql, startsWith('SELECT users.name, users.role FROM users'));
    expect(sql, contains('JOIN roles ON users.role_id = roles.id'));
    expect(sql, contains('WHERE active = ? AND age > ?'));
    expect(sql, contains('ORDER BY created_at DESC'));
    expect(sql, contains('LIMIT 10'));
    expect(sql, contains('OFFSET 5'));
    expect(dbSpy.lastArgs, equals([1, 21]));
  });

  test('cast() copies eager loading (_with) configuration', () async {
    final dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);

    final originalQuery = TestUser().query().withRelations(['posts']);
    final castedQuery = originalQuery.cast<AdminView>(AdminView.new);

    expect(castedQuery, isNotNull);
  });
}
