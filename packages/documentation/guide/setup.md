# Initial Setup

Before you can use Bavard, you need to tell it which database to use by registering a **Database Adapter**. This connection should be established once during your application's startup.

## Database Connection

Bavard is driver-agnostic. You can use it with SQLite (via `sqflite` or `sqlite3`), PostgreSQL, PowerSync or any other SQL database by wrapping the connection in an adapter.

```dart
import 'package:bavard/bavard.dart';

void main() async {
  // Initialize your database connection (e.g., SQLite)
  final adapter = SQLiteAdapter('my_database.db'); 

  // Register the adapter with the DatabaseManager
  DatabaseManager().setDatabase(adapter);

  // Your models are now ready to use!
}
```

## Migration Setup (Optional)

If you are using the `bavard_migration` package, you can also use the `Migrator` during initialization to ensure your database schema is up to date.

Typically, this is handled via the CLI in development, but you can trigger it programmatically if needed:

```dart
import 'package:bavard/bavard.dart';
import 'package:bavard_migration/bavard_migration.dart';

Future<void> initializeDatabase() async {
  final adapter = SQLiteAdapter('path/to/db');
  DatabaseManager().setDatabase(adapter);

  // Initialize the migration repository and migrator
  final repository = MigrationRepository(adapter);
  final migrator = Migrator(adapter, repository);

  // In production, you might want to run this carefully
  // await migrator.runUp(allMyMigrations);
}
```

## CLI Setup (Recommended)

To streamline your development, you should set up the Bavard CLI. This allows you to generate models, pivot tables, and run migrations directly from your terminal.

Create a file at `bin/bavard.dart` in your project:

```dart
import 'package:bavard_cli/bavard_cli.dart';
import 'package:bavard_migration/bavard_migration.dart';

void main(List<String> args) {
  // Registering both standard and migration commands
  CliRunner([
    MakeMigrationCommand(),
    MigrateCommand(),
    RollbackCommand(),
  ]).run(args);
}
```

Now you can use the CLI using `dart run bavard`. Check the [CLI Documentation](/tooling/cli) for a full list of commands.

## Next Steps

Now that Bavard is connected to your database, you can:

1.  **[Define your Models](/guide/models)**: Map your Dart classes to database tables.
2.  **[Create Migrations](/guide/migrations)**: Define your database structure using code.
3.  **[Configure Conventions](/guide/conventions)**: Learn how Bavard handles table and column names by default.
