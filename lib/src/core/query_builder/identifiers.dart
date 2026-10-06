import '../exceptions.dart';

/// Strict identifier patterns guarding against SQL injection in identifiers
/// (tables, columns), which cannot be parameterized.
final RegExp _tableIdentifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

final RegExp _dottedIdentifier = RegExp(
  r'^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$',
);

/// Operators accepted in WHERE clauses (logic-injection whitelist).
const Set<String> allowedWhereOps = {
  '=',
  '!=',
  '<>',
  '>',
  '<',
  '>=',
  '<=',
  'LIKE',
  'NOT LIKE',
};

/// Operators accepted in JOIN ... ON clauses.
const Set<String> allowedJoinOps = {'=', '!=', '<>', '>', '<', '>=', '<='};

/// Operators accepted in HAVING clauses.
const Set<String> allowedHavingOps = {'=', '!=', '<>', '>', '<', '>=', '<='};

/// Normalizes an operator (trim + uppercase) for whitelist comparison.
String normalizeOperator(String op) => op.trim().toUpperCase();

/// Security Check: Ensures identifiers (tables, columns) match a strict regex.
///
/// Necessary because identifiers cannot be parameterized in SQL, making them
/// vulnerable to injection if not sanitized.
void assertIdentifier(
  String v, {
  required bool dotted,
  required String what,
}) {
  final ok = dotted
      ? _dottedIdentifier.hasMatch(v)
      : _tableIdentifier.hasMatch(v);
  if (!ok) {
    throw InvalidQueryException('Invalid $what: $v');
  }
}
