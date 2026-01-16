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

  test('insertAll() returns true immediately if list is empty', () async {
    final result = await TestUser().query().insertAll([]);
    expect(result, isTrue);
    expect(dbSpy.lastSql, isEmpty);
  });

  test('insertAll() generates correct SQL for single item', () async {
    await TestUser().query().insertAll([
      {'name': 'Alice', 'age': 30},
    ]);

    expect(dbSpy.lastSql, 'INSERT INTO "users" ("age", "name") VALUES (?, ?)');
    expect(dbSpy.lastArgs, [30, 'Alice']);
  });

  test('insertAll() generates correct SQL for multiple items', () async {
    await TestUser().query().insertAll([
      {'name': 'Alice', 'age': 30},
      {'name': 'Bob', 'age': 25},
    ]);

    expect(
      dbSpy.lastSql,
      'INSERT INTO "users" ("age", "name") VALUES (?, ?), (?, ?)',
    );
    expect(dbSpy.lastArgs, [30, 'Alice', 25, 'Bob']);
  });

  test(
    'insertAll() handles items with mixed key order but same keys',
    () async {
      await TestUser().query().insertAll([
        {'name': 'Alice', 'age': 30},
        {'age': 25, 'name': 'Bob'},
      ]);

      expect(
        dbSpy.lastSql,
        'INSERT INTO "users" ("age", "name") VALUES (?, ?), (?, ?)',
      );
      expect(dbSpy.lastArgs, [30, 'Alice', 25, 'Bob']);
    },
  );
}
