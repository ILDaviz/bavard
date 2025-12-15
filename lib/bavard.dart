/// Main entry point for the Bavard ORM library.
///
/// Exposes the core [Model], [QueryBuilder], [DatabaseManager], and relationship classes
/// required to interact with the database using the Active Record pattern.
library bavard;

// --- Metadata & Casting ---
/// Annotations for code generation and type casting definitions.
export 'src/annotations.dart';
export 'src/generators/orm_cast_type.dart';

// --- Core Model & Utilities ---
/// Core Active Record implementation and type-safe query extensions.
export 'src/core/model.dart';
export 'src/core/utils.dart';
export 'src/core/typed_query.dart';

// --- Exceptions ---
/// Custom exception types for error handling.
export 'src/core/exceptions.dart';

// --- Model Concerns ---
/// Reusable model behaviors (Mixins) for UUIDs, timestamps, soft deletes, and global scopes.
export 'src/core/concerns/has_global_scopes.dart';
export 'src/core/concerns/has_uuids.dart';
export 'src/core/concerns/has_soft_deletes.dart';
export 'src/core/concerns/has_timestamps.dart';

// --- Database & Drivers ---
/// Database connection management singleton and driver interface definitions.
export 'src/core/database_manager.dart';
export 'src/core/database_adapter.dart';

// --- Query Builder ---
/// Fluent SQL query builder implementation.
export 'src/core/query_builder.dart';

// --- Relationships ---
/// Relationship definitions (One-to-One, One-to-Many, Many-to-Many, and Polymorphic).
export 'src/relations/relation.dart';
export 'src/relations/belongs_to.dart';
export 'src/relations/belongs_to_many.dart';
export 'src/relations/has_many.dart';
export 'src/relations/has_many_through.dart';
export 'src/relations/has_one.dart';
export 'src/relations/morph_many.dart';
export 'src/relations/morph_one.dart';
export 'src/relations/morph_to.dart';
export 'src/relations/morph_to_many.dart';