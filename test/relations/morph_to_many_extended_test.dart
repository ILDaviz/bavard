import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class Post extends Model {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  MorphToMany<Tag> tags() => morphToMany(Tag.new, 'taggable');
}

class Video extends Model {
  @override
  String get table => 'videos';
  Video([super.attributes]);
  @override
  Video fromMap(Map<String, dynamic> map) => Video(map);

  MorphToMany<Tag> tags() => morphToMany(Tag.new, 'taggable');
}

class Tag extends Model {
  @override
  String get table => 'tags';
  Tag([super.attributes]);
  @override
  Tag fromMap(Map<String, dynamic> map) => Tag(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('MorphToMany Extended', () {
    test('returns empty when no pivot entries', () async {
      final mockDb = MockDatabaseSpy([], {'FROM taggables': []});
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
      ];
      await posts.first.tags().match(posts, 'tags');

      final tags = posts.first.getRelationList<Tag>('tags');
      expect(tags, isEmpty);
    });

    test('filters by parent type in pivot', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM taggables': [
          {'tag_id': 10, 'taggable_id': 1, 'taggable_type': 'posts'},
          {
            'tag_id': 11,
            'taggable_id': 1,
            'taggable_type': 'videos',
          },
        ],
        'FROM tags': [
          {'id': 10, 'name': 'Flutter'},
          {'id': 11, 'name': 'Dart'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
      ];
      await posts.first.tags().match(posts, 'tags');

      final tags = posts.first.relations['tags'] as List;

      expect(tags.length, 1);
      expect((tags.first as Tag).attributes['name'], 'Flutter');
    });

    test('eager load with multiple parent types', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM taggables': [
          {'tag_id': 10, 'taggable_id': 1, 'taggable_type': 'posts'},
          {'tag_id': 11, 'taggable_id': 1, 'taggable_type': 'posts'},
        ],
        'FROM tags': [
          {'id': 10, 'name': 'Flutter'},
          {'id': 11, 'name': 'Dart'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = [
        Post({'id': 1}),
      ];
      await posts.first.tags().match(posts, 'tags');

      final tags = posts.first.relations['tags'] as List;
      expect(tags.length, 2);
    });

    test('pivot table naming convention', () async {
      final post = Post({'id': 1});
      await post.tags().get();

      expect(dbSpy.lastSql, contains('taggables'));
    });
  });
}
