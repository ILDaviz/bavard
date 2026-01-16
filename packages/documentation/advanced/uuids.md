# HasUuids

The `HasUuids` mixin configures the model to use a UUID (v4) string as its primary key instead of an auto-incrementing integer.

```dart
class Document extends Model with HasUuids {
  @override
  String get table => 'documents';
}
```

## Behavior

- **Auto-Generation:** If the `id` is null when `save()` is called, a new UUID v4 is generated and assigned.
- **Non-Incrementing:** Sets `incrementing` to `false`, preventing the ORM from trying to fetch the last insert ID as an integer.

```dart
final doc = Document();
doc.title = 'Report';
await doc.save();

print(doc.id); // "550e8400-e29b-41d4-a716-446655440000"
```
