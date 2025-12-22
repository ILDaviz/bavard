# Relationships

Bavard supports all standard database relationships.

## HasOne (One-to-One)

A one-to-one relationship is a very basic relation. For example, a `User` model might be associated with one `Profile`.

```dart
class User extends Model {
  // Bavard assumes the foreign key is 'user_id' in the 'profiles' table
  HasOne<Profile> profile() => hasOne(Profile.new);
}
```

To determine the table and keys, Bavard uses conventions:
- **Foreign Key**: `user_id` (derived from the parent model name).
- **Local Key**: `id` (parent primary key).

You can override these:
```dart
HasOne<Profile> profile() => hasOne(Profile.new, foreignKey: 'u_id', localKey: 'uuid');
```

**Usage:**
```dart
final user = await User().query().find(1);
final profile = await user?.profile().getResult();
```

## BelongsTo (Inverse One-to-One / One-to-Many)

This is the inverse of `HasOne` and `HasMany`. It resides on the child model.

```dart
class Profile extends Model {
  // Bavard assumes the foreign key is 'user_id' in the 'profiles' table
  BelongsTo<User> user() => belongsTo(User.new);
}
```

**Usage:**
```dart
final profile = await Profile().query().find(1);
final user = await profile?.user().getResult();
```

## HasMany (One-to-Many)

A one-to-many relationship is used to define relationships where a single model owns any amount of other models. For example, a blog post may have an infinite number of comments.

```dart
class Post extends Model {
  HasMany<Comment> comments() => hasMany(Comment.new);
}
```

**Usage:**
```dart
final post = await Post().query().find(1);
final comments = await post?.comments().get(); // Returns List<Comment>

// You can chain query methods
final recentComments = await post?.comments()
    .where('created_at', '2023-01-01', operator: '>')
    .orderBy('created_at', direction: 'DESC')
    .get();
```

## BelongsToMany (Many-to-Many)

Many-to-many relationships are slightly more complicated than other relationships. An example of such a relationship is a user with many roles, where the roles are also shared by other users. This requires an intermediate table (pivot table).

**Convention:**
- Pivot table name: `role_user` (alphabetical order of related model names).
- Pivot keys: `user_id`, `role_id`.

```dart
class User extends Model {
  BelongsToMany<Role> roles() => belongsToMany(Role.new, 'role_user');
}
```

**Overriding Keys:**
```dart
BelongsToMany<Role> roles() => belongsToMany(
  Role.new,
  'user_roles', // Custom pivot table
  foreignPivotKey: 'user_id',
  relatedPivotKey: 'role_id',
);
```

**Usage:**
```dart
final user = await User().query().find(1);
final roles = await user?.roles().get();
```

### Accessing Intermediate Table Attributes

Working with pivot tables often involves accessing extra data stored on the intermediate table. Bavard allows you to retrieve this data in a strongly-typed way using a custom `Pivot` class.

**1. Define the Pivot Class**
Create a class that extends `Pivot` and defines your intermediate table columns using static `Column` definitions. Annotate it with `@bavardPivot`.

```dart
// user_role.dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';

part 'user_role.pivot.g.dart';

@bavardPivot
class UserRole extends Pivot with _$UserRole {
  UserRole(super.attributes);

  // Define pivot columns
  static const createdAtCol = DateTimeColumn('created_at');
  static const isActiveCol = BoolColumn('is_active');
}
```

**2. Run the Code Generator**
This will generate the `_$UserRole` mixin containing typed accessors and a static `schema` list.
```bash
dart run build_runner build
```

**3. Use `.using()` on the Relationship**
In your model, chain the `.using()` method to your `belongsToMany` definition, providing the `Pivot` class factory and the generated schema.

```dart
class User extends Model {
  BelongsToMany<Role> roles() {
    return belongsToMany(Role.new, 'user_roles')
      .using(UserRole.new, UserRole.schema);
  }
}
```

**4. Retrieve Pivot Data**
When you retrieve the relationship, each related model will have a `pivot` property. Use the `getPivot<T>()` helper to access it in a type-safe way.

```dart
final user = await User().query().withRelations(['roles']).first();

final firstRole = user.rolesList.first;
final pivotData = firstRole.getPivot<UserRole>();

print(pivotData?.createdAt); // Fully typed as DateTime?
print(pivotData?.isActive);  // Fully typed as bool?
```
This works for both eager loading (`withRelations`) and lazy loading (`get()`).

### Filtering via Pivot Columns

You can filter the relationship results based on columns in the intermediate table using `wherePivot` helpers.

```dart
// Basic filtering
final admins = await user.roles()
    .wherePivot('is_admin', true)
    .get();

// Using WhereCondition (Typed)
final activeRoles = await user.roles()
    .wherePivotCondition(UserRole.isActiveCol.isTrue())
    .get();
```

Available methods:
- `wherePivot(column, value, [op])`
- `orWherePivot(...)`
- `wherePivotIn(...)` / `wherePivotNotIn(...)`
- `wherePivotNull(...)` / `wherePivotNotNull(...)`
- `wherePivotCondition(condition)` / `orWherePivotCondition(condition)`
