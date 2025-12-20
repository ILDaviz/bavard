import 'package:bavard/src/core/concerns/has_soft_deletes.dart';
import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../../mocks/moke_database.dart';

class SoftUser extends Model with HasSoftDeletes {
  @override
  String get table => 'users';

  bool onDeletingCalled = false;
  bool onDeletedCalled = false;

  SoftUser([super.attributes]);

  @override
  SoftUser fromMap(Map<String, dynamic> map) => SoftUser(map);

  @override
  Map<String, String> get casts => {'deleted_at': 'datetime'};

  @override
  Future<bool> onDeleting() async {
    onDeletingCalled = true;
    return super.onDeleting();
  }

  @override
  Future<void> onDeleted() async {
    onDeletedCalled = true;
    await super.onDeleted();
  }
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

  group('HasSoftDeletes Extended', () {
    test('trashed getter returns true when deleted_at is set', () {
      final user = SoftUser({'id': 1, 'deleted_at': '2023-01-01T10:00:00'});
      expect(user.trashed, isTrue);
    });

    test('trashed getter returns false when deleted_at is null', () {
      final user = SoftUser({'id': 1, 'deleted_at': null});
      expect(user.trashed, isFalse);
    });

    test('trashed getter returns false when deleted_at is missing', () {
      final user = SoftUser({'id': 1});
      expect(user.trashed, isFalse);
    });

    test('delete() on new model (exists=false, no id) does nothing', () async {
      final user = SoftUser({'name': 'David'});
      // id is null, exists is false

      await user.delete();

      expect(dbSpy.history, isEmpty);
    });

    test('restore() clears deleted_at', () async {
      final restoreMock = MockDatabaseSpy([], {
        'SELECT users.* FROM users WHERE id = ? LIMIT 1': [
          {'id': 1, 'name': 'David', 'deleted_at': null},
        ],
      });
      DatabaseManager().setDatabase(restoreMock);

      final user = SoftUser({'id': 1, 'deleted_at': '2023-01-01T10:00:00'});
      user.exists = true;
      user.syncOriginal();

      await user.restore();

      expect(user.trashed, isFalse);
      expect(user.attributes['deleted_at'], isNull);
    });

    test('restore() on non-trashed model still saves', () async {
      final mockDb = MockDatabaseSpy([], {
        'SELECT * FROM users WHERE id = ?': [
          {'id': 1, 'name': 'David', 'deleted_at': null},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = SoftUser({'id': 1, 'deleted_at': null});
      user.exists = true;
      user.syncOriginal();

      await user.restore();

      // Should still attempt to save (no-op due to no dirty fields)
      expect(user.trashed, isFalse);
    });

    test('forceDelete() removes from DB permanently', () async {
      final user = SoftUser({'id': 1});
      user.exists = true;

      await user.forceDelete();

      expect(dbSpy.lastSql, contains('DELETE FROM users'));
      expect(dbSpy.lastSql, contains('WHERE id = ?'));
    });

    test('forceDelete() triggers onDeleting/onDeleted hooks', () async {
      final user = SoftUser({'id': 1});
      user.exists = true;

      await user.forceDelete();

      expect(user.onDeletingCalled, isTrue);
      expect(user.onDeletedCalled, isTrue);
    });

    test('withTrashed() combined with where clauses', () async {
      await SoftUser().withTrashed().where('name', 'David').get();

      expect(dbSpy.lastSql, contains('WHERE name = ?'));
      expect(dbSpy.lastSql, isNot(contains('deleted_at IS NULL')));
    });

    test('onlyTrashed() combined with where clauses', () async {
      await SoftUser().onlyTrashed().where('role', 'admin').get();

      expect(dbSpy.lastSql, contains('WHERE deleted_at IS NOT NULL'));
      expect(dbSpy.lastSql, contains('AND role = ?'));
    });

    test('standard query excludes soft deleted records', () async {
      await SoftUser().query().get();

      expect(dbSpy.lastSql, contains('WHERE deleted_at IS NULL'));
    });
  });
}
