import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/testing.dart';

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  BelongsToMany<Role> roles() {
    return belongsToMany(
      Role.new,
      'user_roles',
      foreignPivotKey: 'user_id',
      relatedPivotKey: 'role_id',
    );
  }
}

class Role extends Model {
  @override
  String get table => 'roles';
  Role([super.attributes]);
  @override
  Role fromMap(Map<String, dynamic> map) => Role(map);
}

class UserRoleSchema {
  final isActive = BoolColumn('is_active');
  final grantedAt = DateTimeColumn('granted_at');
}

void main() {
  late MockDatabaseSpy dbSpy;
  final schema = UserRoleSchema();

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  test('wherePivot works with Column object', () async {
    await User().roles().wherePivot(schema.isActive, true).get();

    expect(dbSpy.lastSql, contains('"user_roles"."is_active" = ?'));
  });

  test('wherePivotIn works with Column object', () async {
    await User().roles().wherePivotIn(schema.isActive, [true, false]).get();

    expect(dbSpy.lastSql, contains('"user_roles"."is_active" IN (?, ?)'));
  });

  test('wherePivotNull works with Column object', () async {
    await User().roles().wherePivotNull(schema.grantedAt).get();

    expect(dbSpy.lastSql, contains('"user_roles"."granted_at" IS NULL'));
  });

  test('withPivot works with Column object', () async {
    await User().roles().withPivot([schema.isActive]).get();

    expect(
      dbSpy.lastSql,
      contains('"user_roles"."is_active" AS "pivot_is_active"'),
    );
  });
}
