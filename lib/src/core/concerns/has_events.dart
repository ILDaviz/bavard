/// Defines interception points for persistence lifecycle (ORM-style hooks).
///
/// Allows implementing cross-cutting concerns like validation, cascading updates,
/// or external side effects during the Save/Delete transaction flow.
mixin HasEvents {
  /// Pre-persistence hook. Return `false` to abort the Save operation.
  ///
  /// Useful for final validation, setting automated timestamps (e.g., `updated_at`),
  /// or calculating derived fields before the data hits the storage.
  Future<bool> onSaving() async => true;

  /// Post-persistence hook invoked after the record is committed.
  ///
  /// Safe for side effects that require the record to definitely exist in the DB,
  /// such as invalidating cache, triggering webhooks, or scheduling background jobs.
  Future<void> onSaved() async {}

  /// Pre-removal hook. Return `false` to prevent the Delete operation.
  ///
  /// Critical for referential integrity checks (e.g., preventing delete if dependencies exist)
  /// or business rule enforcement (e.g., "cannot delete the last admin").
  Future<bool> onDeleting() async => true;

  /// Post-removal hook.
  ///
  /// Ideal for cleanup of non-database resources (file system assets, cloud storage images)
  /// or broadcasting deletion events to other parts of the app.
  Future<void> onDeleted() async {}
}
