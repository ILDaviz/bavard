/// Base exception for all ORM-related errors.
///
/// Provides a common ancestor for catching any Bavard exception
/// while allowing specific handling via subclasses.
abstract class BavardException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const BavardException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => 'ActiveSyncException: $message';
}

/// Thrown when a requested model cannot be found in the database.
///
/// Typically raised by `findOrFail()` or `firstOrFail()` when no matching
/// record exists.
class ModelNotFoundException extends BavardException {
  final String model;
  final dynamic id;

  const ModelNotFoundException({
    required this.model,
    this.id,
    String? message,
    StackTrace? stackTrace,
  }) : super(
          message ??
              'No query results for model [$model]${id != null ? ' with ID: $id' : ''}.',
          null,
          stackTrace,
        );

  @override
  String toString() => 'ModelNotFoundException: $message';
}

/// Thrown when a database query fails to execute.
///
/// Wraps the underlying driver exception with additional context
/// about the failing SQL statement.
class QueryException extends BavardException {
  final String sql;
  final List<dynamic>? bindings;

  const QueryException({
    required this.sql,
    this.bindings,
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError, stackTrace);

  @override
  String toString() =>
      'QueryException: $message\nSQL: $sql\nBindings: $bindings';
}

/// Thrown when a database transaction fails.
///
/// Contains information about whether the transaction was rolled back
/// and the original cause of failure.
class TransactionException extends BavardException {
  final bool wasRolledBack;

  const TransactionException({
    required String message,
    this.wasRolledBack = true,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError, stackTrace);

  @override
  String toString() =>
      'TransactionException: $message (Rolled back: $wasRolledBack)';
}

/// Thrown when attempting to use the database before initialization.
///
/// Signals that `DatabaseManager().setDatabase()` was not called.
class DatabaseNotInitializedException extends BavardException {
  const DatabaseNotInitializedException([StackTrace? stackTrace])
    : super(
        'Database driver not initialized. '
        'Call DatabaseManager().setDatabase(driver) first.',
        null,
        stackTrace,
      );

  @override
  String toString() => 'DatabaseNotInitializedException: $message';
}

/// Thrown when mass assignment protection blocks an attribute.
///
/// Useful for debugging when `fill()` silently ignores fields.
class MassAssignmentException extends BavardException {
  final String attribute;
  final String model;

  const MassAssignmentException({
    required this.attribute,
    required this.model,
    StackTrace? stackTrace,
  }) : super(
          'Cannot mass-assign [$attribute] on model [$model].',
          null,
          stackTrace,
        );

  @override
  String toString() => 'MassAssignmentException: $message';
}

/// Thrown when an invalid query structure is detected.
///
/// Examples: Invalid operator, malformed identifier, or conflicting clauses.
class InvalidQueryException extends BavardException {
  const InvalidQueryException(String message, {StackTrace? stackTrace})
    : super(message, null, stackTrace);

  @override
  String toString() => 'InvalidQueryException: $message';
}

/// Thrown when a relationship cannot be resolved.
///
/// May occur due to missing foreign keys, invalid type maps (MorphTo),
/// or undefined relation methods.
class RelationNotFoundException extends BavardException {
  final String relation;
  final String model;

  const RelationNotFoundException({
    required this.relation,
    required this.model,
    StackTrace? stackTrace,
  }) : super(
          'Relation [$relation] not found on model [$model].',
          null,
          stackTrace,
        );

  @override
  String toString() => 'RelationNotFoundException: $message';
}
