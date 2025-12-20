import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/mock_database.dart';

class Post extends Model {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);
}

class Video extends Model {
  @override
  String get table => 'videos';
  Video([super.attributes]);
  @override
  Video fromMap(Map<String, dynamic> map) => Video(map);
}

class Comment extends Model {
  @override
  String get table => 'comments';
  Comment([super.attributes]);
  @override
  Comment fromMap(Map<String, dynamic> map) => Comment(map);

  MorphTo<Model> commentable() {
    return morphToTyped('commentable', {
      'posts': Post.new,
      'videos': Video.new,
    });
  }
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('MorphTo Extended', () {
    test('returns null when type is null', () async {
      final comment = Comment({
        'id': 1,
        'commentable_type': null,
        'commentable_id': 100,
      });

      final parent = await comment.commentable().getResult();

      expect(parent, isNull);
    });

    test('returns null when id is null', () async {
      final comment = Comment({
        'id': 1,
        'commentable_type': 'posts',
        'commentable_id': null,
      });

      final parent = await comment.commentable().getResult();

      expect(parent, isNull);
    });

    test('returns null when type not in typeMap', () async {
      final comment = Comment({
        'id': 1,
        'commentable_type': 'unknown_type',
        'commentable_id': 100,
      });

      final parent = await comment.commentable().getResult();

      expect(parent, isNull);
    });

    test('get() throws UnsupportedError', () {
      final comment = Comment({
        'id': 1,
        'commentable_type': 'posts',
        'commentable_id': 100,
      });

      expect(
        () => comment.commentable().get(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('watch() throws UnsupportedError', () {
      final comment = Comment({
        'id': 1,
        'commentable_type': 'posts',
        'commentable_id': 100,
      });

      expect(
        () => comment.commentable().watch(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('eager load groups by type efficiently', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM posts': [
          {'id': 100, 'title': 'Post A'},
          {'id': 101, 'title': 'Post B'},
        ],
        'FROM videos': [
          {'id': 200, 'title': 'Video A'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final comments = [
        Comment({'id': 1, 'commentable_type': 'posts', 'commentable_id': 100}),
        Comment({'id': 2, 'commentable_type': 'posts', 'commentable_id': 101}),
        Comment({'id': 3, 'commentable_type': 'videos', 'commentable_id': 200}),
      ];

      await comments.first.commentable().match(comments, 'commentable');

      // Should have made 2 queries (one per type), not 3
      final fromPostsCount = mockDb.history
          .where((s) => s.contains('FROM posts'))
          .length;
      final fromVideosCount = mockDb.history
          .where((s) => s.contains('FROM videos'))
          .length;

      expect(fromPostsCount, 1);
      expect(fromVideosCount, 1);
    });

    test('eager load with unknown type in data', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM posts': [
          {'id': 100, 'title': 'Post A'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final comments = [
        Comment({'id': 1, 'commentable_type': 'posts', 'commentable_id': 100}),
        Comment({
          'id': 2,
          'commentable_type': 'unknown',
          'commentable_id': 999,
        }),
      ];

      await comments.first.commentable().match(comments, 'commentable');

      expect(comments[0].relations['commentable'], isA<Post>());
      expect(comments[1].relations.containsKey('commentable'), isFalse);
    });
  });
}
