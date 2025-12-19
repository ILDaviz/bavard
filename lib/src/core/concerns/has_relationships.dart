import '../model.dart';
import '../utils.dart';
import '../../relations/relation.dart';
import '../../relations/has_one.dart';
import '../../relations/has_many.dart';
import '../../relations/belongs_to.dart';
import '../../relations/belongs_to_many.dart';
import '../../relations/has_many_through.dart';
import '../../relations/morph_many.dart';
import '../../relations/morph_one.dart';
import '../../relations/morph_to.dart';
import '../../relations/morph_to_many.dart';

/// Provides a DSL for defining Eloquent-style relationships.
///
/// Relies heavily on "Convention over Configuration" to infer Foreign/Local keys
/// based on model class names and table definitions, unless explicitly overridden.
mixin HasRelationships {
  // --- Abstract Requirements ---

  /// The table name of the current model, used to generate default Foreign Keys (e.g., `user_id`).
  String get table;

  /// The primary key value, required to bind relation queries to this specific instance.
  dynamic get id;

  /// The primary key column name (usually 'id').
  String get primaryKey;

  /// Cache registry for eager-loaded relationships to prevent N+1 queries.
  Map<String, dynamic> get relations;

  /// Accessor for hydration logic to retrieve cached/eager-loaded data.
  Relation? getRelation(String name) => null;

  /// Helper casting to [Model] to satisfy strict typing in relation constructors.
  Model get _asModel => this as Model;

  // --- Relationship Definitions ---

  /// Defines a 1:1 relationship where the Foreign Key resides on the related model [R].
  ///
  /// Example: User has one Phone. (Phone table has `user_id`).
  HasOne<R> hasOne<R extends Model>(
    R Function(Map<String, dynamic>) creator, {
    String? foreignKey,
    String? localKey,
  }) {
    return HasOne<R>(
      _asModel,
      creator,
      foreignKey ?? Utils.foreignKey(table),
      localKey ?? primaryKey,
    );
  }

  /// Defines a 1:N relationship where the Foreign Key resides on the related model [R].
  ///
  /// Example: Blog has many Posts. (Post table has `blog_id`).
  HasMany<R> hasMany<R extends Model>(
    R Function(Map<String, dynamic>) creator, {
    String? foreignKey,
    String? localKey,
  }) {
    return HasMany<R>(
      _asModel,
      creator,
      foreignKey ?? Utils.foreignKey(table),
      localKey ?? primaryKey,
    );
  }

  /// Defines an inverse 1:1 or N:1 relationship where the Foreign Key resides on *this* model.
  ///
  /// Example: Post belongs to User. (Post table has `user_id`).
  ///
  /// Note: Instantiates a temporary [R] to inspect its `table` and `primaryKey`
  /// for default key inference.
  BelongsTo<R> belongsTo<R extends Model>(
    R Function(Map<String, dynamic>) creator, {
    String? foreignKey,
    String? ownerKey,
  }) {
    // We create a dummy instance to inspect the parent's table and primary key defaults.
    final instance = creator({});
    return BelongsTo<R>(
      _asModel,
      creator,
      foreignKey ?? Utils.foreignKey(instance.table),
      ownerKey ?? instance.primaryKey,
    );
  }

  /// Defines a N:N relationship via an intermediate pivot table.
  ///
  /// Example: User belongs to many Roles (via `role_user` table).
  ///
  /// * [pivotTable]: Explicit name required if strictly following convention isn't possible or desired.
  BelongsToMany<R> belongsToMany<R extends Model>(
    R Function(Map<String, dynamic>) creator,
    String pivotTable, {
    String? foreignPivotKey,
    String? relatedPivotKey,
  }) {
    final instance = creator({});
    return BelongsToMany<R>(
      _asModel,
      creator,
      pivotTable,
      foreignPivotKey ?? Utils.foreignKey(table),
      relatedPivotKey ?? Utils.foreignKey(instance.table),
    );
  }

  /// Defines a distant 1:N relationship through an intermediate model.
  ///
  /// Example: Country has many Posts through User.
  /// (Country -> User -> Post). Useful to avoid manual nested joins.
  HasManyThrough<R, I> hasManyThrough<R extends Model, I extends Model>(
    R Function(Map<String, dynamic>) relatedCreator,
    I Function(Map<String, dynamic>) intermediateCreator, {
    String? firstKey,
    String? secondKey,
  }) {
    return HasManyThrough<R, I>(
      _asModel,
      relatedCreator,
      intermediateCreator,
      firstKey,
      secondKey,
    );
  }

  // --- Polymorphic Relationships ---

  /// Polymorphic 1:N. The target model [R] stores the `_id` and `_type`.
  ///
  /// Example: Post has many Comments (and Video also has many Comments).
  MorphMany<R> morphMany<R extends Model>(
    R Function(Map<String, dynamic>) creator,
    String name,
  ) {
    return MorphMany<R>(_asModel, creator, name);
  }

  /// Polymorphic 1:1. Similar to [morphMany] but enforces a single result.
  MorphOne<R> morphOne<R extends Model>(
    R Function(Map<String, dynamic>) creator,
    String name,
  ) {
    return MorphOne<R>(_asModel, creator, name);
  }

  /// The inverse of a polymorphic relationship (the child side).
  ///
  /// Used by the model holding the `_id` and `_type` columns (e.g., Comment)
  /// to resolve its parent, which could be one of several types.
  ///
  /// * [typeMap]: Maps the stored string discriminator (e.g., 'post') to the concrete Model factory.
  MorphTo<Model> morphToTyped(
    String name,
    Map<String, Model Function(Map<String, dynamic>)> typeMap,
  ) {
    return MorphTo<Model>(_asModel, name, typeMap);
  }

  /// Polymorphic N:N.
  ///
  /// Allows a model to belong to many other models of different types via a pivot table
  /// that includes type discriminators.
  MorphToMany<R> morphToMany<R extends Model>(
    R Function(Map<String, dynamic>) creator,
    String name,
  ) {
    return MorphToMany<R>(_asModel, creator, name);
  }
}
