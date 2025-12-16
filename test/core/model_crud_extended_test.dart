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
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {
      'last_insert_rowid': [
        {'id': 1}
      ],
      'FROM users': [
        {'id': 1, 'name': 'David', 'email': 'david@test.com'}
      ],
    });
    DatabaseManager().setDatabase(dbSpy);
  });

  // ===========================================================================
  // CREATE
  // ===========================================================================
  group('Create Operations', () {
    test('save() new model without any attributes', () async {
      final user = User();
      await user.save();

      expect(dbSpy.history.any((s) => s.contains('INSERT INTO users')), isTrue);
      expect(user.exists, isTrue);
    });

    test('save() with pre-set id (no auto-increment)', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': 'custom-uuid-123', 'name': 'David'}
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = User({'id': 'custom-uuid-123', 'name': 'David'});
      await user.save();

      final insertSql =
      mockDb.history.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('id'));

      expect(user.id, 'custom-uuid-123');
    });

    test('save() preserves attribute types after refresh', () async {
      final mockDb = MockDatabaseSpy([], {
        'last_insert_rowid': [
          {'id': 1}
        ],
        'FROM users': [
          {'id': 1, 'name': 'David', 'age': 30, 'active': 1}
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = User({'name': 'David', 'age': 30, 'active': 1});
      await user.save();

      expect(user.attributes['age'], 30);
      expect(user.attributes['active'], 1);
    });

    test('save() with special characters in string values', () async {
      final user = User({
        'name': "O'Connor",
        'bio': 'Line1\nLine2\tTabbed',
        'emoji': '👍🎉',
      });

      expect(user.attributes['name'], "O'Connor");
      expect(user.attributes['bio'], 'Line1\nLine2\tTabbed');
      expect(user.attributes['emoji'], '👍🎉');

      await user.save();

      expect(dbSpy.history.any((s) => s.contains('INSERT')), isTrue);
    });

    test('save() with very long text values', () async {
      final longText = 'A' * 10000;
      final user = User({'bio': longText});

      expect(user.attributes['bio'], longText);
      expect(user.attributes['bio'].length, 10000);

      await user.save();

      expect(dbSpy.history.any((s) => s.contains('INSERT')), isTrue);
    });
  });

  // ===========================================================================
  // UPDATE
  // ===========================================================================
  group('Update Operations', () {
    test('save() updates only changed attributes', () async {
      final user = User({
        'id': 1,
        'name': 'David',
        'email': 'david@test.com',
        'age': 30
      });
      user.exists = true;
      user.syncOriginal();

      user.attributes['email'] = 'new@test.com';

      await user.save();

      final updateSql =
      dbSpy.history.firstWhere((s) => s.contains('UPDATE'), orElse: () => '');
      expect(updateSql, contains('email = ?'));
      expect(updateSql, isNot(contains('name = ?')));
      expect(updateSql, isNot(contains('age = ?')));
    });

    test('save() with unchanged attributes does nothing and returns early',
            () async {
          final user = User({'id': 1, 'name': 'David'});
          user.exists = true;
          user.syncOriginal();

          await user.save();

          expect(dbSpy.history, isEmpty);
        });

    test('save() resets dirty state after success', () async {
      final user = User({'id': 1, 'name': 'David'});
      user.exists = true;
      user.syncOriginal();

      user.attributes['name'] = 'Updated';
      await user.save();

      expect(user.original['name'], user.attributes['name']);
    });

    test('save() with null value overwrites existing', () async {
      final user = User({'id': 1, 'name': 'David', 'email': 'test@test.com'});
      user.exists = true;
      user.syncOriginal();

      user.attributes['email'] = null;
      await user.save();

      final updateSql =
      dbSpy.history.firstWhere((s) => s.contains('UPDATE'), orElse: () => '');
      expect(updateSql, contains('email = ?'));
    });

    test('save() detects changes correctly with different types', () async {
      final user = User({'id': 1, 'count': 5, 'active': true});
      user.exists = true;
      user.syncOriginal();

      user.attributes['count'] = 10;
      user.attributes['active'] = false;
      await user.save();

      final updateSql =
      dbSpy.history.firstWhere((s) => s.contains('UPDATE'), orElse: () => '');
      expect(updateSql, contains('count = ?'));
      expect(updateSql, contains('active = ?'));
    });
  });

  // ===========================================================================
  // DELETE
  // ===========================================================================
  group('Delete Operations', () {
    test('delete() on model without id does nothing', () async {
      final user = User({'name': 'David'});
      await user.delete();
      expect(dbSpy.history, isEmpty);
    });

    test('delete() executes DELETE statement', () async {
      final user = User({'id': 50});
      user.exists = true;

      await user.delete();

      expect(dbSpy.lastSql, contains('DELETE FROM users'));
      expect(dbSpy.lastSql, contains('WHERE id = ?'));
      expect(dbSpy.lastArgs, [50]);
    });
  });

  // ===========================================================================
  // REFRESH / SYNC
  // ===========================================================================
  group('Refresh & Sync Operations', () {
    test('syncOriginal() creates deep copy', () async {
      final user = User({'id': 1, 'name': 'David', 'tags': ['a', 'b']});
      user.syncOriginal();

      user.attributes['name'] = 'Changed';

      expect(user.original['name'], 'David');
      expect(user.attributes['name'], 'Changed');
    });

    test('syncOriginal() after save reflects DB values', () async {
      final mockDb = MockDatabaseSpy([], {
        'last_insert_rowid': [
          {'id': 99}
        ],
        'FROM users': [
          {'id': 99, 'name': 'FromDB', 'created_at': '2024-01-01'}
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = User({'name': 'Original'});
      await user.save();

      expect(user.original['name'], 'FromDB');
      expect(user.original['created_at'], '2024-01-01');
    });

    test('attributes modification does not affect original', () async {
      final user = User({'id': 1, 'name': 'David'});
      user.syncOriginal();

      user.attributes['name'] = 'Modified';
      user.attributes['newField'] = 'value';

      expect(user.original['name'], 'David');
      expect(user.original.containsKey('newField'), isFalse);
    });
  });
}