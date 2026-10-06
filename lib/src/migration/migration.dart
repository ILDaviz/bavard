import '../schema/schema.dart';

/// A single database migration.
///
/// Migrations are like version control for your database: each one describes
/// a reversible change to the schema. This is especially important for
/// offline-first Flutter apps, where the local database must be upgraded
/// in place when the user installs a new version of the app.
abstract class Migration {
  /// Applies the change (e.g., create a table, add a column).
  Future<void> up(Schema schema);

  /// Reverses the change performed by [up].
  Future<void> down(Schema schema);
}
