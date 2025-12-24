# Relationships

Bavard supports all standard database relationships.

> [!IMPORTANT]
> **The `getRelation` Method**
> If the model defines relationships, it is **necessary** to override the `getRelation` method for **ALL** existing relationships. This method maps the relationship names (used in lazy loading) to the corresponding definition methods. For this ORM to function correctly, it must always be defined for each model.
>
> ```dart
> class User extends Model {
>   HasMany<Post> posts() => hasMany(Post.new);
>   HasOne<Profile> profile() => hasOne(Profile.new);
>
>   @override
>   Relation? getRelation(String name) {
>     switch (name) {
>       case 'posts': return posts();
>       case 'profile': return profile();
>       default: return super.getRelation(name);
>     }
>   }
> }
> ```

## Constraining Relations

Since all relationships in Bavard serve as query builders, you can add further constraints to the relationship queries directly within the model definition. This is useful for defining specialized relationships like "Active Posts" or sorting default results.

The recommended way to do this is using the **cascade operator** (`..`) in Dart:

```dart
class User extends Model {
  // Standard relation
  HasMany<Post> posts() => hasMany(Post.new);

  // Constrained relation: Only active posts
  HasMany<Post> activePosts() {
    return hasMany(Post.new)
      ..where('is_active', true)
      ..orderBy('created_at', direction: 'desc');
  }
}
```

Now, when you eager load or access `activePosts`, the additional WHERE and ORDER BY clauses will be automatically applied.

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
Create a class that extends `Pivot` and defines your intermediate table columns using a `static const schema` record. Annotate it with `@bavardPivot`.

```dart
// user_role.dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';

import 'user_role.pivot.g.dart';

@bavardPivot
class UserRole extends Pivot with $UserRole {
  UserRole(super.attributes);

  // Define pivot columns in a schema record
  static const schema = (
    createdAt: DateTimeColumn('created_at'),
    isActive: BoolColumn('is_active'),
  );
}
```

**2. Run the Code Generator**
This will generate the `$UserRole` mixin containing typed accessors (getters and setters).
```bash
dart run build_runner build
```

**3. Use `.using()` on the Relationship**
In your model, chain the `.using()` method to your `belongsToMany` definition, providing the `Pivot` class factory and the generated schema columns.

```dart
class User extends Model {
  BelongsToMany<Role> roles() {
    return belongsToMany(Role.new, 'user_roles')
      .using(UserRole.new, UserRole.columns);
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

// You can also update pivot attributes
pivotData?.isActive = false;
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
    .wherePivotCondition(UserRole.schema.isActive.isTrue())
    .get();
```

Available methods:
- `wherePivot(column, value, [op])`
- `orWherePivot(...)`
- `wherePivotIn(...)` / `wherePivotNotIn(...)`
- `wherePivotNull(...)` / `wherePivotNotNull(...)`
- `wherePivotCondition(condition)` / `orWherePivotCondition(condition)`
