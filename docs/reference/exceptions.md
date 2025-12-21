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
