# Database Adapters

Bavard is designed to be purely agnostic regarding the underlying database driver. This ensures the core package remains lightweight and free of unnecessary dependencies.

To connect Bavard to a database, you must implement the `DatabaseAdapter` interface.

## Grammars & Dialects

Since Bavard supports multiple SQL dialects, your adapter must specify which **Grammar** it uses to generate SQL.

- **SQLiteGrammar**: For SQLite, PowerSync, Drift, and sqflite.
- **PostgresGrammar**: For PostgreSQL, Supabase, and other Postgres-compatible drivers.

The `DatabaseAdapter` interface requires you to implement the `grammar` getter:

```dart
@override
Grammar get grammar => SQLiteGrammar(); // or PostgresGrammar()
```

## Implementing `DatabaseAdapter`

The `DatabaseAdapter` interface is straightforward. You only need to implement methods for executing SQL queries and managing transactions.

::: tip Automatic Reactivity
You do **not** need to implement any logic for `watch()` or change notifications. 
Bavard's core `DatabaseManager` automatically handles table change tracking and stream updates by wrapping your adapter's `execute` and `insert` calls.
:::

### Key Methods

- **`getAll(sql, [args])`**: Returns a list of rows (`List<Map<String, dynamic>>`).
- **`get(sql, [args])`**: Returns a single row (`Map<String, dynamic>`).
- **`execute(table, sql, [args])`**: Executes an UPDATE/DELETE command and returns the number of affected rows. **Note:** The `table` argument is used by the core for change tracking.
- **`insert(table, values)`**: Inserts a row and returns the new ID (or primary key).
- **`transaction(callback)`**: Executes a callback within a database transaction.

### Transactions

The `transaction` method receives a callback that provides a `TransactionContext`. This context has the same API as the adapter (`get`, `getAll`, `execute`, `insert`) but operates inside the transaction.

Your adapter is responsible for:
1. Starting the transaction (e.g., `BEGIN`).
2. Creating a context that executes queries on that transaction.
3. Committing or Rolling back based on whether the callback throws an error.

Bavard automatically handles buffering notifications during transactions, so you don't need to worry about dirty reads in your streams.

Below are the **reference implementations** for the most common use cases. You can copy these files directly into your project.


## SQLite (via `package:sqlite3`)

Best for: **Dart Desktop / Mobile (FFI)**.


**Dependencies:**
- `bavard`
- `sqlite3`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/src/grammars/sqlite_grammar.dart';
import 'package:bavard/schema.dart';

class SqliteAdapter implements DatabaseAdapter {
  final Database _db;

  SqliteAdapter(this._db);

  @override
  Grammar get grammar => SQLiteGrammar();

  List<dynamic> _sanitize(List<dynamic> args) {
    return args.map((arg) {
      if (arg is DateTime) return arg.toIso8601String();
      if (arg is bool) return arg ? 1 : 0;
      if (arg is Map || arg is List) return jsonEncode(arg);

      return arg;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List<dynamic>? arguments]) async {
    final result = _db.select(sql, _sanitize(arguments ?? []));
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]) async {
    final result = await getAll(sql, arguments);
    if (result.isEmpty) return {};
    return result.first;
  }

  @override
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    _db.execute(sql, _sanitize(arguments ?? []));
    return _db.getUpdatedRows();
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders)';

    _db.execute(sql, _sanitize(values.values.toList()));
    return _db.lastInsertRowId;
  }

  @override
  bool get supportsTransactions => true;

  @override
  Future<T> transaction<T>(Future<T> Function(TransactionContext txn) callback) async {
    _db.execute('BEGIN TRANSACTION');
    try {
      final txnContext = _SqliteTransactionContext(_db, _sanitize);
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
  final List<dynamic> Function(List<dynamic>) _sanitize;

  _SqliteTransactionContext(this._db, this._sanitize);

  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List? arguments]) async {
    final result = _db.select(sql, _sanitize(arguments ?? []));
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List? arguments]) async {
    final list = await getAll(sql, arguments);
    return list.isNotEmpty ? list.first : {};
  }

  @override
  Future<int> execute(String table, String sql, [List? arguments]) async {
    _db.execute(sql, _sanitize(arguments ?? []));
    return _db.getUpdatedRows();
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders)';
    _db.execute(sql, _sanitize(values.values.toList()));
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
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    return db.writeTransaction((tx) async {
      final context = _PowerSyncTransactionContext(tx);
      return context.execute(table, sql, arguments);
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
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) =>
    _executeInternal(sql, arguments);

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) =>
    _insertInternal(table, values);
}
```
