# Bavard Core

**Package:** `packages/bavard`
**Description:** The core ORM library providing the Active Record pattern, query builder, and relationship management.

## Key Features

### Model Architecture
- **Base Class:** All models extend `Model`.
- **Runtime Architecture:**
  - Uses `noSuchMethod` and internal attribute maps (`attributes` for current state, `original` for dirty checking).
  - Hydration/Dehydration logic bridges raw DB values and Dart objects.
- **Mixins:** Modular functionality via mixins:
  - `HasTimestamps`: Adds `created_at` / `updated_at`.
  - `HasSoftDeletes`: Adds `deleted_at` handling.
  - `HasUuids`: Auto-generates UUIDs for primary keys.
  - `HasGlobalScopes`: Applies default query constraints.
  - `HasCasts`: Handles attribute casting (see below).

### Type Casting & Schema
- **Schema Definition:** Recommended approach is defining `List<SchemaColumn> get columns` in the model. This enables runtime casting *and* static type safety.
- **Supported Types:** `int`, `double`, `bool`, `datetime` (ISO-8601), `json`, `array` (List), `object` (Map).
- **Custom Casts:** Implement `AttributeCast<T, R>` interface (where `T` is runtime type, `R` is DB type) and register in `casts` map.
- **Enums:** Helper `getEnum('col', Enum.values)` available.

### Query Builder
- **Fluent Interface:** `User.query().where(...).orderBy(...).get()`.
- **Retrieval Methods:**
  - `get()`: Returns `List<T>`.
  - `first()`, `find(id)`: Returns `T?`.
  - `findOrFail(id)`, `firstOrFail()`: Throws `ModelNotFoundException`.
  - `cursor()`: Stream-based iteration for large datasets.
  - `watch()`: Reactive stream for Flutter apps.
- **Clauses:**
  - `select`, `selectRaw`, `distinct`.
  - `where`, `orWhere`, `whereIn`, `whereNull`, `whereBetween`.
  - `whereColumn` (compare two columns).
  - `whereExists`, `whereRaw`.
  - `join`, `leftJoin`, `rightJoin`.
  - `groupBy`, `having`, `havingRaw`.
  - `limit`, `offset`.
  - `union`, `unionAll`, `intersect`, `except`.
- **Aggregates:** `count`, `max`, `min`, `avg`, `sum`.
- **Write Operations:**
  - `insert(Map)`, `insertAll(List<Map>)` (Raw inserts, bypasses hooks).
  - `update(Map)` (Bulk update).
  - `delete()` (Bulk delete).

### Relationships
Supports a full suite of Laravel-style relationships:
- **Basic:** `HasOne`, `HasMany`, `BelongsTo`.
- **Many-to-Many:** `BelongsToMany` (with `Pivot` models).
  - Pivot filtering: `wherePivot`, `wherePivotIn`, `wherePivotCondition`.
- **Polymorphic:** `MorphOne`, `MorphMany`, `MorphTo`, `MorphToMany`.
- **Advanced:** `HasManyThrough`.
- **Eager Loading:** `withRelations(['posts', 'profile'])` to solve N+1.

### Lifecycle Hooks
Override these methods in your Model to hook into events:
- `onSaving()`: Before create/update. Return `false` to cancel.
- `onSaved()`: After save.
- `onDeleting()`: Before delete. Return `false` to cancel.
- `onDeleted()`: After delete.
> **Note:** Bulk operations (`query().update()`, `query().delete()`) bypass these hooks.

### Transactions
- Use `DatabaseManager().transaction((txn) async { ... })`.
- Model operations inside the callback automatically participate in the transaction.

## Directory Structure
- `lib/bavard.dart`: Main export.
- `lib/src/core/`: Core logic (Model, QueryBuilder, DatabaseManager).
- `lib/src/relations/`: Relationship implementations.
- `lib/src/grammars/`: SQL dialect implementations.