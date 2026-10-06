import 'dart:async';

import '../database_manager.dart';
import '../model.dart';
import '../query_builder.dart';
import 'base.dart';

/// Reactive and lazy result streaming (`watch` and `cursor`).
mixin StreamsResults<T extends Model> on QueryBuilderBase<T> {
  /// Satisfied by [ExecutesQueries] once the mixins are composed into
  /// [QueryBuilder]; declared abstract so this mixin can re-run the query.
  Future<List<T>> get();

  /// Returns a reactive stream that emits updated results when the table changes.
  ///
  /// Essential for Flutter reactive UIs (StreamBuilder).
  Stream<List<T>> watch() {
    applyScopes();
    final manager = DatabaseManager();
    final controller = StreamController<List<T>>();

    get()
        .then((data) {
          if (!controller.isClosed) controller.add(data);
        })
        .catchError((e) {
          if (!controller.isClosed) controller.addError(e);
        });

    final subscription = manager.tableChanges.where((t) => t == table).listen((
      _,
    ) async {
      try {
        final data = await get();
        if (!controller.isClosed) controller.add(data);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    });

    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Lazily streams results in chunks to minimize memory usage for large datasets.
  ///
  /// Uses **keyset pagination** to fetch [batchSize] records at a time: after the
  /// first batch, every subsequent query resumes strictly after the last row
  /// already yielded, via a `WHERE (key > last) OR (key = last AND id > lastId)`
  /// predicate. Unlike offset pagination this stays O(1) per batch on indexed
  /// keys (no repeated table scan) and never skips or duplicates rows when rows
  /// are inserted or deleted while streaming.
  ///
  /// Ordering is always deterministic: the query's `orderBy` (if any) is kept
  /// and the primary key is appended as a tiebreaker; without an explicit
  /// `orderBy`, results stream in ascending primary key order.
  ///
  /// An [QueryBuilderBase.queryOffset] set on the query is honored for the first
  /// batch only, after which iteration continues by keyset.
  ///
  /// Note: when an explicit `orderBy` targets a nullable column, rows holding
  /// `NULL` in it cannot be ordered reliably across batches — prefer a
  /// non-nullable sort key.
  ///
  /// Example:
  /// ```dart
  /// await for (final user in User().query().cursor(batchSize: 50)) {
  ///   print(user.name);
  /// }
  /// ```
  Stream<T> cursor({int batchSize = 100}) async* {
    final primaryKey = creator(const {}).primaryKey;
    final pkWrapped = grammar.wrap(primaryKey);

    // Deterministic ordering: the user's sort column plus the primary key as
    // a tiebreaker (always ascending) to guarantee a total, stable order.
    final sortColumn = orderByColumn;
    final isDesc = orderByDirection == 'DESC';
    final orderSql = sortColumn != null
        ? '$orderBySql, $pkWrapped ASC'
        : '$pkWrapped ASC';

    // Composite cursor position: [sortColumnValue?, primaryKeyValue].
    List<dynamic>? cursorPosition;
    var isFirstBatch = true;

    while (true) {
      // Create a fresh clone for each batch to ensure isolation.
      final batchQuery = cast<T>(creator, instanceFactory: instanceFactory);
      batchQuery.orderBySql = orderSql;
      batchQuery.limit(batchSize);

      if (isFirstBatch) {
        isFirstBatch = false;
        // The initial offset is inherited from the clone; honor it once.
      } else {
        // Keyset position replaces the offset: keeping it would re-skip rows
        // on every batch (and can loop forever on stable result sets).
        batchQuery.queryOffset = null;

        if (cursorPosition != null) {
          _applyKeysetPredicate(
            batchQuery,
            sortColumn: sortColumn,
            primaryKey: primaryKey,
            isDesc: isDesc,
            position: cursorPosition,
          );
        }
      }

      final batch = await batchQuery.get();

      if (batch.isEmpty) {
        break;
      }

      for (final model in batch) {
        yield model;
      }

      if (batch.length < batchSize) {
        break;
      }

      final last = batch.last;
      cursorPosition = [
        if (sortColumn != null) last.attributes[sortColumn],
        last.attributes[primaryKey],
      ];
    }
  }

  /// Adds the keyset predicate resuming strictly after [position]:
  /// `(key OP last) OR (key = last AND id > lastId)`, where `OP` follows the
  /// sort direction of the key column.
  void _applyKeysetPredicate(
    QueryBuilder<T> batchQuery, {
    required String? sortColumn,
    required String primaryKey,
    required bool isDesc,
    required List<dynamic> position,
  }) {
    batchQuery.whereGroup((q) {
      // Without an explicit sort column the cursor is the primary key alone.
      if (sortColumn == null) {
        q.where(primaryKey, position[0], '>');
        return;
      }

      final sortValue = position[0];
      final sortOperator = isDesc ? '<' : '>';

      q.where(sortColumn, sortValue, sortOperator);
      q.orWhereGroup((nested) {
        nested
          ..where(sortColumn, sortValue, '=')
          ..where(primaryKey, position[1], '>');
      });
    });
  }
}
