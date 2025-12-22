# Database Adapters

Bavard is designed to be purely agnostic regarding the underlying database driver. This ensures the core package remains lightweight and free of unnecessary dependencies.

To connect Bavard to a database, you must implement the `DatabaseAdapter` interface.

Below are the **reference implementations** for the most common use cases. You can copy these files directly into your project.

## SQLite (via `package:sqlite3`)

Best for: **Dart Desktop / Mobile (FFI)**.

**Dependencies:**
- `bavard`
- `sqlite3`

```dart
import 'dart:async';
import 'package:bavard/bavard.dart';
import 'package:bavard/src/grammars/sqlite_grammar.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteAdapter implements DatabaseAdapter {
  final Database _db;

  SqliteAdapter(this._db);

  @override
  Grammar get grammar => SqliteGrammar();

  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List<dynamic>? arguments]) async {
    final result = _db.select(sql, arguments ?? []);
    // Convert Row objects to Map<String, dynamic>
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]) async {
    final result = await getAll(sql, arguments);
    if (result.isEmpty) return {};
    return result.first;
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? arguments]) async {
    _db.execute(sql, arguments ?? []);
    return _db.getUpdatedRows(); // Return number of affected rows
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    // Generate standard INSERT statement
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders)';
    
    _db.execute(sql, values.values.toList());
    return _db.lastInsertRowId;
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(String sql, {List<dynamic>? parameters}) {
    // NOTE: package:sqlite3 does not support reactive streams out of the box.
    // For reactive apps, consider using 'drift' or creating a custom stream controller.
    // This is a basic non-reactive fallback.
    return Stream.fromFuture(getAll(sql, parameters));
  }
  
  @override
  bool get supportsTransactions => true;

  @override
  Future<T> transaction<T>(Future<T> Function(TransactionContext txn) callback) async {
    // Basic transaction handling
    _db.execute('BEGIN TRANSACTION');
    try {
      final txnContext = _SqliteTransactionContext(_db);
      final result = await callback(txnContext);
      _db.execute('COMMIT');
      return result;
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}

class _SqliteTransactionContext implements TransactionContext {
  final Database _db;
  _SqliteTransactionContext(this._db);

  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List? arguments]) async {
    final result = _db.select(sql, arguments ?? []);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List? arguments]) async {
    final list = await getAll(sql, arguments);
    return list.isNotEmpty ? list.first : {};
  }

  @override
  Future<int> execute(String sql, [List? arguments]) async {
    _db.execute(sql, arguments ?? []);
    return _db.getUpdatedRows();
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders)';
    _db.execute(sql, values.values.toList());
    return _db.lastInsertRowId;
  }
}
```

---

## PowerSync

Best for: **Offline-First Flutter Apps**.

Bavard is the perfect ORM for PowerSync because it handles query generation while letting PowerSync handle the complex synchronization logic.

**Dependencies:**
- `bavard`
- `powersync`
- `sqlite_async`

```dart
import 'dart:async';
import 'package:bavard/bavard.dart';
import 'package:powersync/powersync.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite_async/sqlite_async.dart';

mixin _PowerSyncExecutor {
  Future<ResultSet> executeRaw(String sql, [List<dynamic>? arguments]);

  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
      List<dynamic>? arguments,
    ]) async {
    final result = await executeRaw(sql, arguments ?? []);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>> get(
    String sql, [
      List<dynamic>? arguments,
    ]) async {
    final rows = await getAll(sql, arguments);
    return rows.isNotEmpty ? rows.first : {};
  }

  Future<int> _executeInternal(String sql, [List<dynamic>? arguments]) async {
    await executeRaw(sql, arguments ?? []);
    final result = await executeRaw('SELECT changes() as affected');
    return result.first['affected'] as int;
  }

  Future<dynamic> _insertInternal(String table, Map<String, dynamic> values) async {
    if (values.keys.any((k) => !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(k))) {
      throw ArgumentError('Invalid column name in insert values');
    }

    final keys = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO $table ($keys) VALUES ($placeholders)';

    await executeRaw(sql, values.values.toList());

    if (values['id'] != null) {
      return values['id'];
    }

    final result = await executeRaw('SELECT last_insert_rowid() as id');
    return result.first['id'];
  }
}

class PowerSyncDatabaseAdapter with _PowerSyncExecutor implements DatabaseAdapter {
  final PowerSyncDatabase db;

  PowerSyncDatabaseAdapter(this.db);

  @override
  Future<ResultSet> executeRaw(String sql, [List<dynamic>? arguments]) =>
    db.execute(sql, arguments ?? []);

  @override
  Grammar get grammar => SQLiteGrammar();

  @override
  Future<int> execute(String sql, [List<dynamic>? arguments]) async {
    return db.writeTransaction((tx) async {
      final context = _PowerSyncTransactionContext(tx);
      return context.execute(sql, arguments);
    });
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    return db.writeTransaction((tx) async {
      final context = _PowerSyncTransactionContext(tx);
      return context.insert(table, values);
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
      List<dynamic>? parameters,
    }) {
    return db.watch(sql, parameters: parameters ?? []).map(
        (rows) => rows.map((r) => Map<String, dynamic>.from(r)).toList(),
    );
  }

  @override
  bool get supportsTransactions => true;

  @override
  Future<T> transaction<T>(
    Future<T> Function(TransactionContext txn) callback,
    ) async {
    return db.writeTransaction((tx) async {
      final context = _PowerSyncTransactionContext(tx);
      return await callback(context);
    });
  }
}

class _PowerSyncTransactionContext with _PowerSyncExecutor implements TransactionContext {
  final SqliteWriteContext _txn;

  _PowerSyncTransactionContext(this._txn);

  @override
  Future<ResultSet> executeRaw(String sql, [List<dynamic>? arguments]) =>
    _txn.execute(sql, arguments ?? []);

  @override
  Future<int> execute(String sql, [List<dynamic>? arguments]) =>
    _executeInternal(sql, arguments);

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) =>
    _insertInternal(table, values);
}
```
