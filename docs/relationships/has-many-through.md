# HasManyThrough

The "has-many-through" relationship provides a convenient shortcut for accessing distant relations via an intermediate relation.

This is useful when you want to jump over an intermediate model to fetch distant records without writing complex manual joins.

## Standard Relationship

Consider a scenario with **Countries**, **Users**, and **Posts**:
*   A `Country` has many `Users`.
*   A `User` has many `Posts`.
*   Therefore, a `Country` has many `Posts` *through* its users.

### Table Structure

```
countries
    id - integer
    name - string

users
    id - integer
    country_id - integer
    name - string

posts
    id - integer
    user_id - integer
    title - string
```

### Model Definition

```dart
class Country extends Model {
  // Define the distant relationship
  HasManyThrough<Post, User> posts() => hasManyThrough(Post.new, User.new);
}
```

By default, Bavard uses convention to determine the keys:
- **First Key**: `country_id` on the intermediate table (`users`).
- **Second Key**: `user_id` on the target table (`posts`).

### Usage

```dart
final country = await Country().query().find(1);

// Fetch all posts written by users of this country
final posts = await country?.posts().get();
```

## Polymorphic HasManyThrough

A common real-world scenario involves polymorphic tables (like `comments` or `media`).
Imagine you want to retrieve **"All comments posted on a User's posts"**.

Structure:
*   `User` has many `Post`s.
*   `Post` has many `Comment`s (Polymorphic: `commentable_id`, `commentable_type`).

### Model Definition

Use the `hasManyThroughPolymorphic` method. This helper automatically handles the polymorphic type constraints for you.

```dart
class User extends Model {
  // 1. Standard relation to posts
  HasMany<Post> posts() => hasMany(Post.new);

  // 2. Distant relation: Get all comments on this user's posts
  HasManyThrough<Comment, Post> postComments() {
    return hasManyThroughPolymorphic(
      Comment.new, 
      Post.new, 
      name: 'commentable', // The prefix for _id and _type columns
      type: 'posts',       // The value stored in the _type column
    );
  }
}
```

### How it works
Under the hood, this method:
1.  Sets the second foreign key to `commentable_id` (derived from `name`).
2.  Automatically adds a `WHERE commentable_type = 'posts'` clause to the query.

### Usage

```dart
final user = await User().query().find(1);

// Fetch all comments that belongs to the user's posts
final comments = await user?.postComments().get();
```

---

## Overriding Keys (Advanced)

If your database does not follow standard conventions (e.g., using `nation_code` instead of `country_id`), you can manually override the keys.

```dart
class Country extends Model {
  HasManyThrough<Post, User> posts() => hasManyThrough(
    Post.new, 
    User.new,
    firstKey: 'nation_code', // Foreign key on 'users' table pointing to 'countries'
    secondKey: 'author_id',  // Foreign key on 'posts' table pointing to 'users'
  );
}
```
