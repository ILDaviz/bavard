/// Canonical mapping between schema type strings and Dart runtime types.
///
/// Used by the code generator to translate `schemaTypes` definitions (e.g., 'json', 'int')
/// into concrete Dart code.
enum OrmCastType {
  string,
  integer,
  doubleType,
  boolean,
  datetime,

  /// Represents complex structures (Maps/Lists) stored as JSON strings.
  json,

  /// Maps to `List<dynamic>`.
  array,

  /// Maps to `Map<String, dynamic>`.
  object;

  /// Resolves a schema type string to an Enum, handling normalization.
  ///
  /// Strips metadata (':guarded') and nullability modifiers ('?', '!') before matching.
  static OrmCastType? fromString(String value) {
    final normalized = value
        .replaceAll('?', '')
        .replaceAll('!', '')
        .toLowerCase();

    switch (normalized) {
      case 'string':
        return OrmCastType.string;
      case 'int':
      case 'integer':
        return OrmCastType.integer;
      case 'double':
      case 'float':
        return OrmCastType.doubleType;
      case 'bool':
      case 'boolean':
        return OrmCastType.boolean;
      case 'datetime':
      case 'date':
        return OrmCastType.datetime;
      case 'json':
        return OrmCastType.json;
      case 'array':
        return OrmCastType.array;
      case 'object':
        return OrmCastType.object;
      default:
        return null;
    }
  }

  /// Parses nullability intent from the type string suffix.
  ///
  /// Defaults to `true` (nullable) to accommodate potential DB nulls,
  /// unless explicitly marked with '!' (strict).
  static bool isNullable(String value) {
    if (value.endsWith('!')) return false;
    if (value.endsWith('?')) return true;
    return true;
  }

  /// Converts the enum to its corresponding Dart type string for code generation.
  String dartType({required bool nullable}) {
    final suffix = nullable ? '?' : '';

    switch (this) {
      case OrmCastType.string:
        return 'String$suffix';
      case OrmCastType.integer:
        return 'int$suffix';
      case OrmCastType.doubleType:
        return 'double$suffix';
      case OrmCastType.boolean:
        return 'bool$suffix';
      case OrmCastType.datetime:
        return 'DateTime$suffix';
      case OrmCastType.json:
        // 'dynamic' avoids generic complexity; nullability is handled by the value check.
        return 'dynamic';
      case OrmCastType.array:
        return 'List<dynamic>$suffix';
      case OrmCastType.object:
        return 'Map<String, dynamic>$suffix';
    }
  }
}
