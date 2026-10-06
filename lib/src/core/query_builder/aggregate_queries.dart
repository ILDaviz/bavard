import '../database_manager.dart';
import '../exceptions.dart';
import '../grammar.dart';
import '../model.dart';
import 'base.dart';

/// Aggregate helpers (COUNT, SUM, AVG, MIN, MAX) and existence checks.
mixin AggregateQueries<T extends Model> on QueryBuilderBase<T> {
  /// Checks existence by fetching a single record (Limit 1 optimization).
  Future<bool> exists() async {
    final clone = cast<T>(creator, instanceFactory: instanceFactory);
    clone.limit(1);
    final results = await clone.get();
    return results.isNotEmpty;
  }

  Future<bool> notExist() async {
    return !await exists();
  }

  Future<int?> count([dynamic column = '*']) async {
    final targetColumn = column == '*'
        ? '*'
        : grammar.wrap(resolveColumnName(column));

    if (groupByColumns.isNotEmpty ||
        havingClauses.isNotEmpty ||
        unionQueries.isNotEmpty) {
      final dbManager = DatabaseManager();
      final subQuery = compileSql();
      final bindings = grammar.prepareBindings(getAllBindings());
      final wrapperSql =
          'SELECT COUNT(*) as aggregate FROM ($subQuery) as temp_table';
      try {
        final row = await dbManager.get(wrapperSql, bindings);
        if (row.isEmpty || row['aggregate'] == null) return 0;

        final value = row['aggregate'];
        return (value is num) ? value.toInt() : value as int;
      } catch (e) {
        throw QueryException(
          sql: wrapperSql,
          bindings: bindings,
          message:
              'Failed to execute count with group by or unions: ${e.toString()}',
          originalError: e,
        );
      }
    }

    return await _scalar<int>('COUNT($targetColumn)');
  }

  Future<num> sum(dynamic column) async {
    _guardAgainstGrouping('sum');
    final targetColumn = grammar.wrap(resolveColumnName(column));
    return await _scalar<num>('SUM($targetColumn)') ?? 0;
  }

  Future<double?> avg(dynamic column) async {
    _guardAgainstGrouping('avg');
    final targetColumn = grammar.wrap(resolveColumnName(column));
    final result = await _scalar('AVG($targetColumn)');
    if (result == null) return null;
    if (result is num) return result.toDouble();
    if (result is String) return double.tryParse(result);
    return null;
  }

  Future<dynamic> max(dynamic column) async {
    _guardAgainstGrouping('max');
    final targetColumn = grammar.wrap(resolveColumnName(column));
    return await _scalar('MAX($targetColumn)');
  }

  Future<dynamic> min(dynamic column) async {
    _guardAgainstGrouping('min');
    final targetColumn = grammar.wrap(resolveColumnName(column));
    return await _scalar('MIN($targetColumn)');
  }

  void _guardAgainstGrouping(String method) {
    if (groupByColumns.isNotEmpty || havingClauses.isNotEmpty) {
      throw QueryException(
        sql: compileSql(),
        bindings: [],
        message:
            'Cannot use $method() with groupBy() or having(). '
            'This would return a single value from a list of groups, which is ambiguous or mathematically wrong. '
            'Use get() to retrieve grouped results.',
      );
    }
  }

  /// Helper for aggregate queries (Count, Sum, etc).
  ///
  /// Modifies the SELECT clause to return a single scalar value.
  Future<R?> _scalar<R>(String expression) async {
    applyScopes();
    final dbManager = DatabaseManager();

    if (unionQueries.isNotEmpty) {
      final subQuery = compileSql();
      final bindings = grammar.prepareBindings(getAllBindings());
      final wrapperSql =
          'SELECT $expression as aggregate FROM ($subQuery) as temp_table';

      try {
        final row = await dbManager.get(wrapperSql, bindings);
        if (row.isEmpty || row['aggregate'] == null) return null;

        final value = row['aggregate'];
        if (R == int && value is num) return value.toInt() as R;
        if (R == double && value is num) return value.toDouble() as R;
        return value as R;
      } catch (e) {
        throw QueryException(
          sql: wrapperSql,
          bindings: bindings,
          message:
              'Failed to execute scalar query with unions: ${e.toString()}',
          originalError: e,
        );
      }
    }

    final originalColumns = selectColumns;
    selectColumns = [RawExpression('$expression as aggregate')];

    final sql = compileSql();
    selectColumns = originalColumns;

    final allBindings = grammar.prepareBindings(getAllBindings());

    try {
      final row = await dbManager.get(sql, allBindings);

      if (row.isEmpty || row['aggregate'] == null) {
        return null;
      }

      final value = row['aggregate'];

      if (R == int && value is num) {
        return value.toInt() as R;
      }
      if (R == double && value is num) {
        return value.toDouble() as R;
      }

      return value as R;
    } catch (e) {
      throw QueryException(
        sql: sql,
        bindings: allBindings,
        message: 'Failed to execute aggregate query: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
