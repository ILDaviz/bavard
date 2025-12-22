# Implementing a Database Adapter

Bavard is designed to be database-agnostic. To use it with a specific database (SQLite, Postgres, etc.) or package (sqflite, drift, powersync), you must implement the `DatabaseAdapter` interface.

## The Interface

```dart
abstract class DatabaseAdapter {
  /// Returns the Grammar strategy used to compile queries for this adapter.
  Grammar get grammar;

  Future<List<Map<String, dynamic>>> getAll(String sql, [List<dynamic>? arguments]);
  
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]);
  
  Future<int> execute(String sql, [List<dynamic>? arguments]);
  
  Future<dynamic> insert(String table, Map<String, dynamic> values);
  
  Stream<List<Map<String, dynamic>>> watch(String sql, {List<dynamic>? parameters});
  
  bool get supportsTransactions;
  
  Future<T> transaction<T>(Future<T> Function(TransactionContext txn) callback);
}
```

## SQL Grammar (Dialects)

Bavard uses the **Strategy Pattern** to handle SQL dialect differences (e.g., parameter placeholders like `?` vs `$1`, quoting identifiers, etc.). Your adapter must provide a concrete `Grammar` implementation.

Bavard includes built-in grammars:
- `SQLiteGrammar`: For SQLite databases (uses `?` placeholders, double-quote identifiers).
- `PostgresGrammar`: For PostgreSQL (can be extended for `$1` placeholders if needed).

### Using a Built-in Grammar

```dart
class MySqliteAdapter implements DatabaseAdapter {
  @override
  Grammar get grammar => SQLiteGrammar();
  
  // ... implementation
}
```

### Creating a Custom Grammar

If you need to support a different SQL dialect (e.g., MySQL, SQL Server), extend the `Grammar` class:

```dart
class MyCustomGrammar extends Grammar {
  @override
  String wrap(String value) {
    // Custom quoting logic (e.g., backticks for MySQL)
    return '`$value`';
  }

  @override
  String parameter(dynamic value) {
    return '?';
  }
  
  // Override compileSelect, compileInsert, etc. if the syntax differs significantly.
}
```

## Transaction Support

If your database supports transactions, `supportsTransactions` should return `true`. The `transaction` method must create a `TransactionContext` (which mimics the `DatabaseAdapter` interface) and pass it to the callback.

## Watch Support

For reactive apps (Flutter), the `watch` method should return a Stream that emits a new list of results whenever the underlying table changes. If your driver doesn't support this, you can return a simple `Stream.value()` (though the UI won't auto-update).
