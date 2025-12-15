// --- FILE: test/relations/morph_extended_test.dart ---

import 'package:flutter_test/flutter_test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class Post extends Model {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');
  MorphOne<Image> image() => morphOne(Image.new, 'imageable');
}

class Video extends Model {
  @override
  String get table => 'videos';
  Video([super.attributes]);
  @override
  Video fromMap(Map<String, dynamic> map) => Video(map);

  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');
}

class Comment extends Model {
  @override
  String get table => 'comments';
  Comment([super.attributes]);
  @override
  Comment fromMap(Map<String, dynamic> map) => Comment(map);
}

class Image extends Model {
  @override
  String get table => 'images';
  Image([super.attributes]);
  @override
  Image fromMap(Map<String, dynamic> map) => Image(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('MorphMany Extended', () {
    test('returns empty list when no children', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final post = Post({'id': 1});
      final comments = await post.comments().get();

      expect(comments, isEmpty);
    });

    test('filters by type excludes other types', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM comments': [
          {
            'id': 1,
            'commentable_type': 'posts',
            'commentable_id': 1,
            'body': 'Post comment'
          },
          {
            'id': 2,
            'commentable_type': 'videos',
            'commentable_id': 1,
            'body': 'Video comment'
          },
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [Post({'id': 1})];
      await posts.first.comments().match(posts, 'comments');

      final postComments = posts.first.relations['comments'] as List;

      // Should only include post comments, not video comments
      expect(postComments.length, 1);
      expect((postComments.first as Comment).attributes['body'], 'Post comment');
    });

    test('eager load groups by parent id AND type', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM comments': [
          {'id': 1, 'commentable_type': 'posts', 'commentable_id': 1},
          {'id': 2, 'commentable_type': 'posts', 'commentable_id': 2},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
        Post({'id': 2}),
      ];

      await posts.first.comments().match(posts, 'comments');

      expect((posts[0].relations['comments'] as List).length, 1);
      expect((posts[1].relations['comments'] as List).length, 1);
    });
  });

  group('MorphOne Extended', () {
    test('returns null when no polymorphic child', () async {
      final emptyMock = MockDatabaseSpy([], {});
      DatabaseManager().setDatabase(emptyMock);

      final posts = [Post({'id': 1})];
      await posts.first.image().match(posts, 'image');

      expect(posts.first.relations['image'], isNull);
    });

    test('eager load unwraps to single model', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM images': [
          {'id': 100, 'imageable_type': 'posts', 'imageable_id': 1, 'url': 'test.jpg'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [Post({'id': 1})];
      await posts.first.image().match(posts, 'image');

      expect(posts.first.relations['image'], isA<Image>());
      expect((posts.first.relations['image'] as Image).attributes['url'], 'test.jpg');
    });

    test('eager load sets null for missing', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM images': [
          {'id': 100, 'imageable_type': 'posts', 'imageable_id': 1},
          // No image for post 2
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
        Post({'id': 2}),
      ];

      await posts.first.image().match(posts, 'image');

      expect(posts[0].relations['image'], isA<Image>());
      expect(posts[1].relations['image'], isNull);
    });
  });
}