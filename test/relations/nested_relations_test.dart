import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

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

  List<Post> get postsList => getRelationList<Post>('posts');
}

class Post extends Model {
  @override
  String get table => 'posts';

  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  HasMany<Comment> comments() => hasMany(Comment.new);

  BelongsTo<User> user() => belongsTo(User.new, foreignKey: 'user_id');

  @override
  Relation? getRelation(String name) {
    if (name == 'comments') return comments();
    if (name == 'user') return user();
    return super.getRelation(name);
  }

  List<Comment> get commentsList => getRelationList<Comment>('comments');
}

class Comment extends Model {
  @override
  String get table => 'comments';

  Comment([super.attributes]);
  @override
  Comment fromMap(Map<String, dynamic> map) => Comment(map);

  BelongsTo<User> author() =>
      belongsTo(User.new, foreignKey: 'author_id', ownerKey: 'id');

  @override
  Relation? getRelation(String name) {
    if (name == 'author') return author();
    return super.getRelation(name);
  }

  User? get authorModel => getRelated<User>('author');
}

void main() {
  group('Nested Relations', () {
    test('It eager loads nested relations via dot notation', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
        'FROM "posts"': [
          {'id': 100, 'user_id': 1, 'title': 'Post A'},
        ],
        'FROM "comments"': [
          {'id': 200, 'post_id': 100, 'content': 'First comment'},
          {'id': 201, 'post_id': 100, 'content': 'Second comment'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = await User().query().withRelations([
        'posts',
        'posts.comments',
      ]).get();

      final user = users.first;

      // Verify posts loaded
      expect(user.postsList, isNotEmpty);
      expect(user.postsList.first.id, 100);

      // Verify nested comments loaded on the post
      final post = user.postsList.first;
      expect(post.commentsList, isNotEmpty);
      expect(post.commentsList, hasLength(2));
      expect(post.commentsList.first.attributes['content'], 'First comment');
    });

    test('It loads only top level if nested is not specified', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
        'FROM "posts"': [
          {'id': 100, 'user_id': 1, 'title': 'Post A'},
        ],
        'FROM "comments"': [
          {'id': 200, 'post_id': 100, 'content': 'Should not load'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = await User().query().withRelations(['posts']).get();

      final user = users.first;
      final post = user.postsList.first;

      expect(post.relations.containsKey('comments'), isFalse);
      expect(post.commentsList, isEmpty);
    });

    test(
      'It handles implicit top-level relation when only nested is specified',
      () async {
        final mockDb = MockDatabaseSpy([], {
          'FROM "users"': [
            {'id': 1, 'name': 'David'},
          ],
          'FROM "posts"': [
            {'id': 100, 'user_id': 1, 'title': 'Post A'},
          ],
          'FROM "comments"': [
            {'id': 200, 'post_id': 100, 'content': 'First comment'},
          ],
        });
        DatabaseManager().setDatabase(mockDb);

        final users = await User()
            .query()
            .withRelations(['posts.comments']) // 'posts' is implicit
            .get();

        final user = users.first;

        expect(user.postsList, isNotEmpty);

        final post = user.postsList.first;
        expect(post.commentsList, isNotEmpty);
      },
    );

    test('It handles deep nesting (3 levels): posts.comments.author', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
          {'id': 2, 'name': 'Commenter'},
        ],
        'FROM "posts"': [
          {'id': 100, 'user_id': 1, 'title': 'Post A'},
        ],
        'FROM "comments"': [
          {
            'id': 200,
            'post_id': 100,
            'author_id': 2,
            'content': 'Deep comment',
          },
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = await User().query().withRelations([
        'posts.comments.author',
      ]).get();

      final user = users.firstWhere((u) => u.id == 1);

      expect(user.postsList, isNotEmpty);
      final post = user.postsList.first;

      expect(post.commentsList, isNotEmpty);
      final comment = post.commentsList.first;

      expect(comment.authorModel, isNotNull);
      expect(comment.authorModel!.id, 2);
      expect(comment.authorModel!.attributes['name'], 'Commenter');
    });
  });

  test('It handles circular nesting: posts.user.posts', () async {
    final mockDb = MockDatabaseSpy([], {
      'FROM "posts" WHERE "id" = ?': [
        {'id': 100, 'user_id': 1, 'title': 'Root Post'},
      ],
      'FROM "users"': [
        {'id': 1, 'name': 'David'},
      ],
      'FROM "posts" WHERE "user_id" IN': [
        {'id': 100, 'user_id': 1, 'title': 'Root Post'},
        {'id': 101, 'user_id': 1, 'title': 'Other Post'},
      ],
    });
    DatabaseManager().setDatabase(mockDb);

    final result = await Post()
        .query()
        .withRelations(['user.posts'])
        .where('id', 100)
        .get();

    expect(result, hasLength(1));
    final rootPost = result.first;

    final user = rootPost.getRelated<User>('user');
    expect(user, isNotNull);
    expect(user!.id, 1);

    final userPosts = user.getRelationList<Post>('posts');
    expect(userPosts, hasLength(2));

    expect(userPosts.any((p) => p.id == 100), isTrue);
    expect(userPosts.any((p) => p.id == 101), isTrue);
  });

  test('It handles broken chain (empty intermediate HasMany)', () async {
    final mockDb = MockDatabaseSpy([], {
      'FROM "users"': [
        {'id': 1, 'name': 'User No Posts'},
      ],
      'FROM "posts"': [], // Missing posts
    });
    DatabaseManager().setDatabase(mockDb);

    final users = await User().query().withRelations(['posts.comments']).get();

    expect(users, hasLength(1));
    expect(users.first.postsList, isEmpty);
  });

  test('It handles broken chain (null intermediate BelongsTo)', () async {
    final mockDb = MockDatabaseSpy([], {
      'FROM "comments"': [
        {'id': 1, 'content': 'Orphan', 'post_id': null},
      ],
      // Posts is null
    });
    DatabaseManager().setDatabase(mockDb);

    final comments = await Comment().query().withRelations([
      'post.author',
    ]).get();

    final comment = comments.first;
    expect(comment.getRelated('post'), isNull);
  });

  test(
    'It handles branching nested relations (same root, different children)',
    () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
        'FROM "posts"': [
          {'id': 100, 'user_id': 1, 'title': 'Post A'},
        ],
        'FROM "comments"': [
          {'id': 200, 'post_id': 100, 'content': 'Comment 1'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      await User().query().withRelations([
        'posts.comments',
        'posts.author',
      ]).get();

      final postQueries = mockDb.history
          .where((sql) => sql.contains('FROM "posts"'))
          .length;

      expect(
        postQueries,
        1,
        reason: 'Should group nested relations and fetch root only once',
      );
    },
  );
}
