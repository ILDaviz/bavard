import 'dart:async';
import 'package:test/test.dart';
import 'package:bavard/bavard.dart';

class MockDatabaseAdapter implements DatabaseAdapter {
  final List<Map<String, dynamic>> _mockData;

  MockDatabaseAdapter(this._mockData);

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    if (sql.contains('FROM users')) {
      return _mockData;
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> get(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    if (sql.contains('last_insert_row_id')) {
      return {'id': 1};
    }
    return _mockData.first;
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? arguments]) async {
    return 1;
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<dynamic>? parameters,
  }) {
    return Stream.value(_mockData);
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    return 1;
  }

  @override
  bool get supportsTransactions => true;

  @override
  Future<T> transaction<T>(
    Future<T> Function(TransactionContext txn) callback,
  ) async {
    final context = _MockTransactionContext(this);
    return await callback(context);
  }
}

class _MockTransactionContext implements TransactionContext {
  final MockDatabaseAdapter _adapter;

  _MockTransactionContext(this._adapter);

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<dynamic>? arguments,
  ]) {
    return _adapter.getAll(sql, arguments);
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]) {
    return _adapter.get(sql, arguments);
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? arguments]) {
    return _adapter.execute(sql, arguments);
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) {
    return _adapter.insert(table, values);
  }
}

class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

void main() {
  setUp(() {
    final mockDb = MockDatabaseAdapter([
      {'id': 1, 'name': 'David', 'role': 'Admin'},
      {'id': 2, 'name': 'Romolo', 'role': 'Admin'},
    ]);
    DatabaseManager().setDatabase(mockDb);
  });

  group('ActiveSync Core Tests', () {
    test('It creates and hydrates typed models from query', () async {
      final List<User> users = await User().query().get();

      expect(users.length, 2);
      expect(users.first, isA<User>());
      expect(users.first.attributes['name'], 'David');
      expect(users.last.attributes['role'], 'Admin');
    });

    test('It manages dirty attributes correctly', () async {
      final user = User({'id': 1, 'name': 'David', 'email': 'old@test.com'});
      user.syncOriginal();

      expect(user.original['email'], 'old@test.com');

      user.attributes['email'] = 'new@test.com';

      final dirtyMap = <String, dynamic>{};
      user.attributes.forEach((key, value) {
        if (value != user.original[key]) {
          dirtyMap[key] = value;
        }
      });

      expect(dirtyMap.containsKey('email'), true);
      expect(dirtyMap.containsKey('name'), false);
    });
  });
}
