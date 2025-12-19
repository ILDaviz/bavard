/// Helpers for ORM 'Convention over Configuration' naming resolution.
class Utils {
  /// Heuristic-based plural-to-singular conversion.
  ///
  /// **Trade-off**: Naive implementation for performance/size. Handles standard
  /// suffixes ('ies', 's') but does not support irregular English plurals (e.g., 'mice').
  static String singularize(String word) {
    if (word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }

    return word;
  }

  /// Infers foreign key column name from a table name (e.g., `users` -> `user_id`).
  static String foreignKey(String tableName) {
    return '${singularize(tableName)}_id';
  }
}
