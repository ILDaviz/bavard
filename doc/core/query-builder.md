# Query Builder

The Query Builder provides a fluent interface for building SQL queries safely. It handles parameter binding automatically to prevent SQL injection.

## Retrieving Results

### get()

The `get` method executes the query and returns a `List<T>` of models.

```dart
final users = await User().query().where('active', 1).get();
```

### first()

The `first` method executes the query and returns the first result as a model instance, or `null`.

```dart
final user = await User().query().where('email', 'test@example.com').first();
```

### find()

Retrieve a model by its primary key (usually `id`):

```dart
final user = await User().query().find(1);
```

### findOrFail()

Retrieve a model by its primary key or throw a `ModelNotFoundException` if not found:

```dart
try {
  final user = await User().query().findOrFail(1);
} catch (e) {
  // Handle not found
}
```

### firstOrFail()

Execute the query and return the first result or throw a `ModelNotFoundException` if no results are found:

```dart
final user = await User().query().where('email', 'test@example.com').firstOrFail();
```

## Selects

By default, the query selects all columns (`*`). You can specify specific columns using `select`. It supports both string column names and `Column` objects:

```dart
final users = await User().query()
    .select([
        User.schema.id, 
        User.schema.name, 
        'email'
    ])
    .get();
```

To add a raw expression to the selection (e.g., for aggregates), use `selectRaw`:

```dart
await User().query()
    .select(['id', 'name'])
    .selectRaw('COUNT(*) as post_count')
    .get();
```

### Distinct

The `distinct` method forces the query to return unique results:

```dart
await User().query().distinct().select(['role']).get();
```

## Where Clauses

### Basic Where

The `where` method accepts three arguments: the column, the value, and an optional operator (defaults to `=`).

```dart
// Equality
.where('votes', 100)

// Comparison
.where('votes', 100, '>=')
.where('name', 'Mario', '!=')

// LIKE
.where('name', 'Mar%', 'LIKE')
```

### Type-Safe Where (Recommended)

When using code generation, you can use the `schema` for type-safe queries. This approach is robust against column name changes.

```dart
// Equality
.where(User.schema.votes.equals(100))

// Comparison
.where(User.schema.votes.greaterThanOrEqual(100))
.where(User.schema.name.notEquals('Mario'))

// LIKE
.where(User.schema.name.startsWith('Mar'))
```

You can also pass `Column` objects directly to methods like `whereNull`, `whereIn`, `orderBy`, etc. The builder will automatically prefix the column with the table name (e.g., `users.updated_at`).

```dart
// Generates: ... WHERE "users"."updated_at" IS NULL
.whereNull(User.schema.updatedAt)

// Generates: ... WHERE "users"."status" IN ('active', 'pending')
.whereIn(User.schema.status, ['active', 'pending'])
```

### Or Where

To join clauses with an `OR` operator, use `orWhere`:

```dart
.where('votes', '>', 100)
.orWhere('name', 'Mario')
```

### Where In / Where Not In

```dart
.whereIn('id', [1, 2, 3])
.whereIn(User.schema.roleId, [1, 2]) // Type-safe column
.orWhereIn('id', [10, 11])
.whereNotIn('id', [4, 5, 6])
```

### Where Between / Where Not Between

```dart
.whereBetween('votes', [1, 100])
.whereNotBetween('votes', [1, 100])
.orWhereBetween(User.schema.age, [18, 30])
```

### Where Null / Where Not Null

```dart
.whereNull('updated_at')
.whereNull(User.schema.deletedAt) // Type-safe column
.orWhereNull('deleted_at')
.whereNotNull('created_at')
.orWhereNotNull('posted_at')
```

### Where Column

The `whereColumn` method allows you to compare two columns in your query.

```dart
// Basic comparison
.whereColumn('first_name', 'last_name')

// Comparison with operator
.whereColumn('updated_at', '>', 'created_at')

// Multiple conditions using an array
.whereColumn([
  ['first_name', 'last_name'],
  ['updated_at', '>', 'created_at']
])
```

You can also use `orWhereColumn`:

```dart
.where('active', 1)
.orWhereColumn('first_name', 'last_name')
```

## Ordering

The `orderBy` method allows you to sort the results. It supports both string column names and `Column` objects.

```dart
.orderBy('name') // ASC by default
.orderBy(User.schema.createdAt, direction: 'DESC') // Type-safe column
```

## Limit and Offset

```dart
.limit(10)
.offset(5)
```

## Aggregates

The query builder supports various aggregate methods, which also accept `Column` objects:

```dart
final count = await User().query().count();
final max = await Product().query().max('price');
final min = await Product().query().min(Product.schema.price); // Type-safe
final avg = await Product().query().avg('rating');
final sum = await Order().query().sum('total');
```

## Inserts, Updates, and Deletes

### Inserts

You can insert records using the `insert` method. It accepts a `Map` of column names and values. It also supports `Column` objects as keys for type safety.

```dart
await User().query().insert({
  'email': 'john@example.com',
  'votes': 0,
});

// Type-safe insert
await User().query().insert({
  User.schema.email: 'jane@example.com',
  User.schema.votes: 0,
});
```

### Updates

The `update` method allows you to update existing records. It also supports `Column` objects as keys.

```dart
await User().query()
    .where('id', 1)
    .update({
        'votes': 1,
        'status': 'active',
    });

// Type-safe update
await User().query()
    .where('id', 1)
    .update({
        User.schema.votes: 10,
        User.schema.status: 'archived',
    });
```

### Deletes

The `delete` method removes records from the database.

```dart
await User().query().where('votes', '<', 100).delete();
```

## Existence Checking

```dart
if (await User().query().where('email', 'foo@bar.com').exists()) {
  // ...
}

if (await User().query().where('email', 'foo@bar.com').notExist()) {
  // ...
}
```

## Reactive Streams

For applications that need to react to database changes (like Flutter apps), you can use the `watch` method. It returns a `Stream<List<T>>` that emits a new list of models whenever the underlying table is modified.

```dart
StreamBuilder<List<User>>(
  stream: User().query().where('active', 1).watch(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return ListView(children: snapshot.data!.map((u) => Text(u.name)).toList());
  },
)
```

## SQL Dialects

Bavard supports multiple SQL dialects (SQLite, PostgreSQL, etc.) through the use of **Grammars**.
The SQL generated by the query builder will automatically adapt to the underlying database adapter's grammar (e.g. using `RETURNING id` for Postgres inserts vs separate query for SQLite).