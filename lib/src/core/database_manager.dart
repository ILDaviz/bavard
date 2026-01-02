import 'dart:async';
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

  /// Broadcasts table names whenever a table is modified (insert, update, delete).
  final _tableChangesController = StreamController<String>.broadcast();

  /// Stream of table names that have been modified.
  Stream<String> get tableChanges => _tableChangesController.stream;

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
        final trackingTxn = _TrackingTransactionContext(txn);
        
        final previousTransaction = _activeTransaction;
        _activeTransaction = trackingTxn;

        try {
          final result = await callback(trackingTxn);
          
          for (final table in trackingTxn.modifiedTables) {
            _tableChangesController.add(table);
          }
          
          return result;
        } finally {
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
  /// Returns the number of rows affected (if supported by the adapter).
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    int result;
    if (_activeTransaction != null) {
      result = await _activeTransaction!.execute(table, sql, arguments);
    } else {
      result = await db.execute(table, sql, arguments);
      _tableChangesController.add(table);
    }
    return result;
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
    dynamic result;
    if (_activeTransaction != null) {
      result = await _activeTransaction!.insert(table, values);
    } else {
      result = await db.insert(table, values);
      _tableChangesController.add(table);
    }
    return result;
  }
}

/// A wrapper around [TransactionContext] that tracks which tables were modified.
///
/// This allows [DatabaseManager] to delay change notifications until the transaction
/// is successfully committed, preventing "dirty reads" by watchers and ensuring
/// UI consistency on rollback.
class _TrackingTransactionContext implements TransactionContext {
  final TransactionContext _inner;
  final Set<String> modifiedTables = {};

  _TrackingTransactionContext(this._inner);

  @override
  Future<int> execute(String table, String sql, [List? arguments]) async {
    final result = await _inner.execute(table, sql, arguments);
    modifiedTables.add(table);
    return result;
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List? arguments]) {
    return _inner.get(sql, arguments);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List? arguments]) {
    return _inner.getAll(sql, arguments);
  }

  @override
  Future insert(String table, Map<String, dynamic> values) async {
    final result = await _inner.insert(table, values);
    modifiedTables.add(table);
    return result;
  }
}
