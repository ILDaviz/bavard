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
