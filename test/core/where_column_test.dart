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

  test('It handles whereColumn', () async {
    await TestUser().query().whereColumn('first_name', 'last_name').get();

    expect(dbSpy.lastSql, contains('WHERE "first_name" = "last_name"'));
    expect(dbSpy.lastArgs, isEmpty);
  });

  test('It handles whereColumn with operator', () async {
    await TestUser().query().whereColumn('updated_at', 'created_at', '>').get();

    expect(dbSpy.lastSql, contains('WHERE "updated_at" > "created_at"'));
  });

  test('It handles orWhereColumn', () async {
    await TestUser()
        .query()
        .where('id', 1)
        .orWhereColumn('first_name', 'last_name')
        .get();

    expect(
      dbSpy.lastSql,
      contains('WHERE "id" = ? OR "first_name" = "last_name"'),
    );
    expect(dbSpy.lastArgs, [1]);
  });

  test('whereColumn rejects invalid operator', () async {
    expect(
      () => TestUser().query().whereColumn('a', 'b', 'INVALID'),
      throwsA(isA<InvalidQueryException>()),
    );
  });

  test('whereColumn requires two columns', () async {
    expect(
      () => TestUser().query().whereColumn('a'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('whereColumn validates identifiers', () async {
    expect(
      () => TestUser().query().whereColumn('a; drop table users', 'b'),
      throwsA(isA<InvalidQueryException>()),
    );
    expect(
      () => TestUser().query().whereColumn('a', 'b; drop table users'),
      throwsA(isA<InvalidQueryException>()),
    );
  });

  test('whereColumn supports dotted identifiers', () async {
    await TestUser()
        .query()
        .whereColumn('users.first_name', 'contacts.first_name')
        .get();

    expect(
      dbSpy.lastSql,
      contains('WHERE "users"."first_name" = "contacts"."first_name"'),
    );
  });

  test('whereColumn supports arrays', () async {
    await TestUser().query().whereColumn([
      ['first_name', 'last_name'],
      ['updated_at', '>', 'created_at'],
    ]).get();

    expect(
      dbSpy.lastSql,
      contains(
        'WHERE "first_name" = "last_name" AND "updated_at" > "created_at"',
      ),
    );
  });
}
