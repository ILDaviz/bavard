import '../exceptions.dart';
import '../model.dart';
import '../query_builder.dart';
import 'base.dart';
import 'identifiers.dart';

/// JOIN clauses and eager-load relationship queueing.
mixin JoinClauses<T extends Model> on QueryBuilderBase<T> {
  QueryBuilder<T> join(
    String table,
    dynamic one,
    String operator,
    dynamic two,
  ) {
    assertIdentifier(table, dotted: false, what: 'join table name');
    final targetOne = resolveColumnName(one);
    final targetTwo = resolveColumnName(two);

    assertIdentifier(targetOne, dotted: true, what: 'join lhs');
    assertIdentifier(targetTwo, dotted: true, what: 'join rhs');

    final op = normalizeOperator(operator);
    if (!allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    joinClauses.add(
      'JOIN ${grammar.wrap(table)} ON ${grammar.wrap(targetOne)} $op ${grammar.wrap(targetTwo)}',
    );
    return this as QueryBuilder<T>;
  }

  /// Adds a LEFT JOIN clause.
  QueryBuilder<T> leftJoin(
    String table,
    dynamic one,
    String operator,
    dynamic two,
  ) {
    assertIdentifier(table, dotted: false, what: 'join table name');
    final targetOne = resolveColumnName(one);
    final targetTwo = resolveColumnName(two);

    assertIdentifier(targetOne, dotted: true, what: 'join lhs');
    assertIdentifier(targetTwo, dotted: true, what: 'join rhs');

    final op = normalizeOperator(operator);
    if (!allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    joinClauses.add(
      'LEFT JOIN ${grammar.wrap(table)} ON ${grammar.wrap(targetOne)} $op ${grammar.wrap(targetTwo)}',
    );
    return this as QueryBuilder<T>;
  }

  /// Adds a RIGHT JOIN clause.
  QueryBuilder<T> rightJoin(
    String table,
    dynamic one,
    String operator,
    dynamic two,
  ) {
    assertIdentifier(table, dotted: false, what: 'join table name');
    final targetOne = resolveColumnName(one);
    final targetTwo = resolveColumnName(two);

    assertIdentifier(targetOne, dotted: true, what: 'join lhs');
    assertIdentifier(targetTwo, dotted: true, what: 'join rhs');

    final op = normalizeOperator(operator);
    if (!allowedJoinOps.contains(op)) {
      throw InvalidQueryException('Invalid operator for join: $operator');
    }

    joinClauses.add(
      'RIGHT JOIN ${grammar.wrap(table)} ON ${grammar.wrap(targetOne)} $op ${grammar.wrap(targetTwo)}',
    );
    return this as QueryBuilder<T>;
  }

  /// Queues relationships for eager loading after the main query execution.
  ///
  /// Critical for performance optimization (mitigates N+1 queries).
  ///
  /// Accepts:
  /// - `List<String>`: `['posts', 'posts.comments']`
  /// - `Map<String, ScopeCallback>`: `{'posts': (q) => q.where('active', 1)}`
  QueryBuilder<T> withRelations(dynamic relations) {
    if (relations is List) {
      for (final relation in relations) {
        eagerLoads[relation.toString()] = null;
      }
    } else if (relations is Map) {
      relations.forEach((key, value) {
        if (value is ScopeCallback) {
          eagerLoads[key.toString()] = value;
        } else if (value == null) {
          eagerLoads[key.toString()] = null;
        } else {
          throw ArgumentError('Invalid scope callback for relation $key');
        }
      });
    } else {
      throw ArgumentError('withRelations expects a List or Map.');
    }
    return this as QueryBuilder<T>;
  }
}
