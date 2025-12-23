# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.0.3] - 2025-12-23

### Added
- **Pivots:** Added typed pivot support for many-to-many relations, allowing type-safe access to pivot data.
- **Pivots:** Allowed retrieving extra pivot columns without requiring a custom pivot class definition.
- **Core:** Introduced `Grammar` strategy pattern for SQL dialect abstraction, supporting SQLite and Postgres.

### Changed
- **Core:** Reworked attribute casting and hydration logic for better performance and reliability.
- **Core:** Refactored code generation annotations and logic for consistency.
- **Pivots:** Improved pivot type casting and added setter support.
- **Pivots:** Updated pivot schema definitions to use static records for cleaner syntax.
- **Structure:** Optimized library exports and removed unnecessary imports.

### Documentation
- Added reference implementations for database adapters.
- Expanded Query Builder documentation.
- Updated pivot schema definition guide.
- Added installation and quick start guides to README.