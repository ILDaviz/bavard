import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class Post extends Model {
  @override
  String get table => 'posts';

  Post([super.attributes]);

  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  MorphMany<Comment> comments() {
    return morphMany(Comment.new, 'commentable');
  }
}

class Comment extends Model {
  @override
  String get table => 'comments';

  Comment([super.attributes]);

  @override
  Comment fromMap(Map<String, dynamic> map) => Comment(map);
}

void main() {
  group('MorphMany Relation', () {
    test(
      'It generates SQL with Type and ID constraints for lazy loading',
      () async {
        final dbSpy = MockDatabaseSpy();
        DatabaseManager().setDatabase(dbSpy);

        final post = Post({'id': 1});

        await post.comments().get();

        expect(dbSpy.lastSql, contains('FROM comments'));

        expect(dbSpy.lastSql, contains("commentable_type = ?"));
        expect(dbSpy.lastSql, contains("commentable_id = ?"));

        expect(dbSpy.lastArgs, contains('posts'));
        expect(dbSpy.lastArgs, contains('1'));
      },
    );

    test('It eager loads children filtering by Type correctly', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM comments': [
          {
            'id': 100,
            'body': 'Nice Post',
            'commentable_type': 'posts',
            'commentable_id': 1,
          },
          {
            'id': 101,
            'body': 'Bad Post',
            'commentable_type': 'posts',
            'commentable_id': 2,
          },
          {
            'id': 102,
            'body': 'Nice Video',
            'commentable_type': 'videos',
            'commentable_id': 1,
          },
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
        Post({'id': 2}),
      ];

      await posts.first.comments().match(posts, 'comments');

      final commentsPost1 = posts[0].relations['comments'] as List;
      final commentsPost2 = posts[1].relations['comments'] as List;

      expect(commentsPost1, hasLength(1));
      expect((commentsPost1.first as Comment).attributes['body'], 'Nice Post');

      expect(commentsPost2, hasLength(1));
      expect((commentsPost2.first as Comment).attributes['body'], 'Bad Post');
    });
  });
}
