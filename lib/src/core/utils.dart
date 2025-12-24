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
      'equipment', 'information', 'rice', 'money', 'species', 'series', 'fish', 'sheep'
    };
    if (uncountables.contains(lower)) {
      return word;
    }

    // 3. Rules

    // -ves (lives -> life, wolves -> wolf)
    if (word.endsWith('ves')) {
      // Very basic heuristic: if it ends in 'ives', usually 'ife' (lives -> life), else 'f' (wolves -> wolf)
      // But 'hives' -> 'hive'. Let's keep it simple for now:
      // knives -> knife, leaves -> leaf.
      // A common safe fallback for 'ves' is just replacing 'ves' with 'f' or 'fe'.
      // For DB table names, this is rare. Let's skip complex 'ves' logic to avoid over-engineering if not needed.
    }

    // -ies (categories -> category)
    if (word.endsWith('ies')) {
      if (word.endsWith('eies') || word.endsWith('aies')) {
        // e.g. zombies -> zombie (handled by standard 's' rule if we are careful)
        // But standard rule is consonant + y -> ies.
        return '${word.substring(0, word.length - 3)}y';
      }
      return '${word.substring(0, word.length - 3)}y';
    }

    // -es (boxes -> box, buses -> bus, searches -> search)
    // Suffixes that typically take -es: s, x, z, ch, sh
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
    // Avoid removing 's' if the word ends in 'ss' (address -> address, NOT addres)
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
