# Initial Setup

Before using Models, you need to configure the database adapter. This acts as the bridge between Bavard's ORM logic and your specific database driver (e.g., `sqflite`, `postgres`, `powersync`, or `drift`).

This configuration should be done once, typically in your app's `main()` function or initialization logic.

```dart
import 'package:bavard/bavard.dart';

void main() {
  // 1. Initialize your specific database connection
  final myDbConnection = ...; 

  // 2. Wrap it in a class that implements DatabaseAdapter
  final myDatabaseAdapter = MyCustomAdapter(myDbConnection);

  // 3. Register the adapter with Bavard
  DatabaseManager().setDatabase(myDatabaseAdapter);

  // Now you can use Models anywhere in your app
}
```

## The DatabaseAdapter Interface

The adapter must implement the `DatabaseAdapter` interface, which defines the basic methods for queries, inserts, updates, and deletes.

See [Implementing a Database Adapter](../reference/database-adapter.md) for details on how to create a custom adapter.
