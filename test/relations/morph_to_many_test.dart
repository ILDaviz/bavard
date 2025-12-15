import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';
import '../mocks/moke_database.dart';

class Post extends Model {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  MorphToMany<Tag> tags() {
    return morphToMany(Tag.new, 'taggable');
  }
}

class Tag extends Model {
  @override
  String get table => 'tags';
  Tag([super.attributes]);
  @override
  Tag fromMap(Map<String, dynamic> map) => Tag(map);
}

void main() {
  group('MorphToMany Relation', () {
    test('It generates correct SQL JOINs for lazy loading', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      final post = Post({'id': 1});

      await post.tags().get();

      expect(
        dbSpy.lastSql,
        contains('JOIN taggables ON tags.id = taggables.tag_id'),
      );

      expect(dbSpy.lastSql, contains("taggables.taggable_type = ?"));

      expect(dbSpy.lastSql, contains("taggables.taggable_id = ?"));

      expect(dbSpy.lastArgs, contains('posts'));
      expect(dbSpy.lastArgs, contains(1));
    });

    test('It eager loads tags via pivot table', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM taggables': [
          {'tag_id': 100, 'taggable_id': 1, 'taggable_type': 'posts'},
          {'tag_id': 101, 'taggable_id': 1, 'taggable_type': 'posts'},
        ],
        'FROM tags': [
          {'id': 100, 'name': 'Tech'},
          {'id': 101, 'name': 'News'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
      ];

      await posts.first.tags().match(posts, 'tags');

      final tags = posts[0].relations['tags'] as List;

      expect(tags, hasLength(2));
      expect(tags.first, isA<Tag>());

      final names = tags.map((t) => (t as Tag).attributes['name']).toList();
      expect(names, containsAll(['Tech', 'News']));
    });
  });
}
