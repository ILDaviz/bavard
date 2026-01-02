import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';
import 'package:bavard/schema.dart';

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
    expect(dbSpy.lastSql, 'SELECT "users".* FROM "users"');
  });

  test('It generates SELECT DISTINCT', () async {
    await TestUser().query().distinct().get();
    expect(dbSpy.lastSql, startsWith('SELECT DISTINCT "users".* FROM "users"'));
  });

  test('It generates WHERE clauses with bindings', () async {
    await TestUser().where('email', 'david@test.com').get();

    expect(dbSpy.lastSql, contains('WHERE "email" = ?'));
    expect(dbSpy.lastArgs, ['david@test.com']);
  });

  test('It chains multiple WHERE clauses', () async {
    await TestUser().query().where('role', 'admin').where('age', 18, '>').get();

    final q = TestUser().where('role', 'admin').where('age', 18, '>');
    await q.get();

    expect(dbSpy.lastSql, contains('WHERE "role" = ? AND "age" > ?'));
    expect(dbSpy.lastArgs, ['admin', 18]);
  });

  test('It generates ORDER BY and LIMIT', () async {
    await TestUser()
        .query()
        .orderBy('created_at', direction: 'DESC')
        .limit(5)
        .get();

    expect(dbSpy.lastSql, contains('ORDER BY "created_at" DESC'));
    expect(dbSpy.lastSql, contains('LIMIT 5'));
  });

  test('It handles whereBetween and whereNotBetween', () async {
    await TestUser().query().whereBetween('age', [18, 30]).get();
    expect(dbSpy.lastSql, contains('WHERE "age" BETWEEN ? AND ?'));
    expect(dbSpy.lastArgs, [18, 30]);

    await TestUser().query().whereNotBetween('age', [1, 10]).get();
    expect(dbSpy.lastSql, contains('WHERE "age" NOT BETWEEN ? AND ?'));
    expect(dbSpy.lastArgs, [1, 10]);
  });

  test('whereBetween works with Column object', () async {
    final col = IntColumn('votes');
    await TestUser().query().whereBetween(col, [100, 200]).get();
    expect(dbSpy.lastSql, contains('WHERE "users"."votes" BETWEEN ? AND ?'));
  });

  test('It handles WHERE IN', () async {
    await TestUser().query().whereIn('id', [1, 2, 3]).get();

    expect(dbSpy.lastSql, contains('"id" IN (?, ?, ?)'));
    expect(dbSpy.lastArgs, [1, 2, 3]);
  });

  test('orderBy accepts dotted identifiers (table.column)', () async {
    await TestUser()
        .query()
        .orderBy('users.created_at', direction: 'DESC')
        .get();

    expect(dbSpy.lastSql, contains('ORDER BY "users"."created_at" DESC'));
  });

  test('orderBy accepts dotted identifiers (table.column)', () async {
    await TestUser()
        .query()
        .orderBy('users.created_at', direction: 'DESC')
        .get();

    expect(dbSpy.lastSql, contains('ORDER BY "users"."created_at" DESC'));
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

    expect(dbSpy.lastSql, contains('WHERE "id" = ? OR "email" = ?'));
    expect(dbSpy.lastArgs, [1, 'admin@test.com']);
  });

  test('It handles whereNull and whereNotNull with dynamic columns (Strings or Column objects)', () async {
    final col = TextColumn('deleted_at');
    final q = TestUser()
        .query()
        .whereNull(col)
        .orWhereNotNull('posted_at');
    await q.get();

    expect(
      dbSpy.lastSql,
      contains('WHERE "users"."deleted_at" IS NULL OR "posted_at" IS NOT NULL'),
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

    expect(dbSpy.lastSql, contains('WHERE "id" = ? OR age < ?'));
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
        'WHERE EXISTS (SELECT "1" FROM "posts" WHERE user_id = users.id AND "active" = ?)',
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

    expect(
      dbSpy.lastSql,
      contains('WHERE NOT EXISTS (SELECT "1" FROM "posts")'),
    );
  });

  test('It handles orWhereIn', () async {
    await TestUser().query().where('id', 1).orWhereIn('role', [
      'admin',
      'editor',
    ]).get();

    expect(dbSpy.lastSql, contains('WHERE "id" = ? OR "role" IN (?, ?)'));
    expect(dbSpy.lastArgs, [1, 'admin', 'editor']);
  });

  test('It handles select() projection', () async {
    await TestUser().query().select(['name', 'email']).get();

    expect(dbSpy.lastSql, startsWith('SELECT "name", "email" FROM "users"'));
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
      contains('SELECT COUNT(*) as aggregate FROM "users"'),
    );
    expect(countMock.lastSql, contains('WHERE "active" = ?'));

    final sumMock = MockDatabaseSpy([], {
      'SELECT SUM("price") as aggregate': [
        {'aggregate': 100.50},
      ],
    });
    DatabaseManager().setDatabase(sumMock);

    final total = await TestUser().query().sum('price');
    expect(total, 100.50);
    expect(sumMock.lastSql, contains('SELECT SUM("price") as aggregate'));

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
      'FROM "users"': [
        {'id': 1, 'name': 'SuperAdmin', 'role': 'admin'},
      ],
    });
    DatabaseManager().setDatabase(dbSpy);

    final originalQuery = TestUser()
        .query()
        .select(['name', 'role'])
        .distinct()
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

    expect(
      sql,
      startsWith('SELECT DISTINCT "users"."name", "users"."role" FROM "users"'),
    );
    expect(sql, contains('JOIN "roles" ON "users"."role_id" = "roles"."id"'));
    expect(sql, contains('WHERE "active" = ? AND age > ?'));
    expect(sql, contains('ORDER BY "created_at" DESC'));
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

  test('It streams results via cursor()', () async {
    dbSpy.setMockData({
      'OFFSET 0': [
        {'id': 1, 'name': 'User 1'},
        {'id': 2, 'name': 'User 2'},
      ],
      'OFFSET 2': [
        {'id': 3, 'name': 'User 3'},
      ],
    });

    final stream = TestUser().query().where('active', 1).cursor(batchSize: 2);
    final results = await stream.toList();

    expect(results.length, 3);
    expect(results[0].getAttribute('name'), 'User 1');
    expect(results[1].getAttribute('name'), 'User 2');
    expect(results[2].getAttribute('name'), 'User 3');

    expect(dbSpy.lastSql, contains('WHERE "active" = ?'));
  });

  test('It generates UNION queries', () async {
    final query1 = TestUser().query().where('id', 1);
    final query2 = TestUser().query().where('id', 2);

    await query1.union(query2).get();

    expect(
      dbSpy.lastSql,
      'SELECT "users".* FROM "users" WHERE "id" = ? UNION SELECT "users".* FROM "users" WHERE "id" = ?',
    );
    expect(dbSpy.lastArgs, [1, 2]);
  });

  test('It generates UNION ALL queries with ORDER BY', () async {
    final query1 = TestUser().query().where('active', 1);
    final query2 = TestUser().query().where('active', 0);

    await query1.unionAll(query2).orderBy('created_at', direction: 'DESC').get();

    expect(
      dbSpy.lastSql,
      'SELECT "users".* FROM "users" WHERE "active" = ? UNION ALL SELECT "users".* FROM "users" WHERE "active" = ? ORDER BY "created_at" DESC',
    );
    expect(dbSpy.lastArgs, [1, 0]);
  });

  test('It calculates COUNT with UNION', () async {
     final query1 = TestUser().query().where('id', 1);
    final query2 = TestUser().query().where('id', 2);

    dbSpy.setMockData({
      'SELECT COUNT(*) as aggregate': [{'aggregate': 10}],
    });

    final count = await query1.union(query2).count();

    expect(count, 10);
    expect(dbSpy.lastSql, contains('SELECT COUNT(*) as aggregate FROM ('));
    expect(dbSpy.lastSql, contains('UNION'));
    expect(dbSpy.lastSql, endsWith(') as temp_table'));
  });
}
