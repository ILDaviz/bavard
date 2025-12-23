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
    final name = column.name;
    if (name == null) return null as T;

    final value = attributes[name];

    if (value == null) return null as T;

    final bool isDateTime = _isType<T, DateTime>();
    final bool isBool = _isType<T, bool>();
    final bool isInt = _isType<T, int>();
    final bool isDouble = _isType<T, double>();

    if (isDateTime && value is String) {
      return DateTime.parse(value) as T;
    }

    if (isDateTime && value is DateTime) {
      return value as T;
    }

    if (isBool && value is int) {
      return (value == 1) as T;
    }

    if (isInt && value is num) {
      return value.toInt() as T;
    }

    if (isDouble && value is num) {
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

// This is utility method.
bool _isType<T, Target>() => T == Target || T == _typeOf<Target?>();
Type _typeOf<T>() => T;

/// A default concrete implementation of [Pivot] for when no custom class is defined.
class GenericPivot extends Pivot {
  GenericPivot(super.attributes);
}