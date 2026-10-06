import '../database_manager.dart';
import '../exceptions.dart';
import '../model.dart';
import '../query_builder.dart';
import 'base.dart';
import 'identifiers.dart';

/// Query execution: retrieval (get/first/find), hydration with eager loading,
/// and write statements (update/delete/insert).
mixin ExecutesQueries<T extends Model> on QueryBuilderBase<T> {
  Future<T?> find(dynamic id) {
    final clone = cast<T>(creator, instanceFactory: instanceFactory);
    return clone.where('id', id).first();
  }

  /// Finds a model by ID or throws [ModelNotFoundException].
  Future<T> findOrFail(dynamic id) async {
    final result = await find(id);
    if (result == null) {
      throw ModelNotFoundException(model: table, id: id);
    }
    return result;
  }

  /// Returns the first result or throws [ModelNotFoundException].
  Future<T> firstOrFail() async {
    final result = await first();
    if (result == null) {
      throw ModelNotFoundException(model: table);
    }
    return result;
  }

  Future<T?> first() async {
    final clone = cast<T>(creator, instanceFactory: instanceFactory);
    clone.limit(1);
    final results = await clone.get();
    return results.isNotEmpty ? results.first : null;
  }

  /// Executes the compiled query and hydrates results.
  Future<List<T>> get() async {
    applyScopes();
    final dbManager = DatabaseManager();
    final sql = compileSql();
    final allBindings = grammar.prepareBindings(getAllBindings());

    try {
      final resultRows = await dbManager.getAll(sql, allBindings);
      final models = await _hydrate(resultRows);
      return models;
    } catch (e) {
      throw QueryException(
        sql: sql,
        bindings: allBindings,
        message: 'Failed to execute query: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<int> update(Map<dynamic, dynamic> values) async {
    applyScopes();

    if (values.isEmpty) {
      return 0;
    }

    final resolvedValues = values.map((key, value) {
      return MapEntry(resolveColumnNameForWrite(key), value);
    });

    final sql = grammar.compileUpdate(this as QueryBuilder, resolvedValues);
    final allBindings = grammar.prepareBindings([
      ...resolvedValues.values,
      ...whereBindings,
    ]);

    return await DatabaseManager().execute(table, sql, allBindings);
  }

  Future<int> delete() async {
    applyScopes();
    final sql = grammar.compileDelete(this as QueryBuilder);
    final bindings = grammar.prepareBindings(whereBindings);

    return await DatabaseManager().execute(table, sql, bindings);
  }

  /// Executes a raw INSERT into the database.
  ///
  /// WARNING: Bypasses the Model lifecycle (no events, automatic timestamps, or casts).
  /// Returns the ID of the inserted record (if supported by the driver, e.g., autoincrement).
  Future<int> insert(Map<dynamic, dynamic> values) async {
    if (values.isEmpty)
      throw const InvalidQueryException('Insert values cannot be empty');

    final resolvedValues = values.map((key, value) {
      final colName = resolveColumnNameForWrite(key);
      assertIdentifier(colName, dotted: false, what: 'column name');
      return MapEntry(colName, value);
    });

    return await DatabaseManager().insert(table, resolvedValues);
  }

  /// Executes a bulk INSERT into the database.
  ///
  /// WARNING: Bypasses the Model lifecycle (no events, automatic timestamps, or casts).
  /// Returns true if the operation was successful.
  Future<bool> insertAll(List<Map<String, dynamic>> values) async {
    if (values.isEmpty) return true;

    final resolvedValues = values.map((map) {
      return map.map((key, value) {
        final colName = resolveColumnNameForWrite(key);
        assertIdentifier(colName, dotted: false, what: 'column name');
        return MapEntry(colName, value);
      });
    }).toList();

    final sortedKeys = resolvedValues.first.keys.toList()..sort();

    final bindings = <dynamic>[];
    for (final map in resolvedValues) {
      for (final key in sortedKeys) {
        bindings.add(map[key]);
      }
    }

    final sql = grammar.compileInsert(this as QueryBuilder, resolvedValues);
    final allBindings = grammar.prepareBindings(bindings);

    final affected = await DatabaseManager().execute(table, sql, allBindings);
    return affected > 0;
  }

  /// Resolves eager loads by delegating to the Model's relation definition.
  ///
  /// Iterates through the result set [models] and matches related records in-memory
  /// or via secondary queries.
  Future<void> _eagerLoad(List<T> models) async {
    if (eagerLoads.isEmpty || models.isEmpty) return;

    final rootScopes = <String, ScopeCallback?>{};
    final rootNested = <String, Map<String, ScopeCallback?>>{};
    final uniqueRoots = <String>{};

    eagerLoads.forEach((path, scope) {
      final parts = path.split('.');
      final root = parts[0];
      final nestedPath = parts.length > 1 ? parts.sublist(1).join('.') : null;

      uniqueRoots.add(root);

      if (nestedPath == null) {
        rootScopes[root] = scope;
      } else {
        if (!rootNested.containsKey(root)) {
          rootNested[root] = {};
        }
        rootNested[root]![nestedPath] = scope;
      }
    });

    await Future.wait(
      uniqueRoots.map((relationName) async {
        final relation = models.first.getRelation(relationName);
        if (relation != null) {
          await relation.match(
            models,
            relationName,
            scope: rootScopes[relationName],
            nested: rootNested[relationName] ?? {},
          );
        }
      }),
    );
  }

  /// Maps raw DB rows to concrete Model instances.
  ///
  /// Handles lifecycle initialization:
  /// - Sets [Model.exists] to true.
  /// - Takes a snapshot for dirty checking ([Model.syncOriginal]).
  /// - Triggers eager loading.
  Future<List<T>> _hydrate(List<Map<String, dynamic>> rows) async {
    final models = <T>[];

    for (final row in rows) {
      final model = creator(row);
      model.exists = true;
      model.syncOriginal();
      models.add(model);
    }

    await _eagerLoad(models);
    return models;
  }
}
