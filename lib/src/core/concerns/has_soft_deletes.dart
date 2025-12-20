import '../model.dart';
import '../database_manager.dart';
import '../query_builder.dart';

/// Implements the "Soft Delete" pattern using a `deleted_at` timestamp.
///
/// Modifies the model's behavior so that "deletion" updates a timestamp rather
/// than removing the row. Automatically filters out these rows from standard queries.
mixin HasSoftDeletes on Model {
  bool get trashed => attributes['deleted_at'] != null;

  @override
  void registerGlobalScopes(QueryBuilder<Model> builder) {
    super.registerGlobalScopes(builder);

    builder.withGlobalScope('soft_delete', (b) {
      b.whereNull('deleted_at');
    });
  }

  /// Bypasses the default soft-delete scope to retrieve all records (active + deleted).
  QueryBuilder<Model> withTrashed() {
    return newQuery().withoutGlobalScope('soft_delete');
  }

  /// Scopes the query to retrieve **only** soft-deleted records.
  QueryBuilder<Model> onlyTrashed() {
    return newQuery()
        .withoutGlobalScope('soft_delete')
        .whereNotNull('deleted_at');
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
