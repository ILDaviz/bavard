# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.0.8] - 2025-12-24

### Changed
- **Documentation:** Change locations.
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
