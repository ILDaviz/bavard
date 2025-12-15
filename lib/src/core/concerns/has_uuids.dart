import 'package:uuid/uuid.dart';
import '../model.dart';

/// Enforces client-side UUID generation for Primary Keys (UUID v4).
///
/// Ideal for distributed systems or offline-first architectures where
/// records must have a guaranteed unique identity before reaching the central database.
mixin HasUuids on Model {
  /// Pre-save hook: Lazily assigns a UUID v4 if the ID is missing.
  ///
  /// Prevents database round-trips for ID generation and allows for
  /// immediate reference to the object in relations/UI before persistence.
  @override
  Future<bool> onSaving() async {
    id ??= const Uuid().v4();
    return super.onSaving();
  }

  /// Signals the ORM that the Primary Key is not database-managed (auto-increment).
  ///
  /// This prevents the framework from attempting to retrieve the "last inserted ID"
  /// and ensures the ID is treated as a string rather than an integer.
  bool get incrementing => false;
}