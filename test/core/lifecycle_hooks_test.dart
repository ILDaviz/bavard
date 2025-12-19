import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class HookUser extends Model {
  @override
  String get table => 'users';

  bool allowSave = true;
  bool allowDelete = true;

  List<String> hookOrder = [];

  bool onSavingCalled = false;
  bool onSavedCalled = false;
  bool onDeletingCalled = false;
  bool onDeletedCalled = false;

  HookUser([super.attributes]);

  @override
  HookUser fromMap(Map<String, dynamic> map) => HookUser(map);

  @override
  Future<bool> onSaving() async {
    hookOrder.add('onSaving');
    onSavingCalled = true;
    return allowSave;
  }

  @override
  Future<void> onSaved() async {
    hookOrder.add('onSaved');
    onSavedCalled = true;
  }

  @override
  Future<bool> onDeleting() async {
    hookOrder.add('onDeleting');
    onDeletingCalled = true;
    return allowDelete;
  }

  @override
  Future<void> onDeleted() async {
    hookOrder.add('onDeleted');
    onDeletedCalled = true;
  }
}

class ModifyingHookUser extends Model {
  @override
  String get table => 'users';

  ModifyingHookUser([super.attributes]);

  @override
  ModifyingHookUser fromMap(Map<String, dynamic> map) => ModifyingHookUser(map);

  @override
  Future<bool> onSaving() async {
    // Modify attributes before save
    attributes['modified_by_hook'] = true;
    attributes['slug'] = (attributes['name'] as String?)?.toLowerCase().replaceAll(' ', '-');
    return true;
  }
}

class AsyncHookUser extends Model {
  @override
  String get table => 'users';

  List<String> asyncOrder = [];

  AsyncHookUser([super.attributes]);

  @override
  AsyncHookUser fromMap(Map<String, dynamic> map) => AsyncHookUser(map);

  @override
  Future<bool> onSaving() async {
    await Future.delayed(const Duration(milliseconds: 10));
    asyncOrder.add('onSaving_complete');
    return true;
  }

  @override
  Future<void> onSaved() async {
    await Future.delayed(const Duration(milliseconds: 10));
    asyncOrder.add('onSaved_complete');
  }
}

class ThrowingHookUser extends Model {
  @override
  String get table => 'users';
  ThrowingHookUser([super.attributes]);
  @override
  ThrowingHookUser fromMap(Map<String, dynamic> map) => ThrowingHookUser(map);

  @override
  Future<bool> onSaving() async {
    throw Exception('Error in onSaving');
  }
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {
      'last_insert_row_id': [
        {'id': 1}
      ],
      'FROM users': [
        {'id': 1, 'name': 'David'}
      ],
    });
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Lifecycle Hooks - Save', () {
    test('onSaving returns false cancels insert', () async {
      final user = HookUser({'name': 'David'});
      user.allowSave = false;

      await user.save();

      expect(dbSpy.history, isEmpty);
      expect(user.onSavingCalled, isTrue);
      expect(user.onSavedCalled, isFalse);
    });

    test('onSaving returns false cancels update', () async {
      final user = HookUser({'id': 1, 'name': 'David'});
      user.exists = true;
      user.syncOriginal();
      user.allowSave = false;

      user.attributes['name'] = 'Updated';
      await user.save();

      expect(dbSpy.history, isEmpty);
    });

    test('onSaving can modify attributes before save', () async {
      final mockDb = MockDatabaseSpy([], {
        'last_insert_row_id': [
          {'id': 1}
        ],
        'FROM users': [
          {'id': 1, 'name': 'Test User', 'modified_by_hook': true, 'slug': 'test-user'}
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = ModifyingHookUser({'name': 'Test User'});
      await user.save();

      final insertSql =
      mockDb.history.firstWhere((s) => s.contains('INSERT'), orElse: () => '');
      expect(insertSql, contains('modified_by_hook'));
      expect(insertSql, contains('slug'));
      expect(user.attributes['modified_by_hook'], isTrue);
      expect(user.attributes['slug'], 'test-user');
    });


    test('onSaved called after successful insert', () async {
      final user = HookUser({'name': 'David'});
      await user.save();

      expect(user.onSavingCalled, isTrue);
      expect(user.onSavedCalled, isTrue);
    });

    test('onSaved called after successful update', () async {
      final user = HookUser({'id': 1, 'name': 'David'});
      user.exists = true;
      user.syncOriginal();

      user.attributes['name'] = 'Updated';
      await user.save();

      expect(user.onSavedCalled, isTrue);
    });

    test('onSaved not called if onSaving returns false', () async {
      final user = HookUser({'name': 'David'});
      user.allowSave = false;

      await user.save();

      expect(user.onSavingCalled, isTrue);
      expect(user.onSavedCalled, isFalse);
    });
  });

  group('Lifecycle Hooks - Delete', () {
    test('onDeleting returns false cancels delete', () async {
      final user = HookUser({'id': 1});
      user.exists = true;
      user.allowDelete = false;

      await user.delete();

      expect(dbSpy.history, isEmpty);
      expect(user.onDeletingCalled, isTrue);
      expect(user.onDeletedCalled, isFalse);
    });

    test('onDeleted called after successful delete', () async {
      final user = HookUser({'id': 1});
      user.exists = true;

      await user.delete();

      expect(user.onDeletingCalled, isTrue);
      expect(user.onDeletedCalled, isTrue);
    });

    test('onDeleted not called if onDeleting returns false', () async {
      final user = HookUser({'id': 1});
      user.exists = true;
      user.allowDelete = false;

      await user.delete();

      expect(user.onDeletingCalled, isTrue);
      expect(user.onDeletedCalled, isFalse);
    });
  });

  group('Lifecycle Hooks - Order & Async', () {
    test('hooks called in correct order', () async {
      final user = HookUser({'name': 'David'});
      await user.save();

      expect(user.hookOrder, ['onSaving', 'onSaved']);
    });

    test('delete hooks called in correct order', () async {
      final user = HookUser({'id': 1});
      user.exists = true;

      await user.delete();

      expect(user.hookOrder, ['onDeleting', 'onDeleted']);
    });

    test('async hooks properly awaited', () async {
      final user = AsyncHookUser({'name': 'David'});
      await user.save();

      expect(user.asyncOrder, ['onSaving_complete', 'onSaved_complete']);
    });
  });

  test('save() propagates exception from onSaving and prevents DB operation', () async {
    final user = ThrowingHookUser({'name': 'David'});

    try {
      await user.save();
      fail('Should have thrown Exception');
    } catch (e) {
      expect(e.toString(), contains('Error in onSaving'));
    }

    expect(dbSpy.history, isEmpty);
    expect(user.exists, isFalse);
  });
}