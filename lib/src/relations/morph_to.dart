import 'relation.dart';
import '../core/model.dart';

/// Represents the inverse side of a polymorphic relationship (the child holding the keys).
///
/// Unlike standard relations, the target Model and Table are not fixed; they are resolved
/// dynamically at runtime based on the `{name}_type` and `{name}_id` columns.
class MorphTo<R extends Model> extends Relation<R> {
  final String name;

  /// Maps the discriminator string (stored in `{name}_type`) to the corresponding Model factory.
  /// Essential for knowing which table to query for a given record.
  final Map<String, R Function(Map<String, dynamic>)> typeMap;

  // Passes a dummy `_MorphModel` to the super constructor because the actual target table
  // is unknown at instantiation time. Real queries use `typeMap` factories.
  MorphTo(Model parent, this.name, this.typeMap)
    : super(parent, (_) => _MorphModel() as R);

  /// No-op: Standard SQL constraints cannot be applied globally here because
  /// the target table varies from record to record.
  @override
  void addConstraints() {
    // Dynamic resolution happens in [getResult] or [match].
  }

  /// Lazy-loads the parent for the current instance.
  ///
  /// Resolves the specific table via [typeMap] using the stored `{name}_type`.
  /// Returns `null` if the discriminator is missing or not mapped.
  Future<R?> getResult() async {
    final type = parent.attributes['${name}_type']?.toString();
    final id = parent.attributes['${name}_id'];

    if (type == null || id == null) return null;

    final creator = typeMap[type];
    if (creator == null) return null;

    final dummy = creator(const {});

    return dummy
        .newQuery()
        .where(dummy.primaryKey, id)
        .first()
        .then((value) => value as R?);
  }

  @override
  Future<R?> first() => getResult();

  /// Throws [UnsupportedError].
  ///
  /// A standard `get()` is impossible because a single query cannot target multiple
  /// unknown tables simultaneously. Use `getResult()` or eager loading (`withRelations`).
  @override
  Future<List<R>> get() {
    throw UnsupportedError(
      'MorphTo does not support get() because the target table is dynamic. '
      'Use getResult() / first() or eager load via withRelations().',
    );
  }

  @override
  Stream<List<R>> watch() {
    throw UnsupportedError(
      'MorphTo does not support watch() because the target table is dynamic.',
    );
  }

  /// Eagerly loads parents for a list of mixed-type children.
  ///
  /// Optimization Strategy:
  /// 1. Buckets child IDs by their polymorphic `type` (e.g., separates 'posts' from 'videos').
  /// 2. Executes exactly one query per distinct type found.
  /// 3. Merges results into a lookup dictionary to populate relations in memory.
  @override
  Future<void> match(
    List<Model> models,
    String relationName, {
    List<String> nested = const [],
  }) async {
    Map<String, List<dynamic>> mapByType = {};

    // 1. Group IDs by type
    for (var model in models) {
      final type = model.attributes['${name}_type']?.toString();
      final id = model.attributes['${name}_id'];

      if (type != null && id != null) {
        mapByType.putIfAbsent(type, () => []);
        mapByType[type]!.add(id);
      }
    }

    Map<String, Map<String, Model>> resultsByType = {};

    // 2. Query each type individually
    for (var type in mapByType.keys) {
      final creator = typeMap[type];
      if (creator == null) continue;

      final ids = mapByType[type]!;
      final dummyModel = creator(const {});

      final results = await dummyModel
          .newQuery()
          .withRelations(nested)
          .whereIn(dummyModel.primaryKey, ids)
          .get();

      resultsByType[type] = {for (var r in results) normKey(r.id)!: r};
    }

    // 3. Assign results back to children
    for (var model in models) {
      final type = model.attributes['${name}_type']?.toString();
      final id = normKey(model.attributes['${name}_id']);

      if (type == null || id == null) continue;

      final dict = resultsByType[type];
      if (dict != null && dict.containsKey(id)) {
        model.relations[relationName] = dict[id];
      }
    }
  }
}

/// Internal sentinel used to satisfy type constraints during [MorphTo] initialization.
/// Prevents runtime crashes when the Relation constructor demands a table name.
class _MorphModel extends Model {
  @override
  String get table => '_morph';

  _MorphModel([super.attributes]);

  @override
  _MorphModel fromMap(Map<String, dynamic> map) => _MorphModel(map);
}
