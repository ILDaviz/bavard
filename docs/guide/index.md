# Introduction

Bavard is an Object-Relational Mapping (ORM) library that brings the **Active Record** pattern to Dart. If you're familiar with Laravel's Eloquent, you'll feel right at home.

The goal is to simplify database interactions with SQLite, PostgreSQL, or PowerSync while keeping your code clean and readable.

## Why Bavard?

- **Fluent Syntax:** Write readable queries such as `User().query().where(User.schema.age.greaterThan(18)).get()`.
- **Offline-first ready:** Native support for client-side UUIDs (`HasUuids`) and driver-agnostic architecture.
- **Advanced features:** Already includes Soft Deletes, automatic Timestamps, Global Scopes, and Polymorphic Relationships.
- **Type Safety:** Optional code generation for fully typed getters and setters.

## Quick Example

```dart
// Define a model
class User extends Model {
  @override
  String get table => 'users';
  
  User([super.attributes]);
  
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

// Use it
final user = User();
user.attributes['name'] = 'Mario';
user.attributes['email'] = 'mario@example.com';
await user.save();

final users = await User().query().where('active', 1).get();
```
