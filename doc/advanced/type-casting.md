# Type Casting

Bavard manages data conversion through the HasCasts mixin, acting as a bridge between raw database values and Dart objects. Hydration occurs when fetching records; the framework stores the raw data internally but lazily parses it—converting timestamps, booleans, or JSON strings into their respective objects—only when you access an attribute via getAttribute. Conversely, Dehydration prepares data for storage or comparison. When setting values or saving a model, the framework serializes rich Dart objects back into database-compatible primitives (like integers for booleans), ensuring complex structures are correctly encoded for persistence and dirty checking.

## Defining Casts

Override the `casts` getter in your model:

```dart
class User extends Model {
  @override
  Map<String, String> get casts => {
    'age': 'int',
    'score': 'double',
    'is_active': 'bool',
    'created_at': 'datetime',
    'settings': 'json',
    'tags': 'array',
    'metadata': 'object',
  };
}
```

## Supported Types

| Cast Type | Dart Type | Behavior |
|-----------|-----------|----------|
| `int` | `int` | Parses strings, converts nums |
| `double` | `double` | Parses strings, converts nums |
| `bool` | `bool` | `1`/`0`, `"true"`/`"false"` -> `bool` |
| `datetime` | `DateTime` | ISO-8601 string <-> `DateTime` |
| `json` | `dynamic` | JSON string <-> Decoded JSON |
| `array` | `List` | JSON string <-> `List` |
| `object` | `Map` | JSON string <-> `Map` |

## Enum Casting

Bavard provides a helper to cast attributes to Dart Enums.

```dart
enum Status { active, inactive }

// Reading
final status = user.getEnum('status', Status.values);

// Writing
user.setAttribute('status', Status.active); // Stores 'active'
```
