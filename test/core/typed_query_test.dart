import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class TypedUser extends Model with HasSoftDeletes {
  @override
  String get table => 'users';

  TypedUser([super.attributes]);

  @override
  TypedUser fromMap(Map<String, dynamic> map) => TypedUser(map);
}

class RegularUser extends Model {
  @override
  String get table => 'users';

  RegularUser([super.attributes]);

  @override
  RegularUser fromMap(Map<String, dynamic> map) => RegularUser(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {
      'FROM users': [
        {'id': 1, 'name': 'David'},
        {'id': 2, 'name': 'Romolo'},
      ],
    });
    DatabaseManager().setDatabase(dbSpy);
  });

  group('TypedQuery Extension', () {
    test('query() returns QueryBuilder<T> not QueryBuilder<Model>', () async {
      final query = RegularUser().query();

      expect(query, isA<QueryBuilder<RegularUser>>());
    });

    test('query() preserves model query overrides', () async {
      await TypedUser().query().get();

      expect(dbSpy.lastSql, contains('"deleted_at" IS NULL'));
    });

    test('query() with SoftDeletes applies scope', () async {
      await TypedUser().query().where('name', 'David').get();

      expect(dbSpy.lastSql, contains('"deleted_at" IS NULL'));
      expect(dbSpy.lastSql, contains('"name" = ?'));
    });

    test('get() returns List<T> with correct type', () async {
      final users = await RegularUser().query().get();

      expect(users, isA<List<RegularUser>>());
      expect(users.first, isA<RegularUser>());
    });

    test('first() returns T? with correct type', () async {
      final user = await RegularUser().query().first();

      expect(user, isA<RegularUser?>());
    });

    test('find() returns T? with correct type', () async {
      final mockDb = MockDatabaseSpy([], {
        'LIMIT 1': [
          {'id': 1, 'name': 'David'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = await RegularUser().query().find(1);

      expect(user, isA<RegularUser?>());
    });

    test('query chain maintains type through all operations', () async {
      final query = RegularUser()
          .query()
          .where('active', 1)
          .orderBy('name')
          .limit(10);

      expect(query, isA<QueryBuilder<RegularUser>>());

      final results = await query.get();
      expect(results, isA<List<RegularUser>>());
    });
  });
}
