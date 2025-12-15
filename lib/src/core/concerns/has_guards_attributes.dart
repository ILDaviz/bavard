/// Implements Mass Assignment protection to secure models against unsafe data injection.
///
/// Prevents sensitive attributes (e.g., `is_admin`, `id`) from being overwritten
/// by raw input maps. Uses a priority system: Global Unguard > Whitelist ([fillable]) > Blacklist ([guarded]).
mixin HasGuardsAttributes {
  /// Attributes explicitly allowed for bulk assignment (whitelist).
  ///
  /// If populated, ONLY these keys are accepted by [fill]; [guarded] becomes irrelevant.
  List<String> get fillable => [];

  /// Attributes blocked from bulk assignment (blacklist).
  ///
  /// Defaults to `['*']` (deny-all) for security. Only active if [fillable] is empty.
  List<String> get guarded => ['*'];

  static bool _unguarded = false;

  /// Globally disables protection. Use strictly for trusted contexts (seeders, migrations, tests).
  static void unguard([bool state = true]) => _unguarded = state;

  /// Re-enables global protection.
  static void reguard() => _unguarded = false;

  /// Safely hydrates the model from [attributes], filtering out forbidden keys.
  ///
  /// Relies on dynamic dispatch to invoke `setAttribute` (typically provided by `HasCasts`).
  void fill(Map<String, dynamic> attributes) {
    attributes.forEach((key, value) {
      if (isFillable(key)) {
        (this as dynamic).setAttribute(key, value);
      }
    });
  }

  /// Bypasses all security guards to set attributes.
  ///
  /// **Security Risk**: Use only for trusted internal operations.
  void forceFill(Map<String, dynamic> attributes) {
    attributes.forEach((key, value) {
      (this as dynamic).setAttribute(key, value);
    });
  }

  /// Determines if [key] is safe to write.
  ///
  /// Resolution order:
  /// 1. Global unguard check.
  /// 2. Whitelist check (if [fillable] is not empty).
  /// 3. Blacklist check (against [guarded]).
  bool isFillable(String key) {
    if (_unguarded) return true;

    // Whitelist mode: strict adherence to fillable.
    if (fillable.contains(key)) {
      return true;
    }
    if (fillable.isNotEmpty) {
      return false;
    }

    // Blacklist mode: defaults to deny-all ('*') if no specific rules exist.
    if (guarded.contains('*') || guarded.contains(key)) {
      return false;
    }

    return true;
  }
}