import 'package:flutter_test/flutter_test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

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
  test('BelongsToMany loads related models via pivot', () async {
    final mockDb = MockDatabaseSpy([], {
      'FROM role_user': [
        {'user_id': 1, 'role_id': 10},
        {'user_id': 1, 'role_id': 11},
      ],
      'FROM roles': [
        {'id': 10, 'name': 'Admin'},
        {'id': 11, 'name': 'Editor'},
      ],
    });
    DatabaseManager().setDatabase(mockDb);

    final users = [
      User({'id': 1}),
    ];

    await users.first.roles().match(users, 'roles');

    final roles = users.first.relations['roles'] as List;

    expect(roles, hasLength(2));
    expect(roles.first, isA<Role>());

    final adminRole = roles.firstWhere((r) => r.id == 10);
    expect(adminRole.attributes['name'], 'Admin');
  });
}
