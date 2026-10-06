# HasSoftDeletes

The `HasSoftDeletes` mixin allows you to "soft delete" records. This means the record is not removed from the database; instead, a `deleted_at` attribute is set on the record.

```dart
class User extends Model with HasSoftDeletes {
  @override
  String get table => 'users';
}
```

## Deleting

When you call `delete()` on a soft-deletable model, it sets the `deleted_at` timestamp.

```dart
await user.delete();
```

## Querying

By default, soft-deleted records are **excluded** from query results.

```dart
// Excludes deleted users
final users = await User().query().get();
```

### Including Deleted Records

```dart
final allUsers = await User().withTrashed().get();
```

### Retrieving Only Deleted Records

```dart
final trash = await User().onlyTrashed().get();
```

## Restoring

To restore a soft-deleted model:

```dart
await user.restore();
```

## Force Deleting

To permanently remove the record from the database:

```dart
await user.forceDelete();
```
