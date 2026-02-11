# Bavard ORM

**The Eloquent-style ORM for Dart.**

Bavard brings the elegance and simplicity of Laravel's Eloquent to the Dart ecosystem. It is designed to provide a fluent, expressive interface for database interactions, prioritizing developer experience, runtime flexibility, and readability.

## Project Structure

This is a monorepo managed with Melos (implied by structure) or simple multi-package setup.

- **`packages/bavard`**: The core Dart package source code.
- **`packages/bavard_cli`**: The Dart package CLI tool.
- **`packages/bavard_migration`**: The Dart package migration tool.
- **`packages/documentation`**: The documentation website (VitePress).
- **`packages/bavard_example_project`**: Example Flutter application using Bavard.

## Key Features

- **Runtime-first architecture:** 100% optional code generation. Uses Dart mixins and runtime reflection-like capabilities.
- **Fluent Query Builder:** Chainable methods for building SQL queries.
- **Relationships:** One-to-One, One-to-Many, Many-to-Many, Polymorphic, HasManyThrough.
- **Smart Casting:** Handles JSON, DateTime, Bool, etc.
- **Production-ready:** Soft Deletes, Timestamps, Global Scopes.
- **Database Agnostic:** SQLite and PostgreSQL support.
- **Flutter Ready:** Stream support for reactive UIs.

## Conventions

Bavard follows "Convention over Configuration".

- **Table Names:** Plural, snake_case (e.g., `User` -> `users`).
- **Primary Key:** Defaults to `id`.
- **Foreign Keys:** `{singular_table_name}_id` (e.g., `user_id`).
- **Pivot Tables:** Alphabetical order joined by underscore (e.g., `role_user` for User <-> Role).
- **Polymorphic:** `{name}_type` and `{name}_id`.
- **Timestamps:** `created_at`, `updated_at`.
- **Soft Deletes:** `deleted_at`.

## Model Implementation Rules

### Eager Loading Support
To enable eager loading via string names (e.g., `.withRelations(['posts'])`), every model with relationships **MUST** override the `getRelation` method.

```dart
@override
Relation? getRelation(String name) {
  switch (name) {
    case 'posts': return posts;
    case 'profile': return profile;
    default: return super.getRelation(name);
  }
}
```

## Development

### Testing
To run tests for the entire project:
```bash
make test
```
(This likely runs tests in each package).

### Core Package (`packages/bavard`)
- Source: `lib/`
- Tests: `test/`
- Adapters: `lib/src/database/adapters/` (inferred)
- Query Builder: `lib/src/query/` (inferred)

## Memory & Implementation Details

### Core Architecture
- **QueryBuilder & Grammar:** Uses a Strategy Pattern for SQL generation. `QueryBuilder` builds the query, `Grammar` handles dialect-specific compilation (SQLite vs Postgres).
- **Models:** Extend `Model`. Mixins like `HasTimestamps`, `HasSoftDeletes` add functionality.
- **Schema:** Type-safe column definitions (e.g., `User.schema.id`).
- **DatabaseManager:** Manages connections.

### Recent Refactors & Features (v0.0.22+)
- **Custom Attribute Casts:** Implemented `AttributeCast<T, R>` interface. `HasCasts` mixin supports these for custom Runtime <-> DB transformations.
- **Smart Dirty Checking:** Timestamps only update `updated_at` if the model is actually dirty.
- **Union Support:** `UNION`, `UNION ALL`, `INTERSECT`, `EXCEPT` implemented in `QueryBuilder`.
- **Conditional Eager Loading:** `withRelations` accepts scopes/callbacks to filter eagerly loaded relations.
- **Casting Improvements:** `HasCasts` can derive casting rules directly from `List<SchemaColumn>`.

### Fixes & Adjustments
- **Grammar Regex:** Fixed `compileColumns` regex to use `caseSensitive: false` instead of inline flags.
- **Mocking:** Updated `MockDatabaseSpy` to support normalized keys; fixed SQL assertions in tests.
- **Postgres:** Fixed `PostgresAdapter` for Blobs and SQL interpolation.