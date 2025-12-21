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

## Selects

By default, the query selects all columns (`*`). You can specify specific columns using `select`:

```dart
final users = await User().query()
    .select(['id', 'name', 'email'])
    .get();
```

To add a raw expression to the selection (e.g., for aggregates), use `selectRaw`:

```dart
await User().query()
    .select(['id', 'name'])
    .selectRaw('COUNT(*) as post_count')
    .get();
```

## Where Clauses

### Basic Where

The `where` method accepts three arguments: the column, the value, and an optional operator (defaults to `=`).

```dart
// Equality
.where('votes', 100)

// Comparison
.where('votes', 100, operator: '>=')
.where('name', 'Mario', operator: '!=')

// LIKE
.where('name', 'Mar%', operator: 'LIKE')
```

### Type-Safe Where (Recommended)

When using code generation, you can use the `schema` for type-safe queries:

```dart
// Equality
.where(User.schema.votes.equals(100))

// Comparison
.where(User.schema.votes.greaterThanOrEqual(100))
.where(User.schema.name.notEquals('Mario'))

// LIKE
.where(User.schema.name.startsWith('Mar'))
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
.whereNotIn('id', [4, 5, 6])
```

### Where Null / Where Not Null

```dart
.whereNull('updated_at')
.whereNotNull('created_at')
```

## Ordering

The `orderBy` method allows you to sort the results.

```dart
.orderBy('name') // ASC by default
.orderBy('created_at', direction: 'DESC')
```

## Limit and Offset

```dart
.limit(10)
.offset(5)
```

## Aggregates

The query builder supports various aggregate methods:

```dart
final count = await User().query().count();
final max = await Product().query().max('price');
final min = await Product().query().min('price');
final avg = await Product().query().avg('rating');
final sum = await Order().query().sum('total');
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
