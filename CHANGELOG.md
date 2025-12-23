# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
