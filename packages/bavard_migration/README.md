# Bavard Migration

Migration system for the [Bavard ORM](https://github.com/ILDaviz/bavard).
This package provides the core migration logic and commands to manage your database schema.

## 📚 Documentation

For detailed guides, API references, and usage examples, please visit our documentation:

👉 **[Read the Documentation](https://ildaviz.github.io/bavard/)**

## Commands

### Make Migration

Create a new migration file.

```bash
dart run bavard make:migration <MigrationName> [options]
```

**Options:**
- `--path=<dir>`: Specify a custom directory for migration files (defaults to `database/migrations`).

**Example:**

```bash
dart run bavard make:migration create_users_table
```

### Migrate

Run the database migrations.
Requires `lib/config/database.dart` exporting `Future<DatabaseAdapter> getDatabaseAdapter()`.

```bash
dart run bavard migrate [options]
```

**Options:**
- `--path=<dir>`: Specify a custom directory for migration files (defaults to `database/migrations`).

**Example:**

```bash
dart run bavard migrate
```

### Rollback

Rollback the last database migration batch.

```bash
dart run bavard migrate:rollback [options]
```

**Options:**
- `--path=<dir>`: Specify a custom directory for migration files (defaults to `database/migrations`).

**Example:**

```bash
dart run bavard migrate:rollback
```
