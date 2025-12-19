import 'dart:async';
import 'package:bavard/bavard.dart';

class MockDatabaseSpy implements DatabaseAdapter {
  String lastSql = '';
  List<dynamic>? lastArgs;

  List<String> history = [];

  final List<Map<String, dynamic>> _defaultData;
  final Map<String, List<Map<String, dynamic>>> _smartResponses;

  /// Tracks whether we're currently in a transaction
  bool _inTransaction = false;

  /// Tracks transaction operations for verification
  List<String> transactionHistory = [];

  /// Whether to simulate transaction failure
  bool shouldFailTransaction = false;

  MockDatabaseSpy([
    this._defaultData = const [],
    this._smartResponses = const {},
  ]);

  @override
  Future<List<Map<String, dynamic>>> getAll(
      String sql, [
        List<dynamic>? arguments,
      ]) async {
    lastSql = sql;
    lastArgs = arguments;
    history.add(sql);

    if (_inTransaction) {
      transactionHistory.add(sql);
    }

    for (var key in _smartResponses.keys) {
      if (sql.contains(key)) {
        return _smartResponses[key]!;
      }
    }

    return _defaultData;
  }

  @override
  Future<Map<String, dynamic>> get(
      String sql, [
        List<dynamic>? arguments,
      ]) async {
    final results = await getAll(sql, arguments);
    return results.isNotEmpty ? results.first : {};
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    lastSql = sql;
    lastArgs = arguments;
    history.add(sql);

    if (_inTransaction) {
      transactionHistory.add(sql);

      if (shouldFailTransaction) {
        throw Exception('Simulated transaction failure');
      }
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
      String sql, {
        List<dynamic>? parameters,
      }) {
    return Stream.value(_defaultData);
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final keys = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO $table ($keys) VALUES ($placeholders)';

    lastSql = sql;
    lastArgs = values.values.toList();
    history.add(sql);

    if (_inTransaction) {
      transactionHistory.add(sql);

      if (shouldFailTransaction) {
        throw Exception('Simulated transaction failure');
      }
    }

    if (_smartResponses.containsKey('last_insert_row_id')) {
      final row = _smartResponses['last_insert_row_id']!.first;
      return row['id'] ?? 1;
    }

    return 1;
  }

  @override
  bool get supportsTransactions => true;

  @override
  Future<T> transaction<T>(
      Future<T> Function(TransactionContext txn) callback,
      ) async {
    _inTransaction = true;
    transactionHistory.clear();
    history.add('BEGIN TRANSACTION');

    try {
      final context = MockTransactionContext(this);
      final result = await callback(context);

      history.add('COMMIT');
      _inTransaction = false;
      return result;
    } catch (e) {
      history.add('ROLLBACK');
      _inTransaction = false;
      rethrow;
    }
  }
}

class MockTransactionContext implements TransactionContext {
  final MockDatabaseSpy _db;

  MockTransactionContext(this._db);

  @override
  Future<List<Map<String, dynamic>>> getAll(
      String sql, [
        List<dynamic>? arguments,
      ]) {
    return _db.getAll(sql, arguments);
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]) {
    return _db.get(sql, arguments);
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? arguments]) {
    return _db.execute(sql, arguments);
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) {
    return _db.insert(table, values);
  }
}