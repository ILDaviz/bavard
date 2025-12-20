import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasOne<Profile> profile() {
    return hasOne(Profile.new);
  }
}

class Profile extends Model {
  @override
  String get table => 'profiles';
  Profile([super.attributes]);
  @override
  Profile fromMap(Map<String, dynamic> map) => Profile(map);
}

void main() {
  group('HasOne Relation', () {
    test('It generates SQL with LIMIT 1 for lazy loading', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      final user = User({'id': 1});

      await user.profile().getResult();

      expect(dbSpy.lastSql, contains('FROM profiles'));
      expect(dbSpy.lastSql, contains('WHERE user_id = ?'));
      expect(dbSpy.lastSql, contains('LIMIT 1'));
      expect(dbSpy.lastArgs, [1]);
    });

    test('It eager loads relation and unwraps list', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM profiles': [
          {'id': 100, 'user_id': 1, 'bio': 'Bio User 1'},
          {'id': 101, 'user_id': 2, 'bio': 'Bio User 2'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = [
        User({'id': 1}),
        User({'id': 2}),
      ];

      await users.first.profile().match(users, 'profile');

      final profile1 = users[0].relations['profile'];
      final profile2 = users[1].relations['profile'];

      expect(profile1, isA<Profile>());
      expect((profile1 as Profile).attributes['bio'], 'Bio User 1');

      expect(profile2, isA<Profile>());
      expect((profile2 as Profile).attributes['bio'], 'Bio User 2');
    });
  });
}
