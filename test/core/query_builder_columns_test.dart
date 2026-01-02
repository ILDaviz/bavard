import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/testing.dart';

class TestUser extends Model {
  @override
  String get table => 'users';
  TestUser([super.attributes]);
  @override
  TestUser fromMap(Map<String, dynamic> map) => TestUser(map);
  
  static final schema = TestUserSchema();
}

class TestUserSchema {
  final id = IntColumn('id');
  final name = TextColumn('name');
  final votes = IntColumn('votes');
  final roleId = IntColumn('role_id');
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  test('count() works with Column', () async {
    final countMock = MockDatabaseSpy([], {
      'SELECT COUNT("users"."votes") as aggregate': [{'aggregate': 10}],
    });
    DatabaseManager().setDatabase(countMock);

    await TestUser().query().count(TestUser.schema.votes);
    expect(countMock.lastSql, contains('COUNT("users"."votes")'));
  });

  test('sum() works with Column', () async {
    final sumMock = MockDatabaseSpy([], {
      'SELECT SUM("users"."votes") as aggregate': [{'aggregate': 100}],
    });
    DatabaseManager().setDatabase(sumMock);

    await TestUser().query().sum(TestUser.schema.votes);
    expect(sumMock.lastSql, contains('SUM("users"."votes")'));
  });

  test('join() works with Column', () async {
    await TestUser().query().join(
      'roles', 
      TestUser.schema.roleId, 
      '=', 
      'roles.id',
    ).get();

    expect(dbSpy.lastSql, contains('JOIN "roles" ON "users"."role_id" = "roles"."id"'));
  });

  test('orderBy() works with Column', () async {
    await TestUser().query().orderBy(TestUser.schema.name).get();
    expect(dbSpy.lastSql, contains('ORDER BY "users"."name" ASC'));
  });

  test('groupBy() works with Column', () async {
    await TestUser().query().groupBy([TestUser.schema.roleId]).get();
    expect(dbSpy.lastSql, contains('GROUP BY "users"."role_id"'));
  });

  test('select() works with Column', () async {
    await TestUser().query().select([
      TestUser.schema.id,
      TestUser.schema.name,
      'email',
    ]).get();

    expect(
      dbSpy.lastSql, 
      startsWith('SELECT "users"."id", "users"."name", "email" FROM "users"')
    );
  });
}
