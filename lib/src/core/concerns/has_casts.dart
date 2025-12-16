import 'dart:convert';

/// Encapsulates type conversion logic for hydrating models from raw data.
///
/// Centralizes parsing rules (String -> int, String -> DateTime, JSON decoding)
/// based on a declarative [casts] configuration, preventing repetitive parsing
/// logic in individual model getters.
mixin HasCasts {
  /// The backing store for raw data, typically mirroring database columns.
  Map<String, dynamic> get attributes;

  /// Configuration map defining how to cast specific attributes.
  ///
  /// Key: Attribute name.
  /// Value: Type identifier (e.g., 'int', 'bool', 'json', 'datetime').
  /// This acts as the schema definition for the model's dynamic data.
  Map<String, String> get casts => {};

  /// Strips modifiers (nullability `?`, `!`) and metadata (suffixes after `:`) to resolve the base type.
  String? _normalizeType(String? value) {
    if (value == null) return null;
    return value.split(':').first.replaceAll('!', '').replaceAll('?', '');
  }

  /// Safe accessor that transforms raw data into type [T] based on [casts].
  ///
  /// Handles distinct parsing strategies:
  /// - Primitives: strict type checks with fallback to `tryParse`.
  /// - Boolean: lenient parsing (supports `true`, `1`, `'true'`, `'1'`).
  /// - JSON: automatically decodes String -> Map/List if type is 'json'/'array'.
  ///
  /// Returns `null` if the key is missing or parsing fails.
  T? getAttribute<T>(String key) {
    final value = attributes[key];
    if (value == null) return null;

    final rawType = casts[key];
    final type = _normalizeType(rawType);

    switch (type) {
      case 'int':
        if (value is int) return value as T;
        if (value is num) return value.toInt() as T;
        return int.tryParse(value.toString()) as T?;

      case 'double':
        if (value is double) return value as T;
        if (value is num) return value.toDouble() as T;
        return double.tryParse(value.toString()) as T?;

      case 'bool':
        if (value is bool) return value as T;
        if (value is int) return (value == 1) as T;
        final s = value.toString().toLowerCase();
        return (s == '1' || s == 'true') as T;

      case 'datetime':
        if (value is DateTime) return value as T;
        return DateTime.tryParse(value.toString()) as T?;

      case 'json':
      case 'array':
      case 'object':
        if (value is String) {
          try {
            return jsonDecode(value) as T;
          } catch (_) {
            return null;
          }
        }
        return value as T;

      default:
        return value as T;
    }
  }

  /// Maps a raw value to a specific [Enum] entry.
  ///
  /// Supports:
  /// - Integer based mapping (index in [values]).
  /// - String based mapping (matches `Enum.name`).
  T? getEnum<T extends Enum>(String key, List<T> values) {
    final val = attributes[key];
    if (val == null) return null;

    if (val is int) {
      if (val >= 0 && val < values.length) return values[val];
    } else {
      final str = val.toString();
      try {
        return values.firstWhere((e) => e.name == str);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Writes data to [attributes], applying transformations for persistence.
  ///
  /// Key transformations:
  /// - Enums -> name string.
  /// - Complex objects/collections -> JSON encoded string (tries `.toJson()` first).
  /// - Bool -> integer (1/0) for broad SQL compatibility.
  /// - DateTime -> ISO-8601 string.
  void setAttribute(String key, dynamic value) {
    final rawType = casts[key];
    final type = _normalizeType(rawType);

    if (value == null) {
      attributes[key] = null;
      return;
    }

    if (value is Enum) {
      attributes[key] = value.name;
      return;
    }

    switch (type) {
      case 'json':
      case 'array':
      case 'object':
        if (value is! String) {
          try {
            // Prioritizes .toJson() for custom objects, falls back to primitive encoding.
            attributes[key] = jsonEncode((value as dynamic).toJson());
          } catch (_) {
            attributes[key] = jsonEncode(value);
          }
        } else {
          attributes[key] = value;
        }
        break;

      case 'bool':
        attributes[key] = (value == true) ? 1 : 0;
        break;

      case 'datetime':
        if (value is DateTime) {
          attributes[key] = value.toIso8601String();
        } else {
          attributes[key] = value;
        }
        break;

      default:
        attributes[key] = value;
    }
  }
}