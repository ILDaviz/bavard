import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';
import '../mocks/moke_database.dart';

class WatchUser extends Model {
  @override
  String get table => 'users';

  WatchUser([super.attributes]);

  @override
  WatchUser fromMap(Map<String, dynamic> map) => WatchUser(map);
}

class StreamingMockDatabase extends MockDatabaseSpy {
  final StreamController<List<Map<String, dynamic>>> _controller =
  StreamController.broadcast();

  StreamingMockDatabase() : super();

  void emit(List<Map<String, dynamic>> data) {
    _controller.add(data);
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
      String sql, {
        List<dynamic>? parameters,
      }) {
    lastSql = sql;
    lastArgs = parameters;
    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Watch/Stream Tests', () {
    test('watch() returns stream of typed models', () async {
      final mockDb = MockDatabaseSpy([
        {'id': 1, 'name': 'David'},
        {'id': 2, 'name': 'Romolo'},
      ]);
      DatabaseManager().setDatabase(mockDb);

      final stream = WatchUser().query().watch();

      expect(stream, isA<Stream<List<WatchUser>>>());
    });

    test('watch() applies where clauses', () async {
      final mockDb = MockDatabaseSpy([]);
      DatabaseManager().setDatabase(mockDb);

      final query = WatchUser().query().where('active', 1);
      final sql = query.toSql();

      expect(sql, contains('WHERE active = ?'));
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

    test('watch() stream emits on data change', () async {
      final streamingDb = StreamingMockDatabase();
      DatabaseManager().setDatabase(streamingDb);

      final stream = WatchUser().query().watch();
      final results = <List<WatchUser>>[];

      final subscription = stream.listen((users) {
        results.add(users);
      });

      // Emit first batch
      streamingDb.emit([
        {'id': 1, 'name': 'David'}
      ]);

      await Future.delayed(const Duration(milliseconds: 50));

      // Emit second batch
      streamingDb.emit([
        {'id': 1, 'name': 'David'},
        {'id': 2, 'name': 'Romolo'}
      ]);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(results.length, 2);
      expect(results[0].length, 1);
      expect(results[1].length, 2);

      await subscription.cancel();
      streamingDb.dispose();
    });

    test('watch() can be cancelled', () async {
      final streamingDb = StreamingMockDatabase();
      DatabaseManager().setDatabase(streamingDb);

      final stream = WatchUser().query().watch();
      var emitCount = 0;

      final subscription = stream.listen((_) {
        emitCount++;
      });

      streamingDb.emit([
        {'id': 1}
      ]);
      await Future.delayed(const Duration(milliseconds: 10));

      await subscription.cancel();

      streamingDb.emit([
        {'id': 2}
      ]); // Should not be received
      await Future.delayed(const Duration(milliseconds: 10));

      expect(emitCount, 1);
      streamingDb.dispose();
    });
  });
}