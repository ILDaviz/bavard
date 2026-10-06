/// Interface for defining custom attribute casting logic.
///
/// [T] is the runtime type (e.g., Address object).
/// [R] is the database/raw type (e.g., String JSON or Map).
abstract class AttributeCast<T, R> {
  /// Transform the raw database value to the runtime value.
  T get(R rawValue, Map<String, dynamic> attributes);

  /// Transform the runtime value to the database value.
  R set(T value, Map<String, dynamic> attributes);
}
