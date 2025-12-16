import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class User extends Model {
  @override
  String get table => 'users';

  @override
  String get primaryKey => 'id';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasOne<Profile> profile() => hasOne(Profile.new);
  HasMany<Post> posts() => hasMany(Post.new);

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'profile':
        return profile();
      case 'posts':
        return posts();
      default:
        return null;
    }
  }
}

class Profile extends Model {
  @override
  String get table => 'profiles';

  Profile([super.attributes]);

  @override
  Profile fromMap(Map<String, dynamic> map) => Profile(map);

  BelongsTo<User> user() =>
      belongsTo(User.new, foreignKey: 'user_id', ownerKey: 'id');
}

class Post extends Model {
  @override
  String get table => 'posts';

  Post([super.attributes]);

  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  BelongsTo<User> author() =>
      belongsTo(User.new, foreignKey: 'user_id', ownerKey: 'id');
}

class CustomPkUser extends Model {
  @override
  String get table => 'users';

  @override
  String get primaryKey => 'uuid';

  CustomPkUser([super.attributes]);

  @override
  CustomPkUser fromMap(Map<String, dynamic> map) => CustomPkUser(map);

  HasMany<CustomPkPost> posts() =>
      hasMany(CustomPkPost.new, foreignKey: 'author_uuid', localKey: 'uuid');
}

class CustomPkPost extends Model {
  @override
  String get table => 'posts';

  CustomPkPost([super.attributes]);

  @override
  CustomPkPost fromMap(Map<String, dynamic> map) => CustomPkPost(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Relations - General', () {
    test('getRelation returns null for undefined relation', () {
      final user = User({'id': 1});
      expect(user.getRelation('nonexistent'), isNull);
    });

    test('relation query can be further constrained', () async {
      final user = User({'id': 1});

      await user.posts().where('published', true).orderBy('created_at').get();

      expect(dbSpy.lastSql, contains('user_id = ?'));
      expect(dbSpy.lastSql, contains('published = ?'));
      expect(dbSpy.lastSql, contains('ORDER BY created_at'));
    });

    test('relation with custom primary key', () async {
      final user = CustomPkUser({'uuid': 'abc-123'});

      await user.posts().get();

      expect(dbSpy.lastSql, contains('author_uuid = ?'));
      expect(dbSpy.lastArgs, contains('abc-123'));
    });
  });

  // ===========================================================================
  // HAS ONE
  // ===========================================================================
  group('HasOne Extended', () {
    test('returns null when no related model exists', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final user = User({'id': 1});
      final profile = await user.profile().getResult();

      expect(profile, isNull);
    });

    test('getResult() applies LIMIT 1', () async {
      final user = User({'id': 1});
      await user.profile().getResult();

      expect(dbSpy.lastSql, contains('LIMIT 1'));
    });

    test('eager load with empty parent list', () async {
      final users = <User>[];

      if (users.isNotEmpty) {
        await users.first.profile().match(users, 'profile');
      }

      expect(dbSpy.history, isEmpty);
    });

    test('eager load when some parents have no related', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM profiles': [
          {'id': 100, 'user_id': 1, 'bio': 'Bio 1'},
          // No profile for user 2
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = [
        User({'id': 1}),
        User({'id': 2}),
      ];

      await users.first.profile().match(users, 'profile');

      expect(users[0].relations['profile'], isA<Profile>());
      expect(users[1].relations['profile'], isNull);
    });

    test('custom foreign key', () async {
      final user = User({'id': 1});
      final customRelation = HasOne<Profile>(
        user,
        Profile.new,
        'custom_user_id',
        'id',
      );

      await customRelation.get();

      expect(dbSpy.lastSql, contains('custom_user_id = ?'));
    });
  });

  // ===========================================================================
  // HAS MANY
  // ===========================================================================
  group('HasMany Extended', () {
    test('returns empty list when no children', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final user = User({'id': 1});
      final posts = await user.posts().get();

      expect(posts, isEmpty);
    });

    test('eager load distributes correctly to parents', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM posts': [
          {'id': 1, 'user_id': 1, 'title': 'Post A'},
          {'id': 2, 'user_id': 1, 'title': 'Post B'},
          {'id': 3, 'user_id': 2, 'title': 'Post C'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = [
        User({'id': 1}),
        User({'id': 2}),
      ];

      await users.first.posts().match(users, 'posts');

      expect((users[0].relations['posts'] as List).length, 2);
      expect((users[1].relations['posts'] as List).length, 1);
    });

    test('chained where on relation query', () async {
      final user = User({'id': 1});

      await user.posts().where('status', 'published').where('views', 100, operator: '>').get();

      expect(dbSpy.lastSql, contains('user_id = ?'));
      expect(dbSpy.lastSql, contains('status = ?'));
      expect(dbSpy.lastSql, contains('views > ?'));
    });

    test('orderBy on relation query', () async {
      final user = User({'id': 1});

      await user.posts().orderBy('created_at', direction: 'DESC').get();

      expect(dbSpy.lastSql, contains('ORDER BY created_at DESC'));
    });

    test('limit on relation query', () async {
      final user = User({'id': 1});

      await user.posts().limit(5).get();

      expect(dbSpy.lastSql, contains('LIMIT 5'));
    });
  });

  // ===========================================================================
  // BELONGS TO
  // ===========================================================================
  group('BelongsTo Extended', () {
    test('returns null when foreign key is null', () async {
      final post = Post({'id': 1, 'user_id': null});
      final author = await post.author().getResult();

      expect(author, isNull);
    });

    test('eager load skips null foreign keys', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 1, 'name': 'David'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1, 'user_id': 1}),
        Post({'id': 2, 'user_id': null}),
      ];

      await posts.first.author().match(posts, 'author');

      expect(posts[0].relations['author'], isA<User>());
      expect(posts[1].relations.containsKey('author'), isFalse);
    });

    test('eager load with mixed null/valid foreign keys', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 1, 'name': 'David'},
          {'id': 2, 'name': 'Romolo'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1, 'user_id': 1}),
        Post({'id': 2, 'user_id': null}),
        Post({'id': 3, 'user_id': 2}),
      ];

      await posts.first.author().match(posts, 'author');

      expect((posts[0].relations['author'] as User).id, 1);
      expect(posts[1].relations.containsKey('author'), isFalse);
      expect((posts[2].relations['author'] as User).id, 2);
    });
  });
}