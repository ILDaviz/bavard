# Introduction

Bavard is a modular, Eloquent-inspired ecosystem for Dart and Flutter. It brings the **Active Record** pattern to the Dart ecosystem, allowing you to interact with your database using an expressive, fluent syntax.

Unlike many Dart ORMs that rely heavily on complex code generation, Bavard is designed to be dynamic and flexible. It leverages Dart's runtime capabilities and a "Convention over Configuration" philosophy to minimize friction in your development loop.

## The Ecosystem

Bavard is built as a collection of specialized packages. While the core is standalone, the tooling suite ensures a smooth workflow:

- **[`bavard`](/guide/installation)**: The core runtime. It includes the Model implementation, the Fluent Query Builder, and the Relationship engine.
- **[`bavard_migration`](/guide/migrations)** & **[`bavard_cli`](/tooling/cli)**: The tooling suite. These two packages work hand-in-hand to manage your database schema and scaffold your code. While optional.

## Why Bavard?

- **Modular Architecture:** Choose between a lightweight core or a full-featured suite with migrations and CLI tools.
- **Flutter ready:** Seamlessly integrated with Flutter for mobile, desktop, and web applications.
- **Fluent Syntax:** Write readable queries such as `User().query().where(User.schema.age.greaterThan(18)).get()`.
- **Offline-first ready:** Native support for client-side UUIDs (`HasUuids`) and driver-agnostic architecture.
- **Advanced features:** Already includes soft deletes, Automatic timestamps, Global scopes, and Polymorphic relationships.
- **No Magic:** Code generation is 100% optional. Bavard leverages Dart's runtime capabilities and mixins to handle relationships and data casting dynamically at runtime, allowing you to iterate without waiting for build processes.
- **Type Safety:** Optional code generation for fully typed getters and setters.

## Core Philosophy

Bavard focuses on speed of development. Relationship resolution, query building, and data hydration are handled dynamically. This means you can add a new relationship or column and use it immediately.

If you prefer strictly typed properties, you can use the CLI to generate them, but the ORM remains functional and transparent even without a single line of generated code.

## Quick Example

```dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'post.dart';
import 'image.dart';
import 'user.g.dart';

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

final users = await User().query().where(User.schema.name.equals('Mario')).get();
```
