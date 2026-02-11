# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **Initial Release:** Extracted CLI tools into a dedicated `bavard_cli` package.
- **Scaffolding:**
    - `make:model`: Generate Model classes.
    - `make:pivot`: Generate Pivot classes.
- **Migrations:**
    - `make:migration`: Create new migration files.
    - `migrate`: Run pending migrations.
    - `migrate:rollback`: Rollback the last batch of migrations.
    - `migrate:reset`: Rollback all migrations.
    - `migrate:refresh`: Reset and re-run all migrations.
