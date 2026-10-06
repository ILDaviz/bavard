# Error Handling

Bavard throws specific exceptions that you can catch to handle errors gracefully. All exceptions extend `BavardException`.

## Common Exceptions

| Exception | Description |
|-----------|-------------|
| `ModelNotFoundException` | Thrown by `findOrFail()` or `firstOrFail()` when no record exists. |
| `QueryException` | Thrown when a database query fails (syntax error, constraint violation). |
| `TransactionException` | Thrown when a transaction fails or is rolled back. |
| `InvalidQueryException` | Thrown when query construction is invalid (e.g., bad operator). |
| `MassAssignmentException` | Thrown when trying to mass-assign a guarded attribute (if configured). |
| `RelationNotFoundException` | Thrown when accessing an undefined relationship. |
| `DatabaseNotInitializedException` | Thrown if `DatabaseManager` is used before setup. |

## Debugging with Stack Traces

All `BavardException` classes include an optional `stackTrace` property that preserves the original stack trace of the error. This is particularly useful for debugging `TransactionException` or `QueryException` where the error might originate deep within the database driver.

```dart
try {
  await DatabaseManager().transaction((txn) async {
    // ... complex logic that might fail ...
  });
} on TransactionException catch (e) {
  print('Transaction failed: ${e.message}');
  
  // Access the original stack trace to find the root cause
  if (e.stackTrace != null) {
    print(e.stackTrace);
  }
}
```

## Example

```dart
try {
  final user = await User().query().findOrFail(999);
} on ModelNotFoundException catch (e) {
  print('User not found: ${e.message}');
} on QueryException catch (e) {
  print('Database error: ${e.message}');
  print('SQL: ${e.sql}');
}
```
