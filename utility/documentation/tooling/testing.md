# Testing

Bavard provides a `MockDatabaseSpy` for testing your models without a real database connection.

## Setup

Import the testing library:

```dart
import 'package:bavard/testing.dart';
import 'package:test/test.dart';
```

## Mocking the Database

In your `setUp` function, initialize the spy and register it.

```dart
late MockDatabaseSpy dbSpy;

setUp(() {
  dbSpy = MockDatabaseSpy();
  DatabaseManager().setDatabase(dbSpy);
});
```

## Verifying Queries

You can check `dbSpy.history` or `dbSpy.lastSql` to verify that your code executed the expected SQL.

```dart
test('creates a user', () async {
  final user = User({'name': 'David'});
  await user.save();

  expect(dbSpy.lastSql, contains('INSERT INTO users'));
  expect(dbSpy.lastArgs, contains('David'));
});
```

## Mocking Responses

You can configure what data the spy returns.

```dart
// Default response for all queries
dbSpy = MockDatabaseSpy([
  {'id': 1, 'name': 'Default'}
]);

// Smart responses based on SQL matching
dbSpy = MockDatabaseSpy([], {
  'FROM users': [{'id': 1, 'name': 'Mario'}],
  'FROM posts': [{'id': 10, 'title': 'Test Post'}],
});
```

## Testing Transactions

The spy also tracks transaction boundaries.

```dart
expect(dbSpy.history, contains('BEGIN TRANSACTION'));
expect(dbSpy.history, contains('COMMIT'));
```
