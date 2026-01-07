import 'dart:async';
import 'package:bavard/bavard.dart';

/// A test double for [DatabaseAdapter] that records query history and allows
/// configuring responses based on SQL substrings.
///
/// Use this to verify that your repository layer generates the expected SQL
/// and correctly handles transaction lifecycles without a real database.
class MockDatabaseSpy implements DatabaseAdapter {
  /// The last executed SQL statement, exposed for test assertions.
  String lastSql = '';
  List<dynamic>? lastArgs;

  /// Full log of all executed SQL statements in chronological order.
  List<String> history = [];

  final List<Map<String, dynamic>> _defaultData;
  Map<String, List<Map<String, dynamic>>> _smartResponses;

  bool _inTransaction = false;

  // Default grammar for testing
  final Grammar _grammar;

  @override
  Grammar get grammar => _grammar;

  /// Captures SQL statements executed specifically within the current transaction scope.
  List<String> transactionHistory = [];

  /// If true, operations within a transaction will throw an exception
  /// to simulate database failures and test rollback logic.
  bool shouldFailTransaction = false;

  /// Creates the spy with optional [defaultData] for unmatched queries and
  /// [smartResponses] mapped by SQL substrings.
  MockDatabaseSpy([
    this._defaultData = const [],
    Map<String, List<Map<String, dynamic>>> smartResponses = const {},
    Grammar? grammar,
  ])  : _smartResponses = Map.from(smartResponses),
        _grammar = grammar ?? SQLiteGrammar();

  /// Updates the mock response configuration at runtime.
  void setMockData(Map<String, List<Map<String, dynamic>>> data) {
    _smartResponses.clear();
    _smartResponses.addAll(data);
  }

  String _normalize(String sql) => sql.replaceAll('"', '');

  /// Logs the query and returns pre-configured data if [sql] contains a key
  /// defined in [_smartResponses]; otherwise returns [_defaultData].
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

    final normalized = _normalize(sql);
    for (var key in _smartResponses.keys) {
      if (normalized.contains(key)) {
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
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    lastSql = sql;
    lastArgs = arguments;
    history.add(sql);

    if (_inTransaction) {
      transactionHistory.add(sql);

      if (shouldFailTransaction) {
        throw Exception('Simulated transaction failure');
      }

      return 1;
    }
    return 1;
  }

  /// Returns a static stream of [_defaultData].
  ///
  /// Does not simulate actual database updates or reactive stream behavior.
  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final keys = values.keys.map(grammar.wrap).join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO ${grammar.wrap(table)} ($keys) VALUES ($placeholders)';

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

  /// Executes a transaction scope.
  ///
  /// Manages `_inTransaction` state and logs lifecycle events (`BEGIN`, `COMMIT`, `ROLLBACK`)
  /// to [history] to verify transaction boundaries.
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

/// A pass-through wrapper ensuring that operations inside a transaction block
/// are routed back to the main [MockDatabaseSpy] instance.
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
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) {
    return _db.execute(table, sql, arguments);
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) {
    return _db.insert(table, values);
  }
}
