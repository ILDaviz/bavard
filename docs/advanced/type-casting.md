# Type Casting

Bavard allows you to convert attributes to common data types when retrieving them from the database, and serialize them back when saving.

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
