# Introduction

Bavard is an Object-Relational Mapping (ORM) library that brings the **Active Record** pattern to Dart. If you're familiar with Laravel's Eloquent, you'll feel right at home.

The goal is to simplify database interactions with SQLite, PostgreSQL, or PowerSync while keeping your code clean and readable.

Bavard is designed to minimize friction in your development loop by reducing reliance on code generation. Unlike many Dart ORMs that require running `build_runner` for every schema change or relationship definition, Bavard relies on Dart's runtime capabilities and a strict "Convention over Configuration" philosophy.

Core features like relationship resolution, query building, and data hydration are handled dynamically through mixins such as `HasCasts` and `HasRelationships`. This means you can define a relationship or add a new column helper and use it immediately without waiting for a watcher process. Code generation is treated as an optional enhancement for reducing boilerplate—such as creating strictly typed getters—rather than a requirement for the ORM to function. This approach significantly speeds up iteration times and keeps your codebase cleaner and more transparent.

## Why Bavard?

- **Fluent Syntax:** Write readable queries such as `User().query().where(User.schema.age.greaterThan(18)).get()`.
- **Offline-first ready:** Native support for client-side UUIDs (`HasUuids`) and driver-agnostic architecture.
- **Advanced features:** Already includes soft deletes, Automatic timestamps, Global scopes, and Polymorphic relationships.
- **Type Safety:** Optional code generation for fully typed getters and setters.

## Core Concepts

### Type Casting and Data Lifecycle

Bavard manages data conversion through the `HasCasts` mixin, acting as a bridge between raw database values and Dart objects. 

- **Hydration** occurs when fetching records; the framework stores the raw data internally but lazily parses it—converting timestamps, booleans, or JSON strings into their respective objects—only when you access an attribute via `getAttribute`. 
- **Dehydration** prepares data for storage or comparison. When setting values or saving a model, the framework serializes rich Dart objects back into database-compatible primitives (like integers for booleans), ensuring complex structures are correctly encoded for persistence and dirty checking.

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
