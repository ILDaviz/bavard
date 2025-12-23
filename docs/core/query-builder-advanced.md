# Advanced Queries

## Nested Where Clauses (Parameter Grouping)

For complex logical conditions mixing `AND` and `OR`, you can group constraints using `whereGroup` or `orWhereGroup`. This creates a nested closure that wraps the constraints in parentheses.

```dart
// Generates: SELECT * FROM users WHERE name = 'Mario' OR (votes > 100 AND title <> 'Admin')
await User().query()
    .where('name', 'Mario')
    .orWhereGroup((query) {
        query.where('votes', 100, '>')
             .where('title', 'Admin', '<>');
    })
    .get();
```

## Where Exists Clauses

The `whereExists` method allows you to write `WHERE EXISTS` SQL clauses. The `whereExists` method accepts a query builder instance, which allows you to define the query that should be placed inside the "exists" clause:

```dart
// SELECT * FROM users
// WHERE EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id)
await User().query()
    .whereExists(
        Order().query().whereRaw('orders.user_id = users.id')
    )
    .get();
```

You can also use `whereNotExists`, `orWhereExists`, and `orWhereNotExists`:

```dart
await User().query()
    .whereNotExists(
        Order().query().whereRaw('orders.user_id = users.id')
    )
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

To group by a single column, you can use the convenience method `groupByColumn`:

```dart
await User().query()
    .groupByColumn('account_id')
    .get();
```

### Having

The `having` method works similarly to `where` but filters the results after grouping.

```dart
await User().query()
    .groupBy(['account_id'])
    .having('account_id', 100, operator: '>')
    .orHaving('status', 'active')
    .get();
```

### Having Raw

For complex expressions in the `HAVING` clause:

```dart
await User().query()
    .groupBy(['account_id'])
    .havingRaw('SUM(price) > ?', bindings: [2500])
    .orHavingRaw('COUNT(*) > ?', [10])
    .get();
```

### Additional Having Clauses

The query builder also supports `havingNull`, `havingNotNull`, and `havingBetween`:

```dart
await User().query()
    .groupBy(['account_id'])
    .havingNull('deleted_at')
    .havingNotNull('activated_at')
    .havingBetween('votes', 1, 100)
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

// Print RAW SQL to console (with bindings substituted)
User().query().where('id', 1).printRawSql();
```

## Pivot Table Filtering

When querying `BelongsToMany` relationships, you can filter the results based on columns in the intermediate (pivot) table.

> **Note:** These methods are only available on `BelongsToMany` relation instances (e.g., `user.roles()`).

### `wherePivot` / `orWherePivot`

Adds a basic `WHERE` clause on the pivot table.

```dart
// Filter roles where the 'is_admin' column on the pivot table is 1
final admins = await user.roles().wherePivot('is_admin', 1).get();
```

### `wherePivotIn` / `wherePivotNotIn`

Adds a `WHERE IN` clause on the pivot table.

```dart
final roles = await user.roles()
    .wherePivotIn('permission_level', [1, 2, 3])
    .get();
```

### `wherePivotNull` / `wherePivotNotNull`

Checks for NULL values on the pivot table.

```dart
final activeRoles = await user.roles()
    .wherePivotNull('expired_at')
    .get();
```

### `wherePivotCondition`

Allows using strongly-typed `WhereCondition` objects (from `Column` definitions) on the pivot table. This is especially useful when using typed Pivot classes.

```dart
final newRoles = await user.roles()
    .wherePivotCondition(UserRole.schema.createdAt.after(DateTime(2023)))
    .get();
```
