# HasTimestamps

The `HasTimestamps` mixin automatically manages `created_at` and `updated_at` columns.

```dart
class Post extends Model with HasTimestamps {
  @override
  String get table => 'posts';
}
```

## Behavior

- **created_at**: Set to the current time when the model is first saved (inserted).
- **updated_at**: Set to the current time every time the model is saved (updated).

## Custom Column Names

You can customize the column names by overriding the getters:

```dart
class Post extends Model with HasTimestamps {
  @override
  String get createdAtColumn => 'date_created';

  @override
  String get updatedAtColumn => 'date_modified';
}
```
