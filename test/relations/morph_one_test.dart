import 'package:flutter_test/flutter_test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class Post extends Model {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  MorphOne<Image> image() {
    return MorphOne(this, Image.new, 'imageable');
  }
}

class Image extends Model {
  @override
  String get table => 'images';
  Image([super.attributes]);
  @override
  Image fromMap(Map<String, dynamic> map) => Image(map);
}

void main() {
  group('MorphOne Relation', () {
    test('It generates correct SQL constraints for lazy loading', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      final post = Post({'id': 1});

      await post.image().get();

      expect(dbSpy.lastSql, contains('FROM images'));

      expect(dbSpy.lastSql, contains('imageable_type = ?'));

      expect(dbSpy.lastSql, contains('imageable_id = ?'));

      expect(dbSpy.lastArgs, contains('posts'));
      expect(dbSpy.lastArgs, contains('1'));
    });

    test('It eager loads and unwraps the result to a single Model', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM images': [
          {
            'id': 500,
            'url': 'cover.jpg',
            'imageable_type': 'posts',
            'imageable_id': 1,
          },
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
        Post({'id': 2}),
      ];

      await posts.first.image().match(posts, 'image');

      final imagePost1 = posts[0].relations['image'];
      expect(imagePost1, isA<Image>());
      expect((imagePost1 as Image).attributes['url'], 'cover.jpg');

      final imagePost2 = posts[1].relations['image'];
      expect(imagePost2, isNull);
    });
  });
}
