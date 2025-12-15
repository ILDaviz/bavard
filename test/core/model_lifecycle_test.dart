import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';
import '../mocks/moke_database.dart';

class ProtectedUser extends Model {
  @override
  String get table => 'users';

  bool allowSave = true;
  bool allowDelete = true;
  bool onSavedCalled = false;

  ProtectedUser([super.attributes]);
  @override
  ProtectedUser fromMap(Map<String, dynamic> map) => ProtectedUser(map);

  @override
  Future<bool> onSaving() async {
    return allowSave;
  }

  @override
  Future<void> onSaved() async {
    onSavedCalled = true;
  }

  @override
  Future<bool> onDeleting() async {
    return allowDelete;
  }
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Model Lifecycle Hooks', () {
    test('save() is cancelled if onSaving returns false', () async {
      final user = ProtectedUser();
      user.allowSave = false;
      user.attributes['name'] = 'David';

      await user.save();

      expect(dbSpy.history, isEmpty);
      expect(user.onSavedCalled, isFalse);
    });

    test('save() proceeds if onSaving returns true', () async {
      final mock = MockDatabaseSpy([], {
        'last_insert_rowid': [
          {'id': 1},
        ],
        'FROM users': [
          {'id': 1},
        ],
      });
      DatabaseManager().setDatabase(mock);

      final user = ProtectedUser();
      user.allowSave = true;
      user.attributes['name'] = 'David';

      await user.save();

      expect(mock.history, isNotEmpty);
      expect(user.onSavedCalled, isTrue);
    });

    test('delete() is cancelled if onDeleting returns false', () async {
      final user = ProtectedUser({'id': 1});
      user.allowDelete = false;

      await user.delete();

      expect(dbSpy.history, isEmpty);
    });
  });
}
