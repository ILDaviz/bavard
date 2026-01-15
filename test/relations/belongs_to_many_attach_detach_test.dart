import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class Role extends Model {
  @override
  String get table => 'roles';
  Role([super.attributes]);
  @override
  Role fromMap(Map<String, dynamic> map) => Role(map);
}

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  BelongsToMany<Role> roles() {
    return belongsToMany(
      Role.new,
      'role_user',
      foreignPivotKey: 'user_id',
      relatedPivotKey: 'role_id',
    );
  }
}

void main() {
  group('BelongsToMany Attach/Detach', () {
    late MockDatabaseSpy mockDb;
    late User user;
    late Role role;

    setUp(() {
      mockDb = MockDatabaseSpy();
      DatabaseManager().setDatabase(mockDb);
      user = User({'id': 1});
      role = Role({'id': 10});
    });

    test('attach() inserts into pivot table', () async {
      await user.roles().attach(role);

      expect(mockDb.lastSql, contains('INSERT INTO "role_user"'));
      expect(mockDb.lastSql, contains('"user_id"'));
      expect(mockDb.lastSql, contains('"role_id"'));
      expect(mockDb.lastArgs, contains(1));
      expect(mockDb.lastArgs, contains(10));
    });

    test('attach() with extra attributes', () async {
      await user.roles().attach(role, {'active': true});

      expect(mockDb.lastSql, contains('INSERT INTO "role_user"'));
      expect(mockDb.lastSql, contains('"active"'));
      expect(mockDb.lastArgs, contains(1));
      expect(mockDb.lastArgs, contains(10));
      expect(mockDb.lastArgs, contains(true));
    });

    test('attach() with ID directly', () async {
      await user.roles().attach(10);

      expect(mockDb.lastArgs, contains(10));
    });

    test('detach() deletes from pivot table (single ID)', () async {
      await user.roles().detach(10);

      expect(mockDb.lastSql, startsWith('DELETE FROM "role_user"'));
      expect(mockDb.lastSql, contains('"user_id" = ?'));
      expect(mockDb.lastSql, contains('"role_id" IN (?)'));
      expect(mockDb.lastArgs, contains(1));
      expect(mockDb.lastArgs, contains(10));
    });

    test('detach() deletes multiple IDs', () async {
      await user.roles().detach([10, 11]);

      expect(mockDb.lastSql, startsWith('DELETE FROM "role_user"'));
      expect(mockDb.lastSql, contains('"role_id" IN (?, ?)'));
      expect(mockDb.lastArgs, contains(10));
      expect(mockDb.lastArgs, contains(11));
    });

    test('detach() all deletes all related to parent', () async {
      await user.roles().detach();

      expect(mockDb.lastSql, startsWith('DELETE FROM "role_user"'));
      expect(mockDb.lastSql, contains('"user_id" = ?'));
      expect(mockDb.lastSql, isNot(contains('"role_id"')));
      expect(mockDb.lastArgs, [1]);
    });
  });
}
