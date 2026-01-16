import '../model.dart';

/// Automates the maintenance of audit timestamps (`created_at`, `updated_at`) during persistence.
mixin HasTimestamps on Model {
  String get createdAtColumn => 'created_at';

  String get updatedAtColumn => 'updated_at';

  DateTime? get createdAt => getAttribute<DateTime>(createdAtColumn);
  set createdAt(dynamic value) => setAttribute(createdAtColumn, value);

  DateTime? get updatedAt => getAttribute<DateTime>(updatedAtColumn);
  set updatedAt(dynamic value) => setAttribute(updatedAtColumn, value);

  /// Master toggle to disable auto-timestamping (e.g., for legacy tables or bulk imports).
  bool get timestamps => true;

  /// Hooks into the save lifecycle to inject current timestamps.
  ///
  /// Logic:
  /// 1. New records (`id` is null): Sets `created_at` (unless manually populated).
  /// 2. All saves: Refreshes `updated_at` to the current time.
  @override
  Future<bool> onSaving() async {
    if (!timestamps) return super.onSaving();

    final now = DateTime.now();

    if (!exists) {
      // Respects manually set creation dates (e.g., during data migration).
      if (attributes[createdAtColumn] == null) {
        setAttribute(createdAtColumn, now);
      }
    }

    // Only update timestamp if model is dirty (user changed something)
    if (exists && !isDirty()) {
      return super.onSaving();
    }

    setAttribute(updatedAtColumn, now);
    return super.onSaving();
  }
}
