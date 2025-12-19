import '../model.dart';
import '../database_manager.dart';
import '../query_builder.dart';

/// Implements the "Soft Delete" pattern using a `deleted_at` timestamp.
///
/// Modifies the model's behavior so that "deletion" updates a timestamp rather
/// than removing the row. Automatically filters out these rows from standard queries.
mixin HasSoftDeletes on Model {
  bool get trashed => attributes['deleted_at'] != null;

  /// Intercepts the default query builder to inject a global `whereNull('deleted_at')` scope.
  ///
  /// This ensures all standard queries exclude soft-deleted records by default.
  @override
  QueryBuilder<Model> newQuery() {
    final query = super.newQuery();

    return query.whereNull('deleted_at');
  }

  /// Bypasses the default soft-delete scope to retrieve all records (active + deleted).
  QueryBuilder<Model> withTrashed() {
    // Calls super directly to avoid the 'whereNull' injection in our override of newQuery().
    return super.newQuery();
  }

  /// Scopes the query to retrieve **only** soft-deleted records.
  QueryBuilder<Model> onlyTrashed() {
    return super.newQuery().whereNotNull('deleted_at');
  }

  /// Overrides physical deletion to perform an `UPDATE` operation.
  ///
  /// Sets `deleted_at` to the current time instead of removing the row.
  /// Maintains standard lifecycle hooks ([onDeleting] / [onDeleted]).
  @override
  Future<void> delete() async {
    if (id != null && await onDeleting()) {
      setAttribute('deleted_at', DateTime.now());

      await save();
      await onDeleted();
    }
  }

  /// Reverses a soft-delete by resetting `deleted_at` to null.
  Future<void> restore() async {
    setAttribute('deleted_at', null);
    await save();
  }

  /// Permanently removes the record from the database (SQL DELETE).
  ///
  /// **Warning:** Data loss is irreversible.
  /// Still triggers standard [onDeleting] and [onDeleted] hooks for consistency.
  Future<void> forceDelete() async {
    if (id != null && await onDeleting()) {
      await DatabaseManager().db.execute(
        'DELETE FROM $table WHERE $primaryKey = ?',
        [id],
      );
      await onDeleted();
    }
  }
}
