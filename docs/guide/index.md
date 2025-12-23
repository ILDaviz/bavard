# Introduction

Bavard is an Object-Relational Mapping (ORM) library that brings the **Active Record** pattern to Dart. If you're familiar with Laravel's Eloquent, you'll feel right at home.

The goal is to simplify database interactions with SQLite, PostgreSQL, or PowerSync while keeping your code clean and readable.

## Why Bavard?

- **Fluent Syntax:** Write readable queries such as `User().query().where(User.schema.age.greaterThan(18)).get()`.
- **Offline-first ready:** Native support for client-side UUIDs (`HasUuids`) and driver-agnostic architecture.
- **Advanced features:** Already includes soft deletes, Automatic timestamps, Global scopes, and Polymorphic relationships.
- **Type Safety:** Optional code generation for fully typed getters and setters.

## Quick Example

```dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'post.dart';
import 'image.dart';
import 'user.fillable.g.dart';

@fillable
class User extends Model with $UserFillable, HasUuids {
  @override
  String get table => 'users';

  static const schema = (
  name: TextColumn('name'),
  email: TextColumn('email'),
  timezone: TextColumn('timezone'),
  createdAt: DateTimeColumn('created_at'),
  updatedAt: DateTimeColumn('updated_at'),
  );

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasMany<Post> posts() => hasMany(Post.new);
  List<Post> get postsList => getRelationList<Post>('posts');

  HasMany<Image> images() => hasMany(Image.new);
  List<Image> get imagesList => getRelationList<Image>('images');

  @override
  Relation? getRelation(String name) {
    if (name == 'posts') return posts();
    if (name == 'images') return images();
    return super.getRelation(name);
  }
}

// Use it
final user = User();
user.name = 'Mario';
user.email = 'mario@example.com';
await user.save();

final users = await User().query().where('active', 1).get();
```
