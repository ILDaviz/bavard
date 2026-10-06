import 'dart:convert';

import '../../schema/columns.dart';
import '../attribute_cast.dart';

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
  /// Value: Type identifier (e.g., 'int', 'bool', 'json', 'datetime') or [AttributeCast] instance.
  /// This acts as the schema definition for the model's dynamic data.
  Map<String, dynamic> get casts => {};

  /// Defines the schema columns for the model.
  ///
  /// Used as a fallback to derive casting rules if [casts] is not explicitly defined.
  List<SchemaColumn> get columns => [];

  Map<String, dynamic>? _cachedCasts;

  Map<String, dynamic> get _totalCasts {
    if (_cachedCasts != null) return _cachedCasts!;

    final combined = <String, dynamic>{};

    for (final col in columns) {
      if (col is Column && col.name != null) {
        combined[col.name!] = col.schemaType;
      }
    }

    combined.addAll(casts);

    _cachedCasts = combined;
    return combined;
  }

  /// Strips modifiers (nullability `?`, `!`) and metadata (suffixes after `:`) to resolve the base type.
  /// Also maps schema types to internal cast types.
  String? _normalizeType(dynamic value) {
    if (value is! String) return null;
    final raw = value.split(':').first.replaceAll('!', '').replaceAll('?', '');

    switch (raw) {
      case 'integer':
        return 'int';
      case 'boolean':
        return 'bool';
      case 'doubleType':
        return 'double';
      case 'string':
        return 'string';
      default:
        return raw;
    }
  }

  void hydrateAttributes(Map<String, dynamic> rawData) {
    attributes.addAll(rawData);
    _totalCasts.forEach((key, rawType) {
      if (!attributes.containsKey(key)) return;

      if (rawType is AttributeCast) return;

      setAttribute(key, attributes[key]);
    });
  }

  Map<String, dynamic> dehydrateAttributes() {
    final dehydrateData = Map<String, dynamic>.from(attributes);

    _totalCasts.forEach((key, rawType) {
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
  /// - Custom Casts: delegates to [AttributeCast.get].
  ///
  /// Returns `null` if the key is missing or parsing fails.
  T? getAttribute<T>(String key) {
    final value = attributes[key];
    final rawType = _totalCasts[key];

    if (rawType is AttributeCast) {
      return rawType.get(value, attributes) as T?;
    }

    if (value == null) return null;

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
  /// - Custom Casts: delegates to [AttributeCast.set].
  /// - Enums -> name string.
  /// - Complex objects/collections -> JSON encoded string (tries `.toJson()` first).
  /// - Bool -> integer (1/0) for broad SQL compatibility.
  /// - DateTime -> ISO-8601 string.
  void setAttribute(String key, dynamic value) {
    final rawType = _totalCasts[key];

    if (rawType is AttributeCast) {
      attributes[key] = rawType.set(value, attributes);
      return;
    }

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
