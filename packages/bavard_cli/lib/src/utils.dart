import 'dart:io';

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

// ANSI Escape Codes
const String reset = '\x1B[0m';
const String red = '\x1B[31m';
const String green = '\x1B[32m';
const String yellow = '\x1B[33m';
const String blue = '\x1B[34m';
const String cyan = '\x1B[36m';
const String bold = '\x1B[1m';

bool get supportsColor => stdout.supportsAnsiEscapes;

/// Wraps text with ANSI code if supported.
String colorized(String text, String code) {
  if (supportsColor) {
    return '$code$text$reset';
  }
  return text;
}

/// Prints a message in green.
void printSuccess(String message) {
  if (supportsColor) {
    print('$green$message$reset');
  } else {
    print(message);
  }
}

/// Prints a message in red.
void printError(String message) {
  if (supportsColor) {
    print('${bold}${red}Error:$reset $red$message$reset');
  } else {
    print('Error: $message');
  }
}

/// Prints a message in yellow.
void printWarning(String message) {
  if (supportsColor) {
    print('$yellow$message$reset');
  } else {
    print(message);
  }
}

/// Prints a message in blue.
void printInfo(String message) {
  if (supportsColor) {
    print('$blue$message$reset');
  } else {
    print(message);
  }
}
