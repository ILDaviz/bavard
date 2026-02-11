# Database Migrations

Migrations are like version control for your database, allowing your team to define and share the application's database schema definition. If you have ever had to tell a teammate to manually add a column to their local database schema, you've faced the problem that database migrations solve.

Bavard's migration system provides a simple way to build and modify tables using a fluent, database-agnostic interface.

## Introduction

Migrations are stored in the root directory `database/migrations` in your project. Each migration file contains a class that extends `Migration` and defines two methods: `up` and `down`.

- The `up` method is used to add new tables, columns, or indexes to your database.
- The `down` method should reverse the operations performed by the `up` method.

## Generating Migrations

To create a new migration, use the `make:migration` CLI command:

```bash
dart run bavard make:migration create_users_table
```

This will create a new file in your `database/migrations` directory. The file name includes a timestamp to ensure migrations run in the correct order.

> [!INFO]
> You can change the base path where migrations are located by specifying `--path=`

## Migration Structure

A migration class looks like this:

```dart
import 'package:bavard_migration/bavard_migration.dart';

class CreateUsersTable extends Migration {
  @override
  Future<void> up(Schema schema) async {
    await schema.create('users', (Blueprint table) {
      table.id();
      table.string('name');
      table.string('email').unique();
      table.timestamps();
    });
  }

  @override
  Future<void> down(Schema schema) async {
    await schema.dropIfExists('users');
  }
}
```

## Running Migrations

To run all of your outstanding migrations, execute the `migrate` command:

```bash
dart run bavard migrate
```

This command will run all migrations that haven't been executed yet, in date order.

### Rolling Back Migrations

To reverse the last batch of migrations that were run, use the `migrate:rollback` command:

```bash
dart run bavard migrate:rollback
```

This will call the `down` method of the migrations in the last batch.

## Tables

### Creating Tables

To create a new table, use the `create` method on the `Schema` object. The `create` method accepts two arguments: the name of the table and a callback that receives a `Blueprint` object, which you can use to define the new table:

```dart
await schema.create('users', (Blueprint table) {
  table.id();
  table.string('username');
});
```

### Modifying Tables

To update an existing table, use the `table` method. This allows you to add or drop columns and indexes:

```dart
await schema.table('users', (Blueprint table) {
  table.string('phone').nullable(); // Add a new column
  table.dropColumn('age');          // Drop an existing column
  table.renameColumn('bio', 'description'); // Rename a column
});
```

> **Note:** When using SQLite, some operations (like dropping foreign keys or modifying columns) might be limited or require a table rebuild. Bavard handles basic operations seamlessly, but complex modifications on SQLite should be tested carefully.

### Dropping Tables

To drop an existing table, you may use the `drop` or `dropIfExists` methods:

```dart
await schema.drop('users');

await schema.dropIfExists('users');
```

## Blueprint Reference

The `Blueprint` object passed to your migration callbacks offers a wide range of methods to define your table structure.

### Column Types

| Method | Description |
| :--- | :--- |
| `bigIncrements('id')` | Auto-incrementing `UNSIGNED BIGINT` (Primary Key). |
| `increments('id')` | Auto-incrementing `UNSIGNED INTEGER` (Primary Key). |
| `id()` | Alias for `bigIncrements('id')`. |
| `string('name', [length])` | `VARCHAR` column with optional length (default 255). |
| `text('description')` | `TEXT` column. |
| `mediumText('body')` | `MEDIUMTEXT` column. |
| `longText('history')` | `LONGTEXT` column. |
| `char('code', [length])` | `CHAR` column with fixed length. |
| `integer('votes')` | `INTEGER` column. |
| `tinyInteger('status')` | `TINYINT` column. |
| `smallInteger('rank')` | `SMALLINT` column. |
| `mediumInteger('code')` | `MEDIUMINT` column. |
| `bigInteger('views')` | `BIGINT` column. |
| `unsignedInteger('age')` | `UNSIGNED INTEGER` column. |
| `float('amount')` | `FLOAT` column. |
| `double('precision')` | `DOUBLE` column. |
| `decimal('price', [p, s])` | `DECIMAL` column with precision and scale. |
| `boolean('confirmed')` | `BOOLEAN` column. |
| `date('dob')` | `DATE` column. |
| `dateTime('created_at')` | `DATETIME` column. |
| `dateTimeTz('created_at')` | `DATETIME` with Timezone. |
| `time('start')` | `TIME` column. |
| `timeTz('start')` | `TIME` with Timezone. |
| `timestamp('added_on')` | `TIMESTAMP` column. |
| `timestampTz('added_on')` | `TIMESTAMP` with Timezone. |
| `timestamps()` | Adds nullable `created_at` and `updated_at`. |
| `timestampsTz()` | Adds nullable timezone-aware `created_at` and `updated_at`. |
| `softDeletes()` | Adds nullable `deleted_at` timestamp. |
| `softDeletesTz()` | Adds nullable timezone-aware `deleted_at`. |
| `binary('data')` | `BLOB` / Binary column. |
| `json('options')` | `JSON` column. |
| `jsonb('meta')` | `JSONB` column (Binary JSON). |
| `uuid('uid')` | `UUID` column. |
| `ipAddress('visitor')` | IP Address column. |
| `macAddress('device')` | MAC Address column. |
| `enumCol('role', ['admin', 'user'])` | `ENUM` column with allowed values. |
| `rememberToken()` | Adds nullable `remember_token` VARCHAR(100). |
| `morphs('taggable')` | Adds `taggable_id` (unsigned big int) and `taggable_type`. |
| `uuidMorphs('taggable')` | Adds `taggable_id` (UUID) and `taggable_type`. |

### Column Modifiers

You can chain these methods onto any column definition:

| Modifier | Description |
| :--- | :--- |
| `.nullable()` | Allows NULL values to be inserted into the column. |
| `.defaultTo(value)` | Declare a "default" value for the column. |
| `.unsigned()` | Set `INTEGER` columns to `UNSIGNED`. |
| `.useCurrentTimestamp()` | Set `TIMESTAMP` columns to use `CURRENT_TIMESTAMP` as default. |
| `.unique()` | Add a unique index to the column. |
| `.primary()` | Add a primary key index to the column. |
| `.change()` | Mark the column to be modified (for `ALTER TABLE` operations). |

### Indexing

| Method | Description |
| :--- | :--- |
| `primary('id')` | Add a primary key. |
| `primary(['first', 'last'])` | Add a composite primary key. |
| `unique('email')` | Add a unique index. |
| `index('state')` | Add a basic index. |
| `fullText('body')` | Add a FullText index. |
| `spatialIndex('location')` | Add a Spatial index. |
| `foreign('user_id')` | Start defining a foreign key constraint. |

### Foreign Key Constraints

Use the `foreign` method to define constraints:

```dart
table.foreign('user_id')
     .references('id')
     .on('users')
     .onDelete('cascade');
```

Available methods on the foreign key definition:
- `references('column')`: The column on the parent table.
- `on('table')`: The parent table name.
- `onDelete('action')`: Action for delete (e.g., `cascade`, `set null`).
- `onUpdate('action')`: Action for update.

