# API Reference

This section serves as a high-level reference for the public API exported by Bavard. For detailed usage instructions and examples, please refer to the [Guide](../guide/).

## Core Components

The foundational classes that power the ORM.

| Class | Description | Documentation |
| :--- | :--- | :--- |
| `Model` | The abstract base class for all your entities. Handles hydration, dirty checking, and persistence. | [Creating Models](../guide/models.md) |
| `QueryBuilder<T>` | Fluent interface for constructing SQL queries safely. Returned by `User().query()`. | [Query Builder](../core/query-builder.md) |
| `DatabaseManager` | Singleton service locator for managing the active database connection and transactions. | [Initial Setup](../guide/setup.md) |
| `DatabaseAdapter` | Interface that must be implemented to connect Bavard to a specific database driver (SQLite, Postgres, etc.). | [Adapter](../reference/database-adapter.md) |

## Schema Definition

Classes used inside the `static const schema` Record to define type-safe columns.

| Column Class | Maps to Dart Type | SQL Equivalent | Description |
| :--- | :--- | :--- | :--- |
| `TextColumn` | `String` | `TEXT` / `VARCHAR` | Supports `contains`, `startsWith`, `endsWith`. |
| `IntColumn` | `int` | `INTEGER` | Supports numeric comparisons (`>`, `<`, etc.). |
| `DoubleColumn` | `double` | `REAL` / `DOUBLE` | Supports numeric comparisons. |
| `BoolColumn` | `bool` | `INTEGER` (0/1) | Stores boolean values as integers for compatibility. |
| `DateTimeColumn` | `DateTime` | `TEXT` (ISO-8601) | Stores dates as standardized strings. |
| `JsonColumn` | `dynamic` | `TEXT` (JSON) | Stores Maps/Lists. Enables [JsonPath](../core/schema-columns.md#jsoncolumn-jsonpathcolumn) querying. |
| `EnumColumn<T>` | `Enum` | `TEXT` | Stores the `name` of the Enum. |

## Relationships

Classes representing the associations between models.

### Standard Relations

| Relation | Type | Description |
| :--- | :--- | :--- |
| `HasOne<R>` | 1:1 | The foreign key is on the **related** table. |
| `HasMany<R>` | 1:N | The foreign key is on the **related** table. |
| `BelongsTo<R>` | 1:1 / N:1 | The foreign key is on the **current** table. |
| `BelongsToMany<R>` | N:N | Uses an intermediate **pivot table**. |
| `HasManyThrough<R, I>` | Distant 1:N | Access a related model via an **intermediate** model. |

### Polymorphic Relations

| Relation | Description |
| :--- | :--- |
| `MorphTo<T>` | The "child" side. Stores `_id` and `_type`. Can belong to multiple parent types. |
| `MorphOne<R>` | A parent has one polymorphic child (e.g., a Post has one Image). |
| `MorphMany<R>` | A parent has many polymorphic children (e.g., a Video has many Comments). |
| `MorphToMany<R>` | Many-to-Many via a polymorphic pivot table (e.g., Tags on Posts and Videos). |

## Mixins (Concerns)

Traits you can add to your `Model` to enable specific behaviors.

| Mixin | Functionality |
| :--- | :--- |
| `HasTimestamps` | Automatically manages `created_at` and `updated_at`. |
| `HasSoftDeletes` | Enables "trash" functionality. Records are marked as deleted (via `deleted_at`) instead of removed. |
| `HasUuids` | Automatically generates UUID v4 strings for the primary key. |
| `HasGlobalScopes` | Allows registering queries that apply to every fetch operation (e.g., Multi-Tenancy). |

## Exceptions

Exceptions thrown by the framework that you should handle.

| Exception | Cause |
| :--- | :--- |
| `ModelNotFoundException` | Thrown by `findOrFail()` or `firstOrFail()` when no result is found. |
| `QueryException` | Thrown when a raw SQL error occurs (syntax error, constraint violation). |
| `TransactionException` | Thrown when a transaction fails or is explicitly rolled back. |
| `InvalidQueryException` | Thrown when the QueryBuilder detects unsafe or malformed input. |
| `DatabaseNotInitializedException` | Thrown if you try to use a Model before calling `setDatabase()`. |

## Annotations & Tooling

| Symbol | Description |
| :--- | :--- |
| `@fillable` | Annotation to mark a class for [Code Generation](../tooling/code-generation.md). |
| `MockDatabaseSpy` | A test utility to spy on generated SQL and mock results. |
