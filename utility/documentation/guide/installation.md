# Installation

Bavard ships as a single package: the Model, Query Builder, Relationship engine, and the runtime migration system are all included.

## Install

```bash
dart pub add bavard
```

---

## Summary of `pubspec.yaml`

A standard setup for a new project looks like this:

```yaml
dependencies:
  bavard: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0      # Optional, only if using code generation
```

::: tip Migrating from the old packages?
The former `bavard_migration` and `bavard_cli` packages have been discontinued. The migration engine is now part of `bavard` itself (see the [Migrations guide](/guide/migrations)), and model/pivot scaffolding is covered by the copy-paste templates in the [Models](/guide/models) and [Relationships](/relationships/) guides.
:::

## Requirements

- **Dart SDK**: `^3.10.1` (or compatible Flutter version)
- **Platforms**: Mobile (iOS/Android), Desktop (macOS/Windows/Linux), Web, and Server.
