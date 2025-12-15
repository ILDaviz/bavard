import 'database_adapter.dart';
import 'exceptions.dart';

/// Singleton service locator for the active database connection.
///
/// Decouples the application logic from specific database drivers, allowing
/// the active adapter to be injected at runtime (Service Locator pattern).
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();

  DatabaseAdapter? _db;

  /// Tracks the current transaction context for nested operations.
  TransactionContext? _activeTransaction;

  factory DatabaseManager() => _instance;

  DatabaseManager._internal();

  /// Dependency injection entry point.
  ///
  /// Must be invoked during app initialization (e.g., in `main()`) prior
  /// to any model operations.
  void setDatabase(DatabaseAdapter db) {
    _db = db;
  }

  /// Fail-fast accessor for the active driver.
  ///
  /// Throws [DatabaseNotInitializedException] if [setDatabase] was not called.
  DatabaseAdapter get db {
    if (_db == null) {
      throw const DatabaseNotInitializedException();
    }
    return _db!;
  }

  /// Returns the active transaction context if within a transaction, null otherwise.
  TransactionContext? get activeTransaction => _activeTransaction;

  /// Indicates whether code is currently executing within a transaction.
  bool get inTransaction => _activeTransaction != null;

  // ---------------------------------------------------------------------------
  // TRANSACTION API
  // ---------------------------------------------------------------------------

  /// Executes [callback] within a database transaction.
  ///
  /// Automatically rolls back on exception and commits on success.
  /// Supports nested transactions via the adapter's implementation.
  ///
  /// Throws [TransactionException] if the transaction fails.
  ///
  /// Example:
  /// ```dart
  /// await DatabaseManager().transaction((txn) async {
  ///   final user = User({'name': 'David'});
  ///   await user.save(); // Uses the active transaction
  ///
  ///   final profile = Profile({'user_id': user.id});
  ///   await profile.save();
  ///
  ///   return user;
  /// });
  /// ```
  Future<T> transaction<T>(
      Future<T> Function(TransactionContext txn) callback,
      ) async {
    if (!db.supportsTransactions) {
      throw const TransactionException(
        message: 'The current database adapter does not support transactions.',
        wasRolledBack: false,
      );
    }

    try {
      return await db.transaction<T>((txn) async {
        // Store the transaction context for Model operations
        final previousTransaction = _activeTransaction;
        _activeTransaction = txn;

        try {
          final result = await callback(txn);
          return result;
        } finally {
          // Restore the previous transaction context (for nested transactions)
          _activeTransaction = previousTransaction;
        }
      });
    } catch (e) {
      if (e is TransactionException) rethrow;

      throw TransactionException(
        message: 'Transaction failed: ${e.toString()}',
        wasRolledBack: true,
        originalError: e,
      );
    }
  }

  /// Executes SQL using the active transaction if available, otherwise uses the main connection.
  ///
  /// This is the primary method Model operations should use to ensure
  /// they participate in active transactions.
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    if (_activeTransaction != null) {
      await _activeTransaction!.execute(sql, arguments);
    } else {
      await db.execute(sql, arguments);
    }
  }

  /// Fetches all results using the active transaction if available.
  Future<List<Map<String, dynamic>>> getAll(
      String sql, [
        List<dynamic>? arguments,
      ]) async {
    if (_activeTransaction != null) {
      return await _activeTransaction!.getAll(sql, arguments);
    }
    return await db.getAll(sql, arguments);
  }

  /// Fetches a single result using the active transaction if available.
  Future<Map<String, dynamic>> get(
      String sql, [
        List<dynamic>? arguments,
      ]) async {
    if (_activeTransaction != null) {
      return await _activeTransaction!.get(sql, arguments);
    }
    return await db.get(sql, arguments);
  }

  /// Inserts a record using the active transaction if available.
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    if (_activeTransaction != null) {
      return await _activeTransaction!.insert(table, values);
    }
    return await db.insert(table, values);
  }
}