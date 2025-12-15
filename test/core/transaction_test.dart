import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';
import '../mocks/moke_database.dart';

class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

class Profile extends Model {
  @override
  String get table => 'profiles';

  Profile([super.attributes]);

  @override
  Profile fromMap(Map<String, dynamic> map) => Profile(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {
      'last_insert_rowid': [
        {'id': 1},
      ],
      'FROM users': [
        {'id': 1, 'name': 'David'},
      ],
      'FROM profiles': [
        {'id': 1, 'user_id': 1, 'bio': 'Test bio'},
      ],
    });
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Transaction Support', () {
    test('transaction() executes callback and commits on success', () async {
      await DatabaseManager().transaction((txn) async {
        final user = User({'name': 'David'});
        await user.save();
        return user;
      });

      expect(dbSpy.history, contains('BEGIN TRANSACTION'));
      expect(dbSpy.history, contains('COMMIT'));
      expect(dbSpy.history, isNot(contains('ROLLBACK')));
    });

    test('transaction() rolls back on exception', () async {
      dbSpy.shouldFailTransaction = true;

      try {
        await DatabaseManager().transaction((txn) async {
          final user = User({'name': 'David'});
          await user.save();
          return user;
        });
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<TransactionException>());
      }

      expect(dbSpy.history, contains('BEGIN TRANSACTION'));
      expect(dbSpy.history, contains('ROLLBACK'));
      expect(dbSpy.history, isNot(contains('COMMIT')));
    });

    test('inTransaction returns correct state', () async {
      expect(DatabaseManager().inTransaction, isFalse);

      await DatabaseManager().transaction((txn) async {
        expect(DatabaseManager().inTransaction, isTrue);
        return null;
      });

      expect(DatabaseManager().inTransaction, isFalse);
    });

    test('multiple model operations participate in same transaction', () async {
      await DatabaseManager().transaction((txn) async {
        final user = User({'name': 'David'});
        await user.save();

        final profile = Profile({'user_id': 1, 'bio': 'Test'});
        await profile.save();

        return null;
      });

      // Verify both inserts happened within transaction
      final insertCount =
          dbSpy.transactionHistory.where((s) => s.contains('INSERT')).length;
      expect(insertCount, 2);
    });

    test('TransactionException contains original error', () async {
      dbSpy.shouldFailTransaction = true;

      try {
        await DatabaseManager().transaction((txn) async {
          await txn.execute('INVALID SQL');
        });
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<TransactionException>());
        final txnError = e as TransactionException;
        expect(txnError.wasRolledBack, isTrue);
        expect(txnError.originalError, isNotNull);
      }
    });
  });
}