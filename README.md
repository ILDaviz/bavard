# Bavard ORM 🗣️

[![pub.dev](https://img.shields.io/pub/v/bavard.svg)](https://pub.dev/packages/bavard)

**The Eloquent-style ORM for Dart.**

> **Work in Progress**: This project is currently under active development. APIs may change.

Bavard brings the elegance and simplicity of Eloquent to the Dart ecosystem. It is designed to provide a fluent, expressive interface for database interactions, prioritizing developer experience, runtime flexibility, and readability.

---

## 🚀 Key Features

- 💙 **Flutter ready:** Seamlessly integrated with Flutter for mobile, desktop, and web applications.
- ⚡️ **Runtime-first architecture:** Code generation is 100% optional. Bavard leverages Dart's runtime capabilities and mixins to work entirely without build processes.
- 🏗️ **Fluent Query Builder:** Construct complex SQL queries using an expressive and type-safe interface.
- 🔗 **Rich Relationship Mapping:** Full support for One-to-One, One-to-Many, Many-to-Many, Polymorphic, and HasManyThrough relations.
- 🧩 **Smart Data Casting:** Automatic hydration and dehydration of complex types like JSON, DateTime, and Booleans between Dart and your database.
- 🏭 **Production-ready features:** Built-in support for Soft Deletes, Automatic Timestamps, and Global Scopes out of the box.
- 📱 **Offline-first ready:** Native support for client-side UUIDs and a driver-agnostic architecture, ideal for local-first applications.
- 🕵️ **Dirty Checking:** Optimized database updates by tracking only the attributes that have actually changed.
- 🚀 **Eager Loading:** Powerful eager loading system to eliminate N+1 query problems.
- 🌐 **Database Agnostic:** Flexible adapter system with native support for SQLite and PostgreSQL.

---

## 📚 Documentation

For detailed guides, API references, and usage examples, please visit our documentation:

👉 **[Read the Documentation](https://ildaviz.github.io/bavard/)**

---

## 🏁 Quick Start

### 0. Initialize Database

Bavard is driver-agnostic. You just need to provide an implementation of `DatabaseAdapter` (see [Adapters documentation](https://ildaviz.github.io/bavard/reference/adapters.html) for reference implementations).

```dart
import 'package:bavard/bavard.dart';
import 'your_project/my_database_adapter.dart'; // Your custom implementation

void main() async {
  // Initialize your custom adapter (SQLite, Postgres, PowerSync, etc.)
  final adapter = MyDatabaseAdapter();
  await adapter.connect();
  
  // Register it as the default connection
  DatabaseManager().setDatabase(adapter);
}
```

### 1. Define a Model

Bavard models use a schema-first approach. For the best experience, use code generation to get full type safety.

```dart
import 'package:bavard/bavard.dart';

part 'user.g.dart';

@fillable
class User extends Model with $UserFillable {
  @override
  String get table => 'users';

  // Define schema for query safety and automatic casting
  static const schema = (
    id: IdColumn(),
    name: TextColumn('name'),
    email: TextColumn('email'),
    isActive: BoolColumn('is_active'),
  );

  User([super.attributes]);
  
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

### 2. Use it!

Enjoy a fluent, expressive, and type-safe API.

```dart
// Create
final user = User();
user.name = 'Mario'; // Typed setter
user.isActive = true;
await user.save();

// Read (Type-Safe)
final users = await User().query()
    .where(User.schema.isActive, true) // Uses generated schema
    .orderBy(User.schema.name)
    .get();

// Update (with Dirty Checking)
final mario = await User().query().find(1);
mario.name = 'Super Mario';
await mario.save(); // Only updates the 'name' column

// Reactive Streams (Flutter friendly)
StreamBuilder<List<User>>(
  stream: User().query().watch(), // Auto-updates on DB changes
  builder: (context, snapshot) {
    // ...
  },
);
```

---

## 🔗 Relationships

Defining relationships is easy. Dispatching (`getRelation`) is **generated automatically** if you use `@fillable` + `build_runner`, or can be overridden manually:

```dart
// With @fillable codegen: just define the relationship,
// the getRelation dispatch is generated.
@fillable
class User extends Model with $UserFillable {
  // ... (table, schema, etc.)

  HasMany<Post> posts() => hasMany(Post.new);
}

// Without codegen (runtime-first): register manually.
@override
Relation? getRelation(String name) {
  if (name == 'posts') return posts();
  return super.getRelation(name);
}

// Usage
final user = await User().query().find(1);

// Lazy Load
final posts = await user.posts().get();

// Eager Load (Avoid N+1)
final usersWithPosts = await User().query().withRelations(['posts']).get();
```

---

## 🧪 Examples & Integration

To see Bavard in action with a real database environment, check the integration suite:

*   [SQLite + Docker Integration Test](example/sqlite-docker/)
*   [PostgreSQL + Docker Integration Test](example/postgresql-docker/)

A complete Flutter demo app lives in [`utility/bavard_example_project`](utility/bavard_example_project).

---

## 🗂️ Repository Structure

The repository root **is** the package. Extras live outside the pub build:

- **`utility/documentation/`**: The documentation website (VitePress), deployed to [ildaviz.github.io/bavard](https://ildaviz.github.io/bavard/).
- **`utility/bavard_example_project/`**: Demonstrative Flutter project that illustrates how to integrate and use **Bavard ORM**.
- Both are excluded from the published package via `.pubignore`.

---

## 🤝 Contributing

Bavard is open-source. Feel free to explore the code, report issues, or submit pull requests.
