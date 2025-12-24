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

### Defining `getRelation` (Mandatory)

To enable eager loading, your model **must** implement the `getRelation` method. This method maps the string names provided to `withRelations` to the actual relationship definitions.

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
        // Always fall back to super
        return super.getRelation(name);
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

## Nested Eager Loading

You can load nested relationships using "dot" syntax. For example, to load all of the book's authors and all of the author's personal contacts in one go:

```dart
final books = await Book().query()
    .withRelations(['author.contacts'])
    .get();
```

This works recursively. If you want to load the `posts`, and for each post load the `comments`, and for each comment load the `author`:

```dart
final users = await User().query()
    .withRelations(['posts', 'posts.comments.author'])
    .get();
```

