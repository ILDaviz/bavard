# Debugging

When working with an ORM, it's often helpful to see the actual SQL being executed.

## Inspecting Queries

The `QueryBuilder` has methods to output SQL.

```dart
// Get SQL string with ? placeholders
print(User().query().where('active', 1).toSql());

// Get SQL with bindings substituted (approximate)
print(User().query().where('active', 1).toRawSql());
```

> **Warning:** `toRawSql()` is for debugging purposes only. Do not use its output for execution, as it may not strictly adhere to driver escaping rules.

## Chained Debugging

You can inject print statements into the chain:

```dart
await User().query()
    .where('status', 'active')
    .printQueryAndBindings() // Prints SQL and List of bindings
    .get();
```

## Print and Die

To halt execution and print the SQL:

```dart
User().query().where('id', 1).printAndDieRawSql();
```
