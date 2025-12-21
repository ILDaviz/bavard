# HasManyThrough

The "has-many-through" relationship provides a convenient shortcut for accessing distant relations via an intermediate relation.

For example, a `Country` model might have many `Post` models through an intermediate `User` model.

```
Country -> User -> Post
```

## Table Structure

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

## Defining the Relationship

```dart
class Country extends Model {
  HasManyThrough<Post, User> posts() => hasManyThrough(Post.new, User.new);
}
```

By default, Bavard uses convention to determine the keys:
- **First Key**: `country_id` on `users` table.
- **Second Key**: `user_id` on `posts` table.

## Overriding Keys

You can explicitly pass the keys if they don't follow the convention:

```dart
class Country extends Model {
  HasManyThrough<Post, User> posts() => hasManyThrough(
    Post.new, 
    User.new,
    firstKey: 'nation_code', // on users table
    secondKey: 'author_id',  // on posts table
  );
}
```

## Usage

```dart
final country = await Country().query().find(1);
final posts = await country?.posts().get();
```
