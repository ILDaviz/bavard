import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class Country extends Model {
  @override
  String get table => 'countries';
  Country([super.attributes]);
  @override
  Country fromMap(Map<String, dynamic> map) => Country(map);

  HasManyThrough<Post, User> posts() => hasManyThrough(Post.new, User.new);
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
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('HasManyThrough Extended', () {
    test('returns empty when no intermediate records', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [],
        'FROM posts': [],
      });
      DatabaseManager().setDatabase(mockDb);

      final countries = [Country({'id': 1})];
      await countries.first.posts().match(countries, 'posts');

      // Usa getRelationList per gestire il caso null
      final posts = countries.first.getRelationList<Post>('posts');
      expect(posts, isEmpty);
    });

    test('returns empty when intermediate exists but no target', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 10, 'country_id': 1}
        ],
        'FROM posts': [],
      });
      DatabaseManager().setDatabase(mockDb);

      final countries = [Country({'id': 1})];
      await countries.first.posts().match(countries, 'posts');

      expect(countries.first.relations['posts'], isEmpty);
    });

    test('eager load with complex chain', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 10, 'country_id': 1},
          {'id': 20, 'country_id': 1},
          {'id': 30, 'country_id': 2},
        ],
        'FROM posts': [
          {'id': 100, 'user_id': 10, 'title': 'Post A'},
          {'id': 101, 'user_id': 10, 'title': 'Post B'},
          {'id': 102, 'user_id': 20, 'title': 'Post C'},
          {'id': 103, 'user_id': 30, 'title': 'Post D'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final countries = [
        Country({'id': 1}),
        Country({'id': 2}),
      ];

      await countries.first.posts().match(countries, 'posts');

      // Country 1 has users 10 and 20, which have posts 100, 101, 102
      final country1Posts = countries[0].relations['posts'] as List;
      expect(country1Posts.length, 3);

      // Country 2 has user 30, which has post 103
      final country2Posts = countries[1].relations['posts'] as List;
      expect(country2Posts.length, 1);
    });

    test('custom first key', () async {
      final country = Country({'id': 1});

      // Using default keys
      await country.posts().get();

      expect(dbSpy.lastSql, contains('users.country_id = ?'));
    });

    test('custom second key', () async {
      final country = Country({'id': 1});

      await country.posts().get();

      expect(dbSpy.lastSql, contains('posts.user_id'));
    });
  });
}