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
  final name = TextColumn('name');
  final age = IntColumn('age');
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  test('update() works with Column objects', () async {
    await TestUser().query().where('id', 1).update({
      TestUser.schema.name: 'David',
      TestUser.schema.age: 30,
    });

    expect(dbSpy.lastSql, contains('UPDATE "users" SET "name" = ?, "age" = ?'));
    expect(dbSpy.lastArgs, containsAll(['David', 30, 1]));
  });

  test('insert() works with Column objects', () async {
    await TestUser().query().insert({
      TestUser.schema.name: 'Alice',
      TestUser.schema.age: 25,
    });

    expect(
      dbSpy.lastSql,
      contains('INSERT INTO "users" ("name", "age") VALUES (?, ?)'),
    );
    expect(dbSpy.lastArgs, containsAll(['Alice', 25]));
  });
}
