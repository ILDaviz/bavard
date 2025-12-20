import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/mock_database.dart';

class Country extends Model {
  @override
  String get table => 'countries';
  Country([super.attributes]);
  @override
  Country fromMap(Map<String, dynamic> map) => Country(map);

  HasManyThrough<Post, User> posts() {
    return hasManyThrough(Post.new, User.new);
  }
}

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
}

void main() {
  group('HasManyThrough Relation', () {
    test('It constructs SQL with correct JOINS for lazy loading', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      final country = Country({'id': 1, 'name': 'Italy'});

      await country.posts().get();

      expect(dbSpy.lastSql, contains('SELECT posts.* FROM posts'));
      expect(dbSpy.lastSql, contains('JOIN users ON users.id = posts.user_id'));
      expect(dbSpy.lastSql, contains('WHERE users.country_id = ?'));
      expect(dbSpy.lastArgs, [1]);
    });

    test('It eager loads distant relations correctly', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 10, 'country_id': 1},
          {'id': 20, 'country_id': 2},
        ],
        'FROM posts': [
          {'id': 100, 'title': 'Pasta Recipe', 'user_id': 10},
          {'id': 200, 'title': 'Baguette Recipe', 'user_id': 20},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final countries = [
        Country({'id': 1, 'name': 'Italy'}),
        Country({'id': 2, 'name': 'France'}),
      ];

      await countries.first.posts().match(countries, 'posts');

      final italyPosts = countries[0].relations['posts'] as List;
      final francePosts = countries[1].relations['posts'] as List;

      expect(italyPosts, hasLength(1));
      expect(italyPosts.first, isA<Post>());
      expect((italyPosts.first as Post).attributes['title'], 'Pasta Recipe');

      expect(francePosts, hasLength(1));
      expect(
        (francePosts.first as Post).attributes['title'],
        'Baguette Recipe',
      );
    });
  });
}
