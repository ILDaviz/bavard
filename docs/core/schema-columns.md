# Schema Columns

When defining your model's schema for code generation, you use `Column` classes. These classes map to database types and provide type-safe query helpers.

## Available Column Types

The following column types are available in `static const schema`:

| Class | Dart Type | SQL Type | Description |
|-------|-----------|----------|-------------|
| `TextColumn` | `String` | `string` | Text strings |
| `IntColumn` | `int` | `integer` | Integers |
| `DoubleColumn` | `double` | `double` | Floating point numbers |
| `BoolColumn` | `bool` | `boolean` | Stored as 1/0 |
| `DateTimeColumn` | `DateTime` | `datetime` | Stored as ISO-8601 string |
| `JsonColumn` | `dynamic` | `json` | Arbitrary JSON data |
| `ArrayColumn` | `List` | `array` | JSON Array |
| `ObjectColumn` | `Map` | `object` | JSON Object |
| `EnumColumn` | `Enum` | `string` | Stored as Enum name string |

## Usage Example

```dart
static const schema = (
  name: TextColumn('name'),
  age: IntColumn('age'),
  isActive: BoolColumn('is_active'),
  settings: JsonColumn('settings'),
);
```

## Type-Safe Query Conditions

These columns provide methods to generate `WhereCondition` objects, which can be passed directly to the `where` method of the query builder.

### TextColumn
- `.contains(String value)`
- `.startsWith(String value)`
- `.endsWith(String value)`
- `.equals(String value)`
- `.notEquals(String value)`

### IntColumn / DoubleColumn
- `.greaterThan(num value)`
- `.lessThan(num value)`
- `.greaterThanOrEqual(num value)`
- `.lessThanOrEqual(num value)`
- `.between(num min, num max)`

### BoolColumn
- `.isTrue()`
- `.isFalse()`

### DateTimeColumn
- `.after(DateTime value)`
- `.before(DateTime value)`
- `.between(DateTime start, DateTime end)`

### JsonColumn / JsonPathColumn
JSON columns allow you to query nested paths.

```dart
// Define
JsonColumn('metadata')

// Query nested key "role" inside "metadata"
User().query().where(
  User.schema.metadata.key('role').equals('admin')
)
```

- `.key(String path)`: Navigate to a key in an object.
- `.index(int index)`: Navigate to an index in an array.

### Standard Methods (All Columns)
- `.equals(T value)`
- `.notEquals(T value)`
- `.isNull()`
- `.isNotNull()`
- `.inList(List<T> values)`
- `.notInList(List<T> values)`
