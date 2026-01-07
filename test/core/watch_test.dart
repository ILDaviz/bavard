import 'dart:async';
import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class WatchUser extends Model {
  @override
  String get table => 'users';

  WatchUser([super.attributes]);

  @override
  WatchUser fromMap(Map<String, dynamic> map) => WatchUser(map);
}

void main() {
  group('Watch/Stream Tests', () {
    test('watch() applies where clauses', () async {
      final mockDb = MockDatabaseSpy([]);
      DatabaseManager().setDatabase(mockDb);

      final query = WatchUser().query().where('active', 1);

      expect(query.toSql(), contains('WHERE "active" = ?'));
    });

    test('watch() hydrates models correctly', () async {
      final mockDb = MockDatabaseSpy([
        {'id': 1, 'name': 'David'},
      ]);
      DatabaseManager().setDatabase(mockDb);

      final stream = WatchUser().query().watch();
      final users = await stream.first;

      expect(users.first, isA<WatchUser>());
      expect(users.first.attributes['name'], 'David');
      expect(users.first.exists, isTrue);
    });

    test(
      'watch() returns stream of typed models and emits initial data',
      () async {
        final mockDb = MockDatabaseSpy([
          {'id': 1, 'name': 'David'},
        ]);
        DatabaseManager().setDatabase(mockDb);

        final stream = WatchUser().query().watch();

        expect(stream, isA<Stream<List<WatchUser>>>());

        final users = await stream.first;
        expect(users.length, 1);
        expect(users.first.attributes['name'], 'David');
      },
    );

    test('watch() stream emits new data when table changes', () async {
      final mockDb = MockDatabaseSpy();
      DatabaseManager().setDatabase(mockDb);

      mockDb.setMockData({
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
      });

      final stream = WatchUser().query().watch();

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isA<List<WatchUser>>().having((l) => l.length, 'initial length', 1),
          isA<List<WatchUser>>()
              .having((l) => l.length, 'updated length', 2)
              .having((l) => l.last.attributes['name'], 'last name', 'Romolo'),
        ]),
      );

      await Future.delayed(Duration.zero);

      mockDb.setMockData({
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
          {'id': 2, 'name': 'Romolo'},
        ],
      });

      await DatabaseManager().execute(
        'users',
        'UPDATE users SET name = "changed"',
      );

      await expectation;
    });

    test('watch() does not emit for other tables', () async {
      final mockDb = MockDatabaseSpy();
      DatabaseManager().setDatabase(mockDb);

      mockDb.setMockData({
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
      });

      final stream = WatchUser().query().watch();
      int emitCount = 0;
      stream.listen((_) => emitCount++);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitCount, 1);

      await DatabaseManager().execute(
        'other_table',
        'UPDATE other_table SET x = 1',
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitCount, 1, reason: 'Should not emit for other table changes');
    });

    test('watch() can be cancelled', () async {
      final mockDb = MockDatabaseSpy();
      DatabaseManager().setDatabase(mockDb);

      final stream = WatchUser().query().watch();
      int emitCount = 0;
      final subscription = stream.listen((_) => emitCount++);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitCount, 1);

      await subscription.cancel();

      await DatabaseManager().execute('users', 'DELETE FROM users');

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitCount, 1);
    });
  });
}
