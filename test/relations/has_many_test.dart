import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class Post extends Model {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);
}

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasMany<Post> posts() => hasMany(Post.new);

  @override
  Relation? getRelation(String name) {
    if (name == 'posts') return posts();
    return super.getRelation(name);
  }
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([
      {'id': 10, 'user_id': 1, 'title': 'Post A'},
      {'id': 11, 'user_id': 1, 'title': 'Post B'},
      {'id': 12, 'user_id': 2, 'title': 'Post C'},
    ]);
    DatabaseManager().setDatabase(dbSpy);
  });

  group('HasMany Relation', () {
    test('It constructs the correct SQL constraints', () async {
      final user = User({'id': 1});
      await user.posts().get();

      expect(dbSpy.lastSql, contains('SELECT posts.* FROM posts'));
      expect(dbSpy.lastSql, contains('WHERE user_id = ?'));
      expect(dbSpy.lastArgs, [1]);
    });

    test('It eager loads children correctly', () async {
      final users = [
        User({'id': 1}),
        User({'id': 2}),
      ];

      final relation = users.first.posts();

      await relation.match(users, 'posts');

      expect(dbSpy.lastSql, contains('WHERE user_id IN (?, ?)'));

      expect(users.first.relations['posts'], hasLength(2));
      expect(users.last.relations['posts'], hasLength(1));

      final firstPost = (users.first.relations['posts'] as List).first;
      expect(firstPost, isA<Post>());
      expect(firstPost.attributes['title'], 'Post A');
    });
  });
}
