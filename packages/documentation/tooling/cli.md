# CLI Tool

Bavard comes with a built-in CLI tool to help you scaffold your models and pivot tables quickly. The CLI features colored output for better readability and supports generating complete, ready-to-use code.

## Setup

To use the Bavard CLI in your project, you need to expose it through a script in your `bin/` directory. This allows you to run it using `dart run bavard`.

### Create the CLI Wrapper
Create a file at `bin/bavard.dart` in your project root:

```dart
import 'package:bavard_cli/bavard_cli.dart';
import 'package:bavard_migration/bavard_migration.dart';

void main(List<String> args) {
  // Register standard CLI commands along with migration commands
  CliRunner([
    MakeMigrationCommand(),
    MigrateCommand(),
    RollbackCommand(),
  ]).run(args);
}
```

### Configure Database for Migrations
Commands that interact with the database (like `migrate`) need to know how to connect to it. By convention, they look for a `getDatabaseAdapter()` function in `lib/config/database.dart`.

Create `lib/config/database.dart`:

```dart
import 'package:bavard/bavard.dart';

/// This function is used by the CLI to obtain a database connection.
Future<DatabaseAdapter> getDatabaseAdapter() async {
  // Return your configured adapter
  return SQLiteAdapter('database.db');
}
```

## Usage

Run the CLI using `dart run`:

```bash
dart run bavard <command> [arguments]
```

## Commands

### `make:model`

Creates a new Model class.

**Syntax:**
```bash
dart run bavard make:model <ModelName> [options]
```

**Options:**

| Option | Description | Example |
| :--- | :--- | :--- |
| `--columns` | Comma-separated list of `name:type`. Supported types: `string`, `int`, `double`, `bool`, `datetime`, `json`. | `--columns=name:string,age:int` |
| `--table` | Explicitly set the table name. Defaults to the snake_case plural of the model name. | `--table=my_users` |
| `--path` | Specify the output directory. | `--path=lib/data/models` |
| `--force` | Overwrite the file if it already exists. | `--force` |
| `--help` | Show detailed usage information and examples. | `--help` |

### Examples

**1. Basic Model**
Creates a bare-bones model with just `table` and `fromMap`.
```bash
dart run bavard make:model Product
```

**2. Model with Schema & Accessors (Recommended)**
Creates a full model with `static const schema`, typed getters/setters, and `casts`.
```bash
dart run bavard make:model User --columns=name:string,age:int,is_active:bool,metadata:json
```

**3. Custom Table & Path**
Creates a model in a specific directory with a custom table name.
```bash
dart run bavard make:model Category --table=product_categories --path=lib/features/shop/models
```

This generates:
```dart
class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  // SCHEMA
  static const schema = (
    name: TextColumn('name'),
    age: IntColumn('age'),
    isActive: BoolColumn('is_active'),
    metadata: JsonColumn('metadata'),
  );

  // ACCESSORS
  String? get name => getAttribute<String>('name');
  set name(String? value) => setAttribute('name', value);

  int? get age => getAttribute<int>('age');
  set age(int? value) => setAttribute('age', value);

  // ... (bool and json accessors)

  // CASTS
  @override
  Map<String, String> get casts => {
    'age': 'int',
    'is_active': 'bool',
    'metadata': 'json',
  };
}
```

### `make:pivot`

Creates a new Pivot class for Many-to-Many relationships. This generates a single, self-contained file with the class, schema, and typed accessors.

**Syntax:**
```bash
dart run bavard make:pivot <PivotName> [options]
```

**Options:**

| Option | Description | Example |
| :--- | :--- | :--- |
| `--columns` | Comma-separated list of `name:type`. | `--columns=is_admin:bool` |
| `--model` | Optional path to the parent model to import. Defaults to checking the sibling file. | `--model=./user.dart` |
| `--path` | Specify the output directory. | `--path=lib/models` |
| `--force` | Overwrite the file if it already exists. | `--force` |

### Examples

**1. Basic Pivot**
```bash
dart run bavard make:pivot UserRole --columns=is_active:bool,created_at:datetime
```

This generates:
```dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';

class UserRole extends Pivot {
  UserRole(super.attributes);

  static const schema = (
    isActive: BoolColumn('is_active'),
    createdAt: DateTimeColumn('created_at'),
  );

  /// Accessor for [isActive] (DB: is_active)
  bool get isActive => get(UserRole.schema.isActive);
  set isActive(bool value) => set(UserRole.schema.isActive, value);

  /// Accessor for [createdAt] (DB: created_at)
  DateTime get createdAt => get(UserRole.schema.createdAt);
  set createdAt(DateTime value) => set(UserRole.schema.createdAt, value);

  static List<Column> get columns => [
    UserRole.schema.isActive,
    UserRole.schema.createdAt,
  ];
}
```

### `make:migration`

Creates a new migration file in `database/migrations`.

**Syntax:**
```bash
dart run bavard make:migration <MigrationName>
```

**Example:**
```bash
dart run bavard make:migration create_users_table
```

### `migrate`

Executes all outstanding migrations.

**Syntax:**
```bash
dart run bavard migrate
```

### `migrate:rollback`

Rolls back the last batch of migrations.

**Syntax:**
```bash
dart run bavard migrate:rollback
```
