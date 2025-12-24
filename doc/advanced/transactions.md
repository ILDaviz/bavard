# Transactions

Bavard's database operations can be executed within a transaction to ensure data integrity.

## Using Transactions

Use the `DatabaseManager().transaction` method.

```dart
await DatabaseManager().transaction((txn) async {
  final user = User();
  user.name = 'Mario';
  await user.save(); // Uses the transaction automatically

  final profile = Profile();
  profile.userId = user.id;
  await profile.save();

  // If an exception is thrown here, both User and Profile inserts are rolled back.
  throw Exception('Something went wrong');
});
```

## Transaction Context

The transaction callback receives a `TransactionContext` (`txn`). If you are using raw SQL queries within the transaction, use this context:

```dart
await DatabaseManager().transaction((txn) async {
  await txn.execute('INSERT INTO logs ...');
});
```

However, `Model` operations (`save`, `delete`, `query`) automatically detect the active transaction on the `DatabaseManager`, so you don't need to pass the context explicitly to them.
