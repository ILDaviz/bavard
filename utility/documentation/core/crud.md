# CRUD Operations

## Creating a Record

To create a new record in the database, instantiate a new model, set its attributes, and call the `save` method:

```dart
final user = User();
user.name = 'Mario';
user.email = 'mario@example.com';
await user.save();
```

After saving, the model's ID will be automatically populated:

```dart
print(user.id); // 1
```

### Using Constructors

You can also pass attributes to the constructor:

```dart
final user = User({
  'name': 'Mario',
  'email': 'mario@example.com',
});
await user.save();
```

## Reading Records

### Finding by Primary Key

To retrieve a single record by its primary key:

```dart
// Returns User? (null if not found)
final user = await User().query().find(1);

// Throws ModelNotFoundException if not found
final user = await User().query().findOrFail(1);
```

### Retrieving All Records

```dart
final users = await User().query().get();

for (final user in users) {
  print(user.name);
}
```

### Retrieving the First Result

```dart
final user = await User().query().where('active', 1).first();
```

## Updating a Record

To update a record, first retrieve it, change its attributes, and then save it.

```dart
final user = await User().query().find(1);

user?.name = 'Luigi';

await user?.save();
```

### Dirty Checking

Bavard automatically tracks which attributes have changed ("dirty" attributes). When you call `save()`, only the modified fields are sent to the database in the `UPDATE` statement. If no fields have changed, no query is executed.

## Deleting a Record

To delete a model, call the `delete` method on an instance:

```dart
final user = await User().query().find(1);

await user?.delete();
```

## Bulk Operations

You can perform updates and deletes on multiple records at once using the query builder.

### Bulk Update

```dart
final rowsAffected = await User()
    .query()
    .where('status', 'inactive')
    .update({'archived': true});
```

### Bulk Delete

```dart
final deletedCount = await User()
    .query()
    .where('last_login', '2020-01-01', '<')
    .delete();
```

> **Note:** Bulk operations bypass model lifecycle hooks (`onSaving`, `onDeleting`, etc.) since they operate directly on the database without hydrating individual models.
