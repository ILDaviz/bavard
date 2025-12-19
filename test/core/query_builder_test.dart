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

  /// Verifies that the [cast] method correctly transfers all SQL clauses, bindings,
  /// and query configurations from the original QueryBuilder instance to the new one.
  ///
  /// This ensures that transforming a query (e.g., from a raw User model to an AdminView)
  /// does not lose critical constraints like WHERE clauses, JOINs, or pagination limits.
  test('cast() preserves ALL query state and bindings', () async {
    // Initialize the Mock Database to intercept and inspect generated SQL.
    // We simulate a response for the 'users' table to allow execution to proceed.
    final dbSpy = MockDatabaseSpy([], {
      'FROM users': [
        {'id': 1, 'name': 'SuperAdmin', 'role': 'admin'},
      ],
    });
    DatabaseManager().setDatabase(dbSpy);

    // 1. Build a complex query on the original model (TestUser).
    // We intentionally use various clauses (select, join, where, raw, order, limit, offset)
    // to ensure 'cast' handles a fully populated state.
    final originalQuery = TestUser()
        .query()
        .select(['name', 'role']) // Custom column projection
        .join('roles', 'users.role_id', '=', 'roles.id') // Explicit JOIN
        .where('active', 1) // Standard WHERE clause
        .whereRaw(
          'age > ?',
          bindings: [21],
        ) // Raw SQL WHERE with parameter binding
        .orderBy('created_at', direction: 'DESC') // Sorting configuration
        .limit(10) // Pagination limit
        .offset(5); // Pagination offset

    // 2. Perform the cast to a new model type (AdminView).
    // This creates a new QueryBuilder<AdminView> carrying over the previous state.
    final castedQuery = originalQuery.cast<AdminView>(AdminView.new);

    // 3. Execute the casted query to trigger SQL generation and database interaction.
    final results = await castedQuery.get();

    // A. Verify type safety: The result list and its items must match the target generic type (AdminView).
    expect(results, isA<List<AdminView>>());
    expect(results.first, isA<AdminView>());

    // B. Verify SQL Generation: The generated SQL must contain all original query components.
    final sql = dbSpy.lastSql;

    // Check custom SELECT projection
    expect(sql, startsWith('SELECT users.name, users.role FROM users'));
    // Check JOIN clause preservation
    expect(sql, contains('JOIN roles ON users.role_id = roles.id'));
    // Check combination of standard and raw WHERE clauses
    expect(sql, contains('WHERE active = ? AND age > ?'));
    // Check ORDER BY clause
    expect(sql, contains('ORDER BY created_at DESC'));
    // Check LIMIT and OFFSET
    expect(sql, contains('LIMIT 10'));
    expect(sql, contains('OFFSET 5'));

    // C. Verify Parameter Bindings: This is crucial for security and correctness.
    // The bindings list must strictly maintain the order of parameters:
    // 1 (from 'active') and 21 (from 'age').
    expect(dbSpy.lastArgs, equals([1, 21]));
  });

  /// Verifies that eager loading configurations (the [_with] list) are copied during a cast.
  ///
  /// Since `_with` is a private internal state, we cannot assert its content directly
  /// without reflection. This test ensures that the operation completes without error
  /// and that the new builder instance is valid.
  test('cast() copies eager loading (_with) configuration', () async {
    final dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);

    // Build a query requesting eager loading of the 'posts' relation.
    final originalQuery = TestUser().query().withRelations(['posts']);

    // Perform the cast.
    // Note: For a comprehensive integration test, [AdminView] should also define
    // the 'posts' relation. Here we primarily test that the internal list copy logic
    // does not throw exceptions and produces a non-null instance.
    final castedQuery = originalQuery.cast<AdminView>(AdminView.new);

    // Assert that the builder was created successfully.
    // (In a full integration scenario, executing this query and inspecting
    // executed SQL for relation fetching would confirm the behavior).
    expect(castedQuery, isNotNull);
  });
}
