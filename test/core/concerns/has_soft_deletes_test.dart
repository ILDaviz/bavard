import 'package:bavard/src/core/concerns/has_soft_deletes.dart';
import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class User extends Model with HasSoftDeletes {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  @override
  Map<String, String> get casts => {'deleted_at': 'datetime'};
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {
      'SELECT users.* FROM users WHERE id = ? LIMIT 1': [
        {'id': 1, 'name': 'David', 'deleted_at': '2023-01-01'},
      ],
    });
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Soft Deletes Logic', () {
    test('delete() performs UPDATE on deleted_at instead of DELETE', () async {
      final user = User({'id': 1, 'name': 'David'});
      user.exists = true;
      user.syncOriginal();

      await user.delete();

      expect(dbSpy.history, contains(contains('UPDATE users SET')));
      expect(dbSpy.history, contains(contains('deleted_at = ?')));

      final hasDelete = dbSpy.history.any((sql) => sql.contains('DELETE FROM'));
      expect(hasDelete, isFalse);

      expect(user.trashed, isTrue);
    });

    test(
      'Standard query automatically excludes soft deleted records',
      () async {
        await User().query().get();
        expect(dbSpy.lastSql, contains('WHERE deleted_at IS NULL'));
      },
    );

    test('withTrashed() includes soft deleted records', () async {
      await User().withTrashed().get();
      expect(dbSpy.lastSql, isNot(contains('deleted_at IS NULL')));
    });

    test('onlyTrashed() fetches ONLY soft deleted records', () async {
      await User().onlyTrashed().get();
      expect(dbSpy.lastSql, contains('WHERE deleted_at IS NOT NULL'));
    });

    test('restore() resets deleted_at to NULL', () async {
      final restoreMock = MockDatabaseSpy([], {
        'SELECT users.* FROM users WHERE id = ? LIMIT 1': [
          {'id': 1, 'name': 'David', 'deleted_at': null},
        ],
      });
      DatabaseManager().setDatabase(restoreMock);

      final user = User({'id': 1, 'deleted_at': '2023-01-01 10:00:00'});
      user.exists = true;
      user.syncOriginal();

      await user.restore();

      expect(restoreMock.history, contains(contains('UPDATE users SET')));

      expect(user.trashed, isFalse);
      expect(user.attributes['deleted_at'], isNull);
    });

    test('forceDelete() performs physical DELETE', () async {
      final user = User({'id': 1});
      user.exists = true;

      await user.forceDelete();

      expect(dbSpy.lastSql, contains('DELETE FROM users'));
      expect(dbSpy.lastSql, contains('WHERE id = ?'));
    });
  });
}
