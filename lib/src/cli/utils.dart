/// Converts a string to snake_case.
String toSnakeCase(String str) {
  return str.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
    return (match.start == 0 ? '' : '_') + match.group(0)!.toLowerCase();
  }).toLowerCase();
}

/// Converts a string to camelCase.
String toCamelCase(String str) {
  final s = str.replaceAllMapped(RegExp(r'(_[a-z])'), (match) {
    return match.group(0)!.substring(1).toUpperCase();
  });
  return s[0].toLowerCase() + s.substring(1);
}

/// Simple pluralizer.
String pluralize(String str) {
  if (str.endsWith('y')) return '${str.substring(0, str.length - 1)}ies';
  if (str.endsWith('s')) return '${str}es';
  return '${str}s';
}
