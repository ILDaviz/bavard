/// Helpers for ORM 'Convention over Configuration' naming resolution.
class Utils {
  /// Heuristic-based plural-to-singular conversion.
  ///
  /// Improved implementation to handle common English pluralization rules
  /// used in database schemas (e.g. addresses, categories, boxes).
  /// IMPORTANT! THIS IS PLACE HOLDER.
  /// I'm search for good replacement.
  static String singularize(String word) {
    final lower = word.toLowerCase();

    // 1. Common Irregulars
    const irregulars = {
      'people': 'person',
      'men': 'man',
      'women': 'woman',
      'children': 'child',
      'teeth': 'tooth',
      'feet': 'foot',
      'mice': 'mouse',
      'geese': 'goose',
    };
    if (irregulars.containsKey(lower)) {
      return irregulars[lower]!;
    }

    // 2. Uncountables (return as is)
    const uncountables = {
      'equipment',
      'information',
      'rice',
      'money',
      'species',
      'series',
      'fish',
      'sheep',
    };
    if (uncountables.contains(lower)) {
      return word;
    }

    // 3. Rules

    // -ves (lives -> life, wolves -> wolf)
    if (word.endsWith('ves')) {
      // knives -> knife, leaves -> leaf.
    }

    // -ies (categories -> category)
    if (word.endsWith('ies')) {
      if (word.endsWith('eies') || word.endsWith('aies')) {
        return '${word.substring(0, word.length - 3)}y';
      }
      return '${word.substring(0, word.length - 3)}y';
    }

    // -es (boxes -> box, buses -> bus, searches -> search)
    if (word.endsWith('es')) {
      final base = word.substring(0, word.length - 2);
      if (base.endsWith('s') ||
          base.endsWith('x') ||
          base.endsWith('z') ||
          base.endsWith('ch') ||
          base.endsWith('sh')) {
        return base;
      }
    }

    // -s (users -> user)
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
