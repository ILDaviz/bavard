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

  void hydrateAttributes(Map<String, dynamic> rawData) {
    attributes.addAll(rawData);
    casts.forEach((key, rawType) {
      if (!attributes.containsKey(key)) return; // Se nullo, lasciamo nullo
      setAttribute(key, attributes[key]);
    });
  }

  Map<String, dynamic> dehydrateAttributes() {
    final dehydrateData = Map<String, dynamic>.from(attributes);

    casts.forEach((key, rawType) {
      if (!dehydrateData.containsKey(key) || dehydrateData[key] == null) return;

      final type = _normalizeType(rawType);
      final value = dehydrateData[key];

      if (type == 'json' || type == 'array' || type == 'object') {
        if (value is String) {
          try {
            dehydrateData[key] = jsonDecode(value);
          } catch (_) {
            // Fail-safe
          }
        }
      }
    });

    return dehydrateData;
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
        final s = value.toString().toLowerCase();
        if (s == '1' || s == 'true') return true as T;
        if (s == '0' || s == 'false') return false as T;
        return null;

      case 'datetime':
        if (value is DateTime) return value as T;
        return DateTime.tryParse(value.toString()) as T?;

      case 'json':
      case 'array':
      case 'object':
        if (value is T && value is! String) return value;
        if (value is String) {
          try {
            final decoded = jsonDecode(value);
            return decoded as T;
          } catch (_) {
            return null;
          }
        }

        // Return null the type is not compatible
        return null;

      default:
        try {
          return value as T;
        } catch (_) {
          return null;
        }
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
        if (value is String) {
          try {
            attributes[key] = jsonDecode(value);
          } catch (e) {
            attributes[key] = value;
          }
        } else {
          attributes[key] = value;
        }
        break;

      case 'bool':
        if (value is bool) {
          attributes[key] = value ? 1 : 0;
        } else if (value is int) {
          attributes[key] = value == 1 ? 1 : 0;
        } else {
          final s = value.toString().toLowerCase();
          attributes[key] = (s == 'true' || s == '1') ? 1 : 0;
        }
        break;

      case 'datetime':
        if (value is DateTime) {
          attributes[key] = value.toIso8601String();
        } else {
          attributes[key] = value.toString();
        }
        break;

      default:
        attributes[key] = value;
    }
  }
}
