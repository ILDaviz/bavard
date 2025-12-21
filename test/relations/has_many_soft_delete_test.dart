import 'package:bavard/bavard.dart';
import 'package:bavard/src/core/concerns/has_soft_deletes.dart';
import 'package:test/test.dart';
import 'package:bavard/testing.dart';

class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasMany<Post> posts() => hasMany(Post.new);
}

class Post extends Model with HasSoftDeletes {
  @override
  String get table => 'posts';

  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {});
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Relations vs Global Scopes', () {
    test(
      'hasMany should respect Soft Deletes (Global Scope) of related model',
      () async {
        dbSpy.setMockData({
          'SELECT * FROM posts WHERE user_id = ? AND deleted_at IS NULL': [
            {
              'id': 10,
              'user_id': 1,
              'title': 'Active Post',
              'deleted_at': null,
            },
          ],
          'SELECT * FROM posts WHERE user_id = ?': [
            {
              'id': 10,
              'user_id': 1,
              'title': 'Active Post',
              'deleted_at': null,
            },
            {
              'id': 11,
              'user_id': 1,
              'title': 'Deleted Post',
              'deleted_at': '2023-01-01',
            },
          ],
        });

        final user = User({'id': 1});

        await user.posts().get();

        expect(
          dbSpy.lastSql,
          contains('"deleted_at" IS NULL'),
          reason: 'La relazione ha ignorato il Soft Delete del modello figlio!',
        );
      },
    );
  });
}
