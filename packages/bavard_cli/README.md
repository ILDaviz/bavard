# Bavard CLI

Command-line interface for the [Bavard ORM](https://github.com/ILDaviz/bavard).
This tool helps you quickly generate models and pivot tables for your Bavard project.

## Installation

You can install the CLI globally using Dart:

```bash
dart pub global activate bavard_cli
```

Or run it directly if included in your project dev_dependencies:

```bash
dart run bavard_cli:bavard <command>
```

## Usage

### Make Model

Generates a new Bavard model file.

```bash
bavard make:model <ModelName> [options]
```

**Options:**
- `--table=names`: Specify a custom table name (defaults to snake_case plural of model name).
- `--columns=name:type,age:int`: Define columns with types (supported: string, int, double, num, bool, datetime, blob).
- `--force`: Overwrite existing files.

**Example:**

```bash
bavard make:model User --columns=name:string,email:string,age:int --table=users
```

### Make Pivot

Generates a new Pivot model for many-to-many relationships.

```bash
bavard make:pivot <PivotName> [options]
```

**Options:**
- `--columns=is_admin:bool`: Define extra columns on the pivot table.
- `--force`: Overwrite existing files.

**Example:**

```bash
bavard make:pivot UserRole --columns=is_active:bool,assigned_at:datetime
```
