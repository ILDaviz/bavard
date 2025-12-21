# Implementing a Database Adapter

Bavard is designed to be database-agnostic. To use it with a specific database (SQLite, Postgres, etc.) or package (sqflite, drift, powersync), you must implement the `DatabaseAdapter` interface.

## The Interface

```dart
abstract class DatabaseAdapter {
  Future<List<Map<String, dynamic>>> getAll(String sql, [List<dynamic>? arguments]);
  
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]);
  
  Future<int> execute(String sql, [List<dynamic>? arguments]);
  
  Future<dynamic> insert(String table, Map<String, dynamic> values);
  
  Stream<List<Map<String, dynamic>>> watch(String sql, {List<dynamic>? parameters});
  
  bool get supportsTransactions;
  
  Future<T> transaction<T>(Future<T> Function(TransactionContext txn) callback);
}
```

## Transaction Support

If your database supports transactions, `supportsTransactions` should return `true`. The `transaction` method must create a `TransactionContext` (which mimics the `DatabaseAdapter` interface) and pass it to the callback.

## Watch Support

For reactive apps (Flutter), the `watch` method should return a Stream that emits a new list of results whenever the underlying table changes. If your driver doesn't support this, you can return a simple `Stream.value()` (though the UI won't auto-update).
