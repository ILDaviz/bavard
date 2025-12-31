import 'dart:async';
import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

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
      'last_insert_row_id': [
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

      final insertCount = dbSpy.transactionHistory
          .where((s) => s.contains('INSERT'))
          .length;
      expect(insertCount, 2);
    });

    test('TransactionException contains original error', () async {
      dbSpy.shouldFailTransaction = true;

      try {
        await DatabaseManager().transaction((txn) async {
          await txn.execute('users', 'INVALID SQL');
        });
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<TransactionException>());
        final txnError = e as TransactionException;
        expect(txnError.wasRolledBack, isTrue);
        expect(txnError.originalError, isNotNull);
      }
    });

    test('Transaction commit updates UI correctly', () async {
      final mockDb = MockDatabaseSpy();
      DatabaseManager().setDatabase(mockDb);

      mockDb.setMockData({
        'FROM "users"': [{'id': 1, 'name': 'Old Name'}],
      });

      final stream = User().query().watch();

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isA<List<User>>().having((l) => l.first.attributes['name'], 'initial', 'Old Name'),
          isA<List<User>>().having((l) => l.first.attributes['name'], 'updated', 'New Name'),
        ]),
      );

      await Future.delayed(Duration.zero);

      await DatabaseManager().transaction((txn) async {
        mockDb.setMockData({
          'FROM "users"': [{'id': 1, 'name': 'New Name'}],
        });
        await txn.execute('users', 'UPDATE users SET name = "New Name"');
        return true;
      });

      await expectation;
    });

    test('Transaction rollback does NOT update UI with temp data', () async {
      final mockDb = MockDatabaseSpy();
      DatabaseManager().setDatabase(mockDb);

      mockDb.setMockData({
        'FROM "users"': [{'id': 1, 'name': 'Old Name'}],
      });

      final stream = User().query().watch();
      final history = <String>[];

      final subscription = stream.listen((users) {
        if (users.isNotEmpty) {
          history.add(users.first.attributes['name']);
        }
      });

      await Future.delayed(Duration.zero);

      try {
        await DatabaseManager().transaction((txn) async {
          mockDb.setMockData({
            'FROM "users"': [{'id': 1, 'name': 'Temporary Name'}],
          });

          await txn.execute('users', 'UPDATE users SET name = "Temporary Name"');

          throw Exception('Rollback Trigger');
        });
      } catch (e) {
        // Expected
      }

      mockDb.setMockData({
        'FROM "users"': [{'id': 1, 'name': 'Old Name'}],
      });

      await Future.delayed(Duration.zero);
      await subscription.cancel();

      expect(history, isNot(contains('Temporary Name')),
          reason: 'UI should never see uncommitted data');
      expect(history.first, 'Old Name');
    });
  });
}