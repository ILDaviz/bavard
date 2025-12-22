import '../../bavard.dart';
import 'pivot.dart';
import 'concerns/has_guards_attributes.dart';
import './concerns/has_casts.dart';
import './concerns/has_events.dart';
import './concerns/has_relationships.dart';
import './concerns/has_attribute_helpers.dart';

/// Core Active Record implementation serving as the bridge between Dart objects and the DB.
///
/// Aggregates feature mixins (Events, Casts, Relations) and manages the
/// persistence lifecycle, including dirty checking and attribute synchronization.
/// Concrete classes need only define the [table] and the [fromMap] hydration factory.
abstract class Model
    with
        HasCasts,
        HasEvents,
        HasRelationships,
        HasAttributeHelpers,
        HasGuardsAttributes {
  Model newInstance() => fromMap(const {});

  @override
  String get table;

  @override
  String get primaryKey => 'id';

  /// The raw data source for the model. Modified by setters/casts, read by getters/DB.
  @override
  Map<String, dynamic> attributes;

  @override
  dynamic get id => attributes[primaryKey];

  set id(dynamic value) => attributes[primaryKey] = value;

  /// Holds the intermediate table data for Many-to-Many relationships.
  Pivot? pivot;

  /// Helper to safely cast the pivot object to a specific type.
  T? getPivot<T extends Pivot>() {
    if (pivot is T) {
      return pivot as T;
    }
    return null;
  }

  Model([Map<String, dynamic> attributes = const {}])
    : attributes = Map<String, dynamic>.from(attributes);

  /// Indicates if the model currently exists in the database (persisted).
  /// This change logic for CREATE or UPDATE
  bool exists = false;

  /// A snapshot of attributes at the time of hydration or last save.
  /// Used to calculate diffs for efficient UPDATE queries.
  Map<String, dynamic> original = {};

  void registerGlobalScopes(QueryBuilder<Model> builder) {}

  dynamic _deepCopy(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), _deepCopy(v)),
      );
    } else if (value is List) {
      return value.map((v) => _deepCopy(v)).toList();
    } else if (value is Set) {
      return value.map((v) => _deepCopy(v)).toSet();
    }

    return value;
  }

  /// Snapshots current attributes to [original].
  ///
  /// Critical for "Dirty Checking" to ensure only changed fields are sent to the DB.
  void syncOriginal() {
    original = _deepCopy(attributes) as Map<String, dynamic>;
  }

  /// Container for eager-loaded data (e.g., `user.relations['posts']`).
  @override
  Map<String, dynamic> relations = {};

  /// Factory method to hydrate a concrete instance from a DB row (Map).
  Model fromMap(Map<String, dynamic> map);

  /// Entry point for the Fluent Query Builder.
  ///
  /// Binds the [fromMap] factory to the builder to ensure results are hydrated
  /// into concrete Model instances rather than raw Maps.
  QueryBuilder<Model> newQuery() {
    final builder = QueryBuilder(
      table,
      fromMap,
      instanceFactory: () => newInstance(),
    );
    registerGlobalScopes(builder);
    return builder;
  }

  QueryBuilder<Model> where(String column, dynamic value) =>
      newQuery().where(column, value);

  QueryBuilder<Model> withRelations(List<String> rels) =>
      newQuery().withRelations(rels);

  /// Persists the model to storage (Upsert logic).
  ///
  /// Flow:
  /// 1. Trigger [onSaving].
  /// 2. If new ([exists] is false): perform INSERT.
  /// 3. If existing: Calculate diff ([dirtyAttributes]) and UPDATE only changed fields.
  /// 4. Refresh: Re-fetch record to sync DB-generated values (autoincrement IDs, timestamps, triggers).
  /// 5. Trigger [onSaved].
  Future<void> save() async {
    if (!await onSaving()) return;

    final dbManager = DatabaseManager();

    if (!exists) {
      final insertId = await dbManager.insert(table, attributes);
      id ??= insertId;
      exists = true;
    } else {
      // Dirty Checking: identify strictly changed values to optimize the SQL payload.
      final dirtyAttributes = <String, dynamic>{};
      attributes.forEach((key, value) {
        if (key != primaryKey && value != original[key]) {
          dirtyAttributes[key] = value;
        }
      });

      if (dirtyAttributes.isEmpty) {
        return;
      }

      await query().where(primaryKey, id).update(dirtyAttributes);
    }
    await refresh();
    await onSaved();
  }

  Future<void> refresh() async {
    if (id == null) return;
    // Reset with withoutGlobalScopes to avoid eager-loading issues
    final freshInstance = await newQuery().withoutGlobalScopes().findOrFail(id);
    attributes = freshInstance.attributes;
    syncOriginal();
  }

  /// Permanently removes the record (unless [HasSoftDeletes] overrides this).
  ///
  /// Triggers [onDeleting] (can cancel) and [onDeleted] hooks.
  Future<void> delete() async {
    if (id != null && await onDeleting()) {
      await newQuery().where(primaryKey, id).delete();
      await onDeleted();
    }
  }
}

/// Helper extension to safely cast dynamic relation data.
extension TypedRelations on Model {
  /// Safely retrieves a single related model (1:1 or N:1).
  T? getRelated<T>(String name) {
    if (!relations.containsKey(name)) return null;
    return relations[name] as T?;
  }

  /// Safely retrieves a list of related models (1:N or N:N).
  List<T> getRelationList<T>(String name) {
    if (!relations.containsKey(name)) return [];

    final list = relations[name];
    if (list is List) {
      return list.cast<T>();
    }

    return [];
  }
}
