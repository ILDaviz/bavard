import 'has_casts.dart';

/// Provides syntactic sugar over [HasCasts] for typed attribute access.
///
/// Reduces boilerplate for common primitives and enables Map-like subscript
/// syntax (e.g., `model['key']`) to facilitate dynamic access or generic UI binding.
mixin HasAttributeHelpers on HasCasts {
  String? string(String key) => getAttribute<String>(key);

  int? integer(String key) => getAttribute<int>(key);

  double? doubleNum(String key) => getAttribute<double>(key);

  bool? boolean(String key) => getAttribute<bool>(key);

  DateTime? date(String key) => getAttribute<DateTime>(key);

  /// Helper for retrieving nested structures (e.g., `Map` or `List`) cast to [T].
  T? json<T>(String key) => getAttribute<T>(key);

  /// Resolves the raw value at [key] to a specific [Enum] entry within [values].
  T? enumeration<T extends Enum>(String key, List<T> values) =>
      getEnum<T>(key, values);

  /// Exposes dynamic access, useful for serialization loops or form field binding.
  dynamic operator [](String key) => getAttribute(key);

  void operator []=(String key, dynamic value) => setAttribute(key, value);
}
