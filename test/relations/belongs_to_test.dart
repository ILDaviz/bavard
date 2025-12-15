import 'package:flutter_test/flutter_test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

class Post extends Model {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  BelongsTo<User> author() {
    return belongsTo(User.new, foreignKey: 'user_id', ownerKey: 'id');
  }
}

void main() {
  group('BelongsTo Relation', () {
    test('It generates correct SQL for single parent', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      final post = Post({'id': 1, 'title': 'Hello World', 'user_id': 99});

      await post.author().get();

      expect(dbSpy.lastSql, contains('FROM users'));
      expect(dbSpy.lastSql, contains('WHERE id = ?'));
      expect(dbSpy.lastArgs, [99]);
    });

    test('It eager loads parents correctly', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 10, 'name': 'David'},
          {'id': 11, 'name': 'Romolo'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1, 'user_id': 10}),
        Post({'id': 2, 'user_id': 11}),
        Post({'id': 3, 'user_id': 10}),
      ];

      await posts.first.author().match(posts, 'author');

      final author1 = posts[0].relations['author'] as User?;
      final author2 = posts[1].relations['author'] as User?;
      final author3 = posts[2].relations['author'] as User?;

      expect(author1, isNotNull);
      expect(author1!.id, 10);
      expect(author1.attributes['name'], 'David');

      expect(author2, isNotNull);
      expect(author2!.id, 11);

      expect(author3, isNotNull);
      expect(author3!.id, 10);
    });
  });
}
