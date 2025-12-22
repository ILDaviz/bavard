import '../schema/columns.dart';

/// Represents a row in a Many-to-Many pivot table.
///
/// Unlike a standard [Model], a Pivot is not a standalone entity but a link
/// between two models, often containing extra data (e.g. `role_user.created_at`).
abstract class Pivot {
  /// The raw attributes of the pivot record (including foreign keys and extra data).
  final Map<String, dynamic> attributes;

  Pivot(this.attributes);

  /// Strongly-typed getter for pivot attributes using Column metadata.
  ///
  /// Example: `pivot.get(UserRole.createdAtCol)`
  T get<T>(Column<T> column) {
    if (column.name == null) return null as T;

    final value = attributes[column.name];

    if (value == null) return null as T;

    if (T == DateTime && value is String) {
      return DateTime.parse(value) as T;
    }

    if (T == bool && value is int) {
      return (value == 1) as T;
    }

    if (T == int && value is num) {
      return value.toInt() as T;
    }

    if (T == double && value is num) {
      return value.toDouble() as T;
    }

    return value as T;
  }

  /// Strongly-typed setter for pivot attributes.
  ///
  /// Example: `pivot.set(UserRole.createdAtCol, DateTime.now())`
  void set<T>(Column<T> column, T value) {
    if (column.name == null) return;
    attributes[column.name!] = value;
  }
}
