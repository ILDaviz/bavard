# Bavard (Pre-Alpha)

Bavard is an Eloquent-like ORM for Flutter/Dart, designed to work with SQLite, PostgreSQL, PowerSync or any driver you want.

🚧 **This project is under active development. APIs and documentation may change.**

---

#### Why Bavard?
- **Fluent syntax:** Write readable queries such as `User().query().where("age", ">", 18).get()`.
- **Offline-first ready:** Native support for client-side UUIDs and driver-agnostic architecture.
- **Advanced features:** Already includes Soft Deletes, automatic Timestamps, Global Scopes, and Polymorphic Relationships.

### Documentation
Documentation is a work in progress and will be published soon.

---

## Quick Start

### 1. Initialization
You must inject a driver adapter before using any model.

```dart
void main() {
  // Use any adapter implementing DatabaseAdapter
  DatabaseManager().setDatabase(DemoAdapter()); 
  runApp(MyApp());
}
```

### 2. Define a Model
You must inject a driver adapter before using any model.
This is a example.

```dart
class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```