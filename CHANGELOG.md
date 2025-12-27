# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **Core:** Support for **Custom Attribute Casts** via the `AttributeCast<T, R>` interface.
- **Core:** Added smart **Dirty Checking for Timestamps**. `updated_at` is now only updated if the model has other dirty attributes, preventing redundant queries.
- **Schema:** Standard columns (`IdColumn`, `CreatedAtColumn`, etc.) now have **default names**, enabling zero-config automatic casting.
- **Testing:** New **Shared Integration Test Suite** in `example/shared_test_suite`.
- **Testing:** Added 5 new integration scenarios: Concurrency, Blob support, Unique constraints, UTC Date handling, and Dirty Checking optimization.
- **Tooling:** Added `make test-all` to the `Makefile` for a full one-shot test execution (Unit + SQLite + Postgres).

### Improved
- **Adapters:** Enhanced `PostgresAdapter` to handle binary data (Blobs) using `TypedValue` and fixed SQL placeholder interpolation.
- **Core:** Refactored `HasTimestamps` to use the internal casting system instead of raw attribute access.

## [0.0.22] - 2025-12-27

### Added
- **Core:** Refactored `HasCasts` to automatically derive casting rules from the `columns` list (Schema), eliminating the need for a manual `casts` map in most cases.
- **Documentation:** Updated "Type Casting" and "Model" guides to prioritize schema-driven casting and added examples for manual implementations.

### Improved
- **Core:** Enhanced internal type mapping between SQL schema types (`integer`, `boolean`, `doubleType`) and Dart runtime types (`int`, `bool`, `double`).

## [0.0.21] - 2025-12-27

### Added
- **Core:** Added `distinct()` method to `QueryBuilder` to support `SELECT DISTINCT` queries.

### Fixed
- **Core:** Fixed `HasSoftDeletes` mixin to correctly handle `deletedAt` type compatibility (getter `DateTime?`, setter `DateTime?`) and corrected internal key typo (`delete_at` -> `deleted_at`).

## [0.0.20] - 2025-12-26

### Fixed
- **Core:** Fixed type created_at, updated_at

## [0.0.19] - 2025-12-26

### Fixed
- **Core:** Fixed type created_at, updated_at and cancel_at

## [0.0.18] - 2025-12-26

### Added
- **Schema:** Added `IdColumn`, `CreatedAtColumn`, `UpdatedAtColumn`, and `DeletedAtColumn` to enable fully type-safe queries on standard fields.
- **Mixins:** Added typed getters/setters (`createdAt`, `updatedAt`, `deletedAt`) directly to `HasTimestamps` and `HasSoftDeletes` mixins.
- **QueryBuilder:** Implemented dynamic column name resolution. Standard columns in the schema (e.g. `User.schema.id`) now automatically resolve to the model's actual configuration (e.g. `primaryKey`) at runtime.

### Improved
- **Generator:** The `@fillable` generator now intelligently ignores standard columns if the corresponding mixins are present, preventing code duplication and conflicts.
- **Schema:** Refactored `Column` hierarchy to support polymorphic column lists via `SchemaColumn` interface, fixing type variance issues in many-to-many pivots.
- **Documentation:** Updated code generation guide to showcase the new concise schema definition style and explained standard column behavior.

### Documentation
- **Core:** Clarified that code generation is completely optional; Bavard is designed to work entirely at runtime using standard Dart syntax.
- **Guides:** Added comprehensive instructions for manual model and pivot class implementation (without `build_runner`).
- **Home:** Updated features list to highlight "Zero boilerplate", "Offline-first", and "Smart Data Casting".
- **API Reference:** Reorganized documentation to distinguish between core (included) and optional mixins.

## [0.0.17] - 2025-12-24

### Added
- **Relations:** Added `attach()` and `detach()` methods to `BelongsToMany` for easy management of many-to-many relationships.
- **Examples:** Added a comprehensive **PostgreSQL + Docker integration test suite** in `example/postgresql-docker`.
- **Core:** Allow `Column` objects as keys in `insert` and `update` methods.
- **Tests:** Added dedicated unit tests for `BelongsToMany` attach/detach operations.

### Improved
- **Core:** Enhanced `QueryBuilder.avg()` to robustly handle numeric string results, improving compatibility with PostgreSQL numeric types.
- **Examples:** Refactored `sqlite-docker` and `postgresql-docker` examples to eliminate raw SQL queries in favor of ORM-native methods.

### Fixed
- **Core:** Quote table and column names in SQL queries to prevent syntax errors.

### Changed
- **Dependencies:** Update project dependencies.
- **Tests:** Update mocks for database grammar wrap.

## [0.0.16] - 2025-12-24

### Changed
- **Dependencies:** Update dependencies

## [0.0.15] - 2025-12-24

### Changed
- **Dependencies:** Update dependencies

## [0.0.14] - 2025-12-24

### Changed
- **Dependencies:** Update dependencies

## [0.0.13] - 2025-12-24

### Changed
- **Dependencies:** Update dependencies

## [0.0.12] - 2025-12-24

### Changed
- **Dependencies:** Update dependencies

## [0.0.11] - 2025-12-24

### Changed
- **Dependencies:** Update dependencies

## [0.0.11] - 2025-12-24

### Changed
- **Dependencies:** Update dependencies

## [0.0.10] - 2025-12-24

### Added
- **Core:** Enhanced `QueryBuilder` with comprehensive support for `Column` objects across all methods (`select`, `where`, `groupBy`, `orderBy`, `count`, `sum`, etc.), enabling fully type-safe queries.
- **Core:** Added automatic table prefixing (e.g., `"users"."id"`) when using `Column` objects to prevent column ambiguity during joins.
- **Core:** Added `whereColumn` and `orWhereColumn` methods for comparing two columns.
- **Core:** Added `whereBetween`, `orWhereBetween`, `whereNotBetween`, and `orWhereNotBetween` methods.
- **Relations:** Added support for `Column` objects in `BelongsToMany` pivot filters (`wherePivot`, `withPivot`, etc.) with automatic pivot table prefixing.
- **Security:** Added strict validation and helpful error messages when passing invalid arguments (like `WhereCondition`) to `QueryBuilder` methods.

### Fixed
- **Documentation:** Fixed 404 error on API index page and improved navigation.
- **Core:** Fixed identifier quoting in aggregate functions for better dialect compatibility.

## [0.0.9] - 2025-12-24

### Changed
- **Documentation:** Update doc.

## [0.0.8] - 2025-12-24

### Changed
- **Documentation:** Update doc.
- **Examples:** Change locations.


## [0.0.7] - 2025-12-24

### Added
- **Core:** Added **Dirty Checking** support to `Model` (`isDirty()`, `getDirty()`) for optimized updates.
- **Relations:** Added `hasManyThroughPolymorphic` to natively support distant polymorphic relations.
- **Utils:** Improved `singularize` utility to handle common English rules (e.g. `-es`, `-ies`, irregulars) without external dependencies.
- **Examples:** Added a comprehensive **SQLite + Docker integration test suite** in `examples/sqlite-docker`.
- **Documentation:** Added detailed guides for "Constraining Relations", "Polymorphic HasManyThrough", and "Dirty Checking".

## [0.0.6] - 2025-12-23

### Added
- **Relations:** Added support for nested relations (e.g., `user.posts.comments`) in eager loading and querying.

## [0.0.5] - 2025-12-23

### Changed
- **Documentation:** Updated import examples in guide and index page.
- **Core:** Removed unused imports and cleaned up code.

## [0.0.4] - 2025-12-23

### Added
- **Pivots:** Added typed pivot support for many-to-many relations, allowing type-safe access to pivot data.
- **Pivots:** Allowed retrieving extra pivot columns without requiring a custom pivot class definition.
- **Documentation:** Added reference implementations for database adapters.

### Changed
- **Core:** Reworked attribute casting and hydration logic for better performance and reliability.
- **Core:** Refactored code generation annotations and logic for consistency.
- **Pivots:** Improved pivot type casting and added setter support.
- **Pivots:** Updated pivot schema definitions to use static records for cleaner syntax.

## [0.0.3] - 2025-12-23

### Added
- **Core:** Introduced `Grammar` strategy pattern for SQL dialect abstraction, supporting SQLite and Postgres.
- **Core:** Implemented AST-based schema parser for fillable generator.
- **Documentation:** Added initial project documentation with VitePress.
- **CI:** Added GitHub Actions workflow to deploy documentation.

### Changed
- **Core:** Overhauled `where` clause with typed column objects and conditions.
- **Core:** Refactored imports and exports for cleaner library structure.
