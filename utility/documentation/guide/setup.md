# Initial Setup

Before you can use Bavard, you need to tell it which database to use by registering a **Database Adapter**. This connection should be established once during your application's startup.

## Database Connection

Bavard is driver-agnostic: it ships no driver bindings, so you connect it to SQLite (via `sqflite` or `sqlite3`), PostgreSQL, PowerSync, or any other SQL database by wrapping the connection in a small adapter that implements `DatabaseAdapter`.

The [Adapters guide](/reference/adapters) provides ready-to-copy reference implementations for the most common drivers.

```dart
import 'package:bavard/bavard.dart';
import 'package:sqlite3/sqlite3.dart';
import 'my_sqlite_adapter.dart'; // SqliteAdapter, copied from the Adapters guide

void main() async {
  // Initialize your database connection (e.g., SQLite)
  final adapter = SqliteAdapter(sqlite3.open('my_database.db'));

  // Register the adapter with the DatabaseManager
  DatabaseManager().setDatabase(adapter);

  // Your models are now ready to use!
}
```

## Running Migrations at Startup

Bavard's `Migrator` is a runtime tool: register your migrations in code and run them once during initialization to ensure the local database schema is up to date. This is the natural workflow for offline-first apps — when the user installs an update, only the new migrations are executed.

```dart
import 'package:bavard/bavard.dart';
import 'my_sqlite_adapter.dart';
import 'migrations/2026_02_11_000001_create_users_table.dart';
import 'migrations/2026_02_11_000002_create_posts_table.dart';

Future<void> initializeDatabase() async {
  final adapter = SqliteAdapter(sqlite3.open('path/to/db'));
  DatabaseManager().setDatabase(adapter);

  // Initialize the migration repository and migrator
  final repository = MigrationRepository(adapter);
  final migrator = Migrator(adapter, repository);

  // Register your migrations (order is inferred from the file name)
  final migrations = [
    MigrationRegistryEntry(CreateUsersTable(), '2026_02_11_000001_create_users_table'),
    MigrationRegistryEntry(CreatePostsTable(), '2026_02_11_000002_create_posts_table'),
  ];

  // Runs only the migrations that haven't been executed yet
  await migrator.runUp(migrations);
}
```

See the [Migrations guide](/guide/migrations) for the full reference, including rollback for development.

## Next Steps

Now that Bavard is connected to your database, you can:

1.  **[Define your Models](/guide/models)**: Map your Dart classes to database tables.
2.  **[Create Migrations](/guide/migrations)**: Define your database structure using code.
3.  **[Configure Conventions](/guide/conventions)**: Learn how Bavard handles table and column names by default.
