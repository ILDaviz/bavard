import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  BelongsToMany<Role> roles() => belongsToMany(
    Role.new,
    'role_user',
    foreignPivotKey: 'user_id',
    relatedPivotKey: 'role_id',
  );
}

class Role extends Model {
  @override
  String get table => 'roles';

  Role([super.attributes]);

  @override
  Role fromMap(Map<String, dynamic> map) => Role(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('BelongsToMany Extended', () {
    test('returns empty list when no pivot entries', () async {
      final emptyMock = MockDatabaseSpy([], {
        'FROM role_user': [],
      });
      DatabaseManager().setDatabase(emptyMock);

      final users = [User({'id': 1})];
      await users.first.roles().match(users, 'roles');

      // Quando non ci sono pivot entries, la relazione potrebbe non essere settata
      // Usa l'accessor sicuro getRelationList
      final roles = users.first.getRelationList<Role>('roles');
      expect(roles, isEmpty);
    });

    test('handles duplicate pivot entries', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM role_user': [
          {'user_id': 1, 'role_id': 10},
          {'user_id': 1, 'role_id': 10}, // Duplicate
          {'user_id': 1, 'role_id': 11},
        ],
        'FROM roles': [
          {'id': 10, 'name': 'Admin'},
          {'id': 11, 'name': 'Editor'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = [User({'id': 1})];
      await users.first.roles().match(users, 'roles');

      // Should have 3 entries (including duplicate)
      final roles = users.first.relations['roles'] as List;
      expect(roles.length, 3);
    });

    test('eager load with empty pivot table', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM role_user': [],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = [
        User({'id': 1}),
        User({'id': 2}),
      ];

      await users.first.roles().match(users, 'roles');

      expect(users[0].getRelationList<Role>('roles'), isEmpty);
      expect(users[1].getRelationList<Role>('roles'), isEmpty);
    });

    test('custom pivot table name', () async {
      final user = User({'id': 1});
      await user.roles().get();

      expect(dbSpy.lastSql, contains('JOIN role_user ON'));
    });

    test('custom pivot keys', () async {
      final user = User({'id': 1});
      await user.roles().get();

      expect(dbSpy.lastSql, contains('role_user.user_id = ?'));
    });
  });
}