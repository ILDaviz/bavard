# Installation

Bavard is split into multiple packages so you can keep your dependencies lean.

## Core Package (Required)

The core package provides the Model, Query Builder, and Relationship engine. This is all you need to start querying existing databases.

```bash
dart pub add bavard
```

## Tooling Suite (Migrations & CLI)

To manage your database schema and scaffold code efficiently, you should install both the migration engine and the CLI tool. They work together to provide the full developer experience.

Add the migration runtime to your dependencies:
```bash
dart pub add bavard_migration
```

And add the CLI tool to your development dependencies:
```bash
dart pub add --dev bavard_cli
```

---

## Summary of `pubspec.yaml`

A standard setup for a new project looks like this:

```yaml
dependencies:
  bavard: ^0.0.1
  bavard_migration: ^0.0.1  # Runtime for migrations

dev_dependencies:
  bavard_cli: ^0.0.1        # CLI for scaffolding and running migrations
  build_runner: ^2.4.0      # Optional, only if using code generation
```

## Requirements

- **Dart SDK**: `^3.10.1` (or compatible Flutter version)
- **Platforms**: Mobile (iOS/Android), Desktop (macOS/Windows/Linux), and Server.
