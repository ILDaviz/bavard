# Bavard

[![pub.dev](https://img.shields.io/pub/v/bavard.svg)](https://pub.dev/packages/bavard)

Bavard is an Eloquent-like ORM for Flutter/Dart, designed to work with SQLite, PostgreSQL, PowerSync or any driver you want.

> [!CAUTION]
> **This project is under active development. APIs and documentation may change.**

---

#### Why Bavard?
- **Fluent syntax:** Write readable queries such as `User().query().where("age", ">", 18).get()`.
- **Offline-first ready:** Native support for client-side UUIDs and driver-agnostic architecture.
- **Advanced features:** Already includes Soft Deletes, automatic Timestamps, Global Scopes, and Polymorphic Relationships.

## Installation

Add Bavard to your `pubspec.yaml`:

```yaml
dependencies:
  bavard: ^0.0.1
```

## Quick Start

### 1. Define a Model

Extend the `Model` class and define your table name and hydration logic.

```dart
import 'package:bavard/bavard.dart';

class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

### 2. Querying

Use the fluent query builder to retrieve data.

```dart
// Get all users over 18
final users = await User().query()
    .where('age', 18, operator: '>')
    .orderBy('name')
    .get();

// Find a specific user
final user = await User().query()
    .where('email', 'mario@example.com')
    .first();
```

### 3. CRUD Operations

Easily create, update, and delete records.

```dart
// Create
final newUser = User();
newUser['name'] = 'Luigi';
newUser['email'] = 'luigi@example.com';
await newUser.save();

// Update
final user = await User().query().first();
if (user != null) {
  user['active'] = true;
  await user.save();
}

// Delete
await user?.delete();
```

### Documentation
See [Official Documentation](https://ildaviz.github.io/bavard/)