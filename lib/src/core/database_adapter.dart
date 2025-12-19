/// Protocol for database drivers.
///
/// Abstraction layer that decouples the ORM from specific SQL dialects (SQLite, Postgres)
/// or underlying packages (sqflite, drift).
abstract class DatabaseAdapter {
  /// Executes a SELECT query.
  ///
  /// Implementations MUST support variable binding in [arguments] to prevent SQL injection.
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<dynamic>? arguments,
  ]);

  /// Executes non-selecting commands (UPDATE, DELETE) or schema changes (DDL).
  Future<int> execute(String sql, [List<dynamic>? arguments]);

  /// Convenience wrapper to fetch the first result of a query.
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]);

  /// Inserts a record and returns the auto-generated primary key (if applicable).
  Future<dynamic> insert(String table, Map<String, dynamic> values);

  /// Exposes a reactive stream of query results.
  ///
  /// Critical for Flutter integration: implementations should emit a new event
  /// whenever the data targeted by [sql] is modified, triggering UI rebuilds.
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<dynamic>? parameters,
  });

  // ---------------------------------------------------------------------------
  // TRANSACTION SUPPORT
  // ---------------------------------------------------------------------------

  /// Executes a callback within a database transaction.
  ///
  /// If [callback] throws an exception, the transaction MUST be rolled back.
  /// If [callback] completes successfully, the transaction MUST be committed.
  ///
  /// Implementations should support nested transactions via savepoints where available.
  ///
  /// Returns the result of [callback].
  ///
  /// Example:
  /// ```dart
  /// final result = await db.transaction((txn) async {
  ///   await txn.execute('INSERT INTO users (name) VALUES (?)', ['David']);
  ///   await txn.execute('INSERT INTO profiles (user_id) VALUES (?)', [1]);
  ///   return 'success';
  /// });
  /// ```
  Future<T> transaction<T>(Future<T> Function(TransactionContext txn) callback);

  /// Indicates whether the adapter supports transactions.
  ///
  /// Some adapters (e.g., in-memory mocks) may not support transactions.
  /// Use this to conditionally enable transactional features.
  bool get supportsTransactions => true;
}

/// Context object passed to transaction callbacks.
///
/// Provides the same API as [DatabaseAdapter] but executes within the
/// transaction boundary. Implementations should ensure all operations
/// through this context participate in the active transaction.
abstract class TransactionContext {
  /// Executes a SELECT query within the transaction.
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<dynamic>? arguments,
  ]);

  /// Executes non-selecting commands within the transaction.
  Future<int> execute(String sql, [List<dynamic>? arguments]);

  /// Fetches the first result within the transaction.
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]);

  /// Inserts a record within the transaction.
  Future<dynamic> insert(String table, Map<String, dynamic> values);
}
