import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class TypedPost extends Model {
  @override
  String get table => 'posts';

  TypedPost([super.attributes]);
  @override
  TypedPost fromMap(Map<String, dynamic> map) => TypedPost(map);

  BelongsTo<TypedUser> author() {
    return belongsTo(TypedUser.new, foreignKey: 'user_id', ownerKey: 'id');
  }

  @override
  Relation? getRelation(String name) {
    if (name == 'author') return author();
    return super.getRelation(name);
  }

  TypedUser? get authorModel => getRelated<TypedUser>('author');
}

class TypedUser extends Model {
  @override
  String get table => 'users';

  TypedUser([super.attributes]);
  @override
  TypedUser fromMap(Map<String, dynamic> map) => TypedUser(map);

  HasMany<TypedPost> posts() => hasMany(TypedPost.new);

  @override
  Relation? getRelation(String name) {
    if (name == 'posts') return posts();
    return super.getRelation(name);
  }

  List<TypedPost> get postsList => getRelationList<TypedPost>('posts');
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Typed Relations & Accessors', () {
    test('It accesses HasMany relations as List<T> via getter', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 1, 'name': 'David'},
        ],
        'FROM posts': [
          {'id': 100, 'user_id': 1, 'title': 'Post A'},
          {'id': 101, 'user_id': 1, 'title': 'Post B'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = await TypedUser().query().withRelations(['posts']).get();
      final user = users.first;

      expect(user.postsList, isA<List<TypedPost>>());
      expect(user.postsList, hasLength(2));
      expect(user.postsList.first.attributes['title'], 'Post A');
    });

    test('It accesses BelongsTo relation as T? via getter', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM posts': [
          {'id': 100, 'user_id': 1, 'title': 'Post A'},
        ],
        'FROM users': [
          {'id': 1, 'name': 'David'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = await TypedPost().query().withRelations(['author']).get();
      final post = posts.first;

      expect(post.authorModel, isA<TypedUser>());
      expect(post.authorModel?.attributes['name'], 'David');
    });

    test(
      'It returns empty list instead of null for missing HasMany relations',
      () async {
        final mockDb = MockDatabaseSpy([], {
          'FROM users': [
            {'id': 1, 'name': 'David'},
          ],
        });
        DatabaseManager().setDatabase(mockDb);

        final users = await TypedUser().query().get();

        expect(users.first.postsList, isA<List<TypedPost>>());
        expect(users.first.postsList, isEmpty);
      },
    );

    test('It returns null for missing HasOne/BelongsTo relations', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM posts': [
          {'id': 100, 'user_id': 1},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final posts = await TypedPost().query().get();

      expect(posts.first.authorModel, isNull);
    });
  });
}
