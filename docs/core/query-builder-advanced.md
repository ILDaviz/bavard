# Advanced Queries

## Nested Where Clauses (Parameter Grouping)

For complex logical conditions mixing `AND` and `OR`, you can group constraints using `whereGroup` or `orWhereGroup`. This creates a nested closure that wraps the constraints in parentheses.

```dart
// Generates: SELECT * FROM users WHERE name = 'Mario' OR (votes > 100 AND title <> 'Admin')
await User().query()
    .where('name', 'Mario')
    .orWhereGroup((query) {
        query.where('votes', 100, operator: '>')
             .where('title', 'Admin', operator: '<>');
    })
    .get();
```

## Joins

The query builder allows you to write `JOIN` clauses.

### Inner Join

```dart
await User().query()
    .join('contacts', 'users.id', '=', 'contacts.user_id')
    .join('orders', 'users.id', '=', 'orders.user_id')
    .select(['users.*', 'contacts.phone', 'orders.price'])
    .get();
```

### Left Join / Right Join

```dart
.leftJoin('posts', 'users.id', '=', 'posts.user_id')
.rightJoin('posts', 'users.id', '=', 'posts.user_id')
```

## Group By and Having

### Group By

```dart
await User().query()
    .groupBy(['account_id', 'status'])
    .get();
```

### Having

The `having` method works similarly to `where` but filters the results after grouping.

```dart
await User().query()
    .groupBy(['account_id'])
    .having('account_id', 100, operator: '>')
    .get();
```

### Having Raw

For complex expressions in the `HAVING` clause:

```dart
await User().query()
    .groupBy(['account_id'])
    .havingRaw('SUM(price) > ?', bindings: [2500])
    .get();
```

## Raw Expressions

Sometimes you may need to use a raw expression in a query. These expressions will be injected into the query as strings, so be careful not to create SQL injection vulnerabilities.

### whereRaw / orWhereRaw

```dart
await User().query()
    .whereRaw('price > IF(state = "TX", ?, 100)', bindings: [200])
    .get();
```

## Debugging

You can inspect the generated SQL for debugging purposes.

```dart
// Get the SQL string with placeholders (?)
final sql = User().query().where('id', 1).toSql();

// Get the SQL with bindings substituted (WARNING: For debugging only!)
final rawSql = User().query().where('id', 1).toRawSql();

// Print SQL to console
User().query().where('id', 1).printQueryAndBindings();
```
