# Bavard CLI

**Package:** `packages/bavard_cli`
**Description:** Command-line tools for scaffolding models, pivot tables, and managing migrations.

## Setup
Requires a wrapper script in `bin/bavard.dart` to expose the CLI to the project.

```dart
// bin/bavard.dart
void main(List<String> args) {
  CliRunner([
    MakeMigrationCommand(),
    MigrateCommand(),
    RollbackCommand(),
  ]).run(args);
}
```

## Commands

### `make:model`
Scaffolds a new model file with optional schema definitions.
- **Syntax:** `dart run bavard make:model <Name> [options]`
- **Options:**
  - `--columns=name:type`: Pre-define columns (e.g., `name:string,age:int`).
    - Supported types: `string`, `int`, `double`, `num`, `bool`, `datetime`, `blob`, `json`.
  - `--table=name`: Explicitly set custom table name.
  - `--path=dir`: Specify output directory (defaults to `lib/models` or similar based on context).
  - `--force`: Overwrite existing files.
- **Output:** Generates a class extending `Model` with `schema` definition (record type), typed getters/setters, and `casts` map overrides.

### `make:pivot`
Scaffolds a Pivot model for many-to-many relationships.
- **Syntax:** `dart run bavard make:pivot <Name> [options]`
- **Options:**
  - `--columns=name:type`: Define extra columns on the pivot table.
  - `--model=path`: Optional path to parent model (defaults to checking sibling files).
  - `--path=dir`: Output directory.
  - `--force`: Overwrite existing.
- **Output:** Generates a class extending `Pivot`.

### `make:migration`
Creates a timestamped migration file in `database/migrations`.
- **Syntax:** `dart run bavard make:migration <Name> [options]`
- **Options:**
  - `--path=dir`: Custom directory for migration files.

### Database Operations
- `migrate`: Runs all pending migrations.
- `migrate:rollback`: Reverts the last batch of migrations.
- **Config:** CLI looks for `lib/config/database.dart` exporting `Future<DatabaseAdapter> getDatabaseAdapter()` to establish connection.