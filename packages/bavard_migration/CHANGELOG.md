# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **Initial Release:** Introduced `bavard_migration` package for managing database schema changes.
- **Core:**
    - `Migrator`: Manages the execution and rollback of migrations.
    - `MigrationRepository`: Tracks executed migrations in the database.
- **Schema Builder:**
    - `Schema.create`: Create new tables.
    - `Schema.table`: Modify existing tables (add/change/drop columns).
    - `Schema.drop`: Drop tables.
    - `Schema.dropIfExists`: Drop tables if they exist.
- **Blueprint:**
    - Fluent interface for defining columns (`string()`, `integer()`, `boolean()`, etc.).
    - Support for column modifiers (`nullable()`, `default()`, `unique()`).
    - Support for dropping columns (`dropColumn()`).
    - Support for renaming columns (`renameColumn()`).
