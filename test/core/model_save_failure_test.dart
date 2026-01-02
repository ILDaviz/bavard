import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class FailingMockDatabase extends MockDatabaseSpy {
  bool shouldFailInsert = false;
  bool shouldFailUpdate = false;

  FailingMockDatabase() : super();

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    if (shouldFailInsert) {
      throw Exception('Database insert failed');
    }
    return super.insert(table, values);
  }

  @override
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    if (shouldFailUpdate && sql.contains('UPDATE')) {
      throw Exception('Database update failed');
    }
    return super.execute(table, sql, arguments);
  }
}

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

void main() {
  group('Model State After Failed Operations', () {
    test('model state remains consistent after failed INSERT', () async {
      final failingDb = FailingMockDatabase();
      failingDb.shouldFailInsert = true;
      DatabaseManager().setDatabase(failingDb);

      final user = User({'name': 'David'});

      expect(user.exists, isFalse);
      expect(user.id, isNull);

      try {
        await user.save();
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(
        user.exists,
        isFalse,
        reason: 'exists should remain false after failed insert',
      );
    });

    test('model state remains consistent after failed UPDATE', () async {
      final failingDb = FailingMockDatabase();
      DatabaseManager().setDatabase(failingDb);

      final user = User({'id': 1, 'name': 'David', 'email': 'old@test.com'});
      user.exists = true;
      user.syncOriginal();

      user.attributes['email'] = 'new@test.com';

      failingDb.shouldFailUpdate = true;

      try {
        await user.save();
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(user.exists, isTrue);
      expect(user.attributes['email'], 'new@test.com');
      expect(user.original['email'], 'old@test.com');
    });

    test('dirty checking works correctly after failed save', () async {
      final failingDb = FailingMockDatabase();
      DatabaseManager().setDatabase(failingDb);

      final user = User({'id': 1, 'name': 'David'});
      user.exists = true;
      user.syncOriginal();

      user.attributes['name'] = 'Updated';
      failingDb.shouldFailUpdate = true;

      try {
        await user.save();
      } catch (e) {
      }

      expect(user.attributes['name'], isNot(equals(user.original['name'])));

      final workingDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 1, 'name': 'Updated'},
        ],
      });
      DatabaseManager().setDatabase(workingDb);

      await user.save();

      expect(workingDb.history.any((s) => s.contains('UPDATE')), isTrue);
    });
  });
}
