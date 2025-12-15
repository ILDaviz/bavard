import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';
import '../mocks/moke_database.dart';

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
  test('MorphTo eager loads mixed types (Posts and Videos)', () async {
    final mockDb = MockDatabaseSpy([], {
      'FROM posts': [
        {'id': 100, 'title': 'Post A'},
      ],
      'FROM videos': [
        {'id': 200, 'title': 'Video B'},
      ],
    });
    DatabaseManager().setDatabase(mockDb);

    final comments = [
      Comment({'id': 1, 'commentable_type': 'posts', 'commentable_id': 100}),
      Comment({'id': 2, 'commentable_type': 'videos', 'commentable_id': 200}),
    ];

    await comments.first.commentable().match(comments, 'commentable');

    final post = comments[0].relations['commentable'];
    final video = comments[1].relations['commentable'];

    expect(post, isA<Post>());
    expect((post as Post).id, 100);

    expect(video, isA<Video>());
    expect((video as Video).id, 200);
  });

  test('MorphTo lazy loads via getResult()', () async {
    final mockDb = MockDatabaseSpy([], {
      'FROM posts': [
        {'id': 100, 'title': 'Post A'},
      ],
    });
    DatabaseManager().setDatabase(mockDb);

    final comment =
    Comment({'id': 1, 'commentable_type': 'posts', 'commentable_id': 100});

    final parent = await comment.commentable().getResult();

    expect(parent, isA<Post>());
    expect((parent as Post).attributes['title'], 'Post A');
  });
}