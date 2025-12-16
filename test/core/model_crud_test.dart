import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

void main() {
  group('Model CRUD Operations', () {
    test('save() performs INSERT when ID is null', () async {
      final insertMock = MockDatabaseSpy([], {
        'last_insert_rowid': [
          {'id': 101},
        ],
        'FROM users': [
          {'id': 101, 'name': 'David', 'email': 'david@test.com'},
        ],
      });
      DatabaseManager().setDatabase(insertMock);

      final user = User();
      user.attributes['name'] = 'David';
      user.attributes['email'] = 'david@test.com';

      await user.save();

      expect(insertMock.history, contains(contains('INSERT INTO users')));

      expect(user.id, 101);
      expect(user.attributes['name'], 'David');
    });

    test(
      'save() performs UPDATE when ID exists and fields are dirty',
      () async {
        final updateMock = MockDatabaseSpy([], {
          'FROM users': [
            {'id': 1, 'name': 'David', 'role': 'Admin'},
          ],
        });
        DatabaseManager().setDatabase(updateMock);

        final user = User({'id': 1, 'name': 'David', 'role': 'User'});
        user.exists = true;
        user.syncOriginal();

        user.attributes['role'] = 'Admin';

        await user.save();

        expect(updateMock.history, contains(contains('UPDATE users SET')));

        final updateSql = updateMock.history.firstWhere(
          (sql) => sql.contains('UPDATE'),
        );
        expect(updateSql, contains('role = ?'));
        expect(updateSql, isNot(contains('name = ?')));
        expect(updateSql, contains('WHERE id = ?'));

        expect(user.attributes['role'], 'Admin');
      },
    );

    test('save() does NOTHING if no fields are dirty', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      final user = User({'id': 1, 'name': 'David'});
      user.exists = true;
      user.syncOriginal();

      await user.save();

      expect(dbSpy.history, isEmpty);
    });

    test('delete() performs DELETE query', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      final user = User({'id': 50});
      user.exists = true;

      await user.delete();

      expect(dbSpy.lastSql, contains('DELETE FROM users'));
      expect(dbSpy.lastSql, contains('WHERE id = ?'));
      expect(dbSpy.lastArgs, [50]);
    });
  });
}
