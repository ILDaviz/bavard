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

The query builder allows you to write `JOIN` clauses. It supports both string column names and `Column` objects for join conditions.

### Inner Join

```dart
// Using Strings
await User().query()
    .join('contacts', 'users.id', '=', 'contacts.user_id')
    .select(['users.*', 'contacts.phone'])
    .get();

// Using Columns
await User().query()
    .join('contacts', User.schema.id, '=', Contact.schema.userId)
    .get();
```

### Left Join / Right Join

```dart
// Using Strings
.leftJoin('posts', 'users.id', '=', 'posts.user_id')

// Using Columns
.rightJoin('posts', User.schema.id, '=', Post.schema.userId)
```

## Group By and Having

### Group By

```dart
// Using Strings
await User().query()
    .groupBy(['account_id', 'status'])
    .get();

// Using Columns (convenience method for single column)
await User().query()
    .groupByColumn(User.schema.accountId)
    .get();
    
// Using Columns (list)
await User().query()
    .groupBy([User.schema.accountId, User.schema.status])
    .get();
```

### Having

The `having` method works similarly to `where` but filters the results after grouping. It accepts string column names or `Column` objects.

```dart
// Using Strings
await User().query()
    .groupBy(['account_id'])
    .having('account_id', 100, operator: '>')
    .get();

// Using Columns
await User().query()
    .groupByColumn(User.schema.accountId)
    .having(User.schema.accountId, 100, operator: '>')
    .orHaving(User.schema.status, 'active')
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

The query builder also supports `havingNull`, `havingNotNull`, and `havingBetween`, accepting both strings and `Column` objects:

```dart
// Using Strings
await User().query()
    .groupBy(['account_id'])
    .havingNull('deleted_at')
    .havingBetween('votes', 1, 100)
    .get();

// Using Columns
await User().query()
    .groupByColumn(User.schema.accountId)
    .havingNotNull(User.schema.activatedAt)
    .havingBetween(User.schema.votes, 1, 100)
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

Adds a basic `WHERE` clause on the pivot table. Accepts strings or `Column` objects.

```dart
// Filter roles where the 'is_admin' column on the pivot table is 1
final admins = await user.roles().wherePivot('is_admin', 1).get();

// Using type-safe Column object (auto-prefixed with pivot table name)
final admins = await user.roles().wherePivot(UserRole.schema.isAdmin, 1).get();
```

### `wherePivotIn` / `wherePivotNotIn`

Adds a `WHERE IN` clause on the pivot table.

```dart
final roles = await user.roles()
    .wherePivotIn('permission_level', [1, 2, 3])
    .wherePivotIn(UserRole.schema.permissionLevel, [1, 2])
    .get();
```

### `wherePivotNull` / `wherePivotNotNull`

Checks for NULL values on the pivot table.

```dart
final activeRoles = await user.roles()
    .wherePivotNull('expired_at')
    .orWherePivotNull(UserRole.schema.expiredAt)
    .get();
```

### `wherePivotCondition`

Allows using strongly-typed `WhereCondition` objects (from `Column` definitions) on the pivot table. This is especially useful when using typed Pivot classes.

```dart
final newRoles = await user.roles()
    .wherePivotCondition(UserRole.schema.createdAt.after(DateTime(2023)))
    .get();
```
