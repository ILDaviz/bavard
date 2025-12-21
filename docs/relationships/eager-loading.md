# Eager Loading

When accessing relationships as properties, query execution is "lazy". This means the relationship data is not actually loaded until you access it. However, eager loading allows you to query many models and then load the relationship data for all of them in a single query.

This significantly reduces the N+1 query problem.

## Using `withRelations`

You can eager load relationships using the `withRelations` method on the query builder:

```dart
final users = await User().query()
    .withRelations(['posts', 'profile'])
    .get();
```

This will execute:
1. `SELECT * FROM users`
2. `SELECT * FROM posts WHERE user_id IN (1, 2, 3...)`
3. `SELECT * FROM profiles WHERE user_id IN (1, 2, 3...)`

## Accessing Eager Loaded Data

Once loaded, you can access the relationships without awaiting a new query.

### Defining `getRelation`

To enable this access, your model **must** implement the `getRelation` method. This method maps the string names to the relationship definitions.

```dart
class User extends Model {
  HasMany<Post> posts() => hasMany(Post.new);
  HasOne<Profile> profile() => hasOne(Profile.new);

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'posts':
        return posts();
      case 'profile':
        return profile();
      default:
        return null;
    }
  }
}
```

### Retrieving the Data

Use the `getRelated` (for single) and `getRelationList` (for lists) helpers:

```dart
for (final user in users) {
  // No database query here
  final posts = user.getRelationList<Post>('posts');
  final profile = user.getRelated<Profile>('profile');

  print('User ${user.name} has ${posts.length} posts');
}
```

> **Warning:** Currently, only one level of nested eager loading is supported directly.
