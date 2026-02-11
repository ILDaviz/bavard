# Bavard Migration

**Package:** `packages/bavard_migration`
**Description:** Schema management system for defining and versioning database structure changes.

## Core Concepts

### Migration Files
- Stored in `database/migrations` (configurable).
- Class extends `Migration`.
- Implements `up(Schema schema)` and `down(Schema schema)`.

### Schema Builder
- **Fluent Interface:** `schema.create('users', (table) { ... })`.
- **Blueprint:** The `table` callback object defines columns and constraints.

### Supported Operations
- **Create Table:** `schema.create(...)`
- **Modify Table:** `schema.table(..., (table) { ... })`
  - Add columns: `table.string('new_col')`
  - Drop columns: `table.dropColumn('old_col')`
  - Rename columns: `table.renameColumn('old', 'new')`
  - Change columns: `table.string('col').nullable().change()` (limited SQLite support).
- **Drop Table:** `schema.drop(...)` / `schema.dropIfExists(...)`

### Column Definitions
Supports extensive column types mapping to SQL equivalents:
- **Integers:** `id`, `increments`, `integer`, `tinyInteger`, `smallInteger`, `mediumInteger`, `bigInteger`, `unsignedInteger`.
- **Strings:** `string` (varchar), `text`, `mediumText`, `longText`, `char`.
- **Dates:** `date`, `dateTime`, `dateTimeTz`, `time`, `timeTz`, `timestamp`, `timestampTz`.
- **Special:**
  - `timestamps()`: Adds nullable `created_at` and `updated_at`.
  - `softDeletes()`: Adds nullable `deleted_at`.
  - `uuid`, `json`, `jsonb`, `binary` (blob), `boolean`.
  - `ipAddress`, `macAddress`.
  - `morphs('taggable')`: Adds `taggable_id` (bigint) + `taggable_type`.
  - `uuidMorphs('taggable')`: Adds `taggable_id` (uuid) + `taggable_type`.

### Modifiers
Chain these to column definitions:
- `.nullable()`
- `.defaultTo(value)`
- `.unsigned()`
- `.unique()`
- `.primary()`
- `.useCurrentTimestamp()` (for timestamps)

### Constraints & Indexes
- **Primary Keys:** `table.primary(['col1', 'col2'])`.
- **Indexes:** `table.index('col')`, `table.unique('col')`, `table.fullText('col')`, `table.spatialIndex('col')`.
- **Foreign Keys:**
  ```dart
  table.foreign('user_id')
       .references('id')
       .on('users')
       .onDelete('cascade')
       .onUpdate('cascade');
  ```