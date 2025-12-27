/// Represents a single query predicate (e.g., "age > 18").
/// Used to build the WHERE clause of a database query.
class WhereCondition {
  final String column;
  final String operator;
  final dynamic value;
  final String boolean;
  final Column? sourceColumn;

  const WhereCondition(
    this.column,
    this.operator,
    this.value, {
    this.boolean = 'AND',
    this.sourceColumn,
  });
}

/// Base interface to allow polymorphic lists of Columns with different generic types.
abstract class SchemaColumn {
  String? get name;
}

/// Abstract definition of a database schema column.
/// [T] is the Dart type associated with the column's value.
abstract class Column<T> implements SchemaColumn {
  @override
  final String? name;
  final bool isNullable;

  /// Prevents this column from being mass-assigned during inserts/updates.
  /// This isGuarded is ignored on pivot column.
  final bool isGuarded;

  const Column(this.name, {this.isNullable = false, this.isGuarded = false});

  /// The underlying SQL data type definition.
  String get schemaType;

  /// Returns the raw column name or expression used in query generation.
  @override
  String toString() => name ?? '';

  WhereCondition equals(T value) =>
      WhereCondition(toString(), '=', value, sourceColumn: this);

  WhereCondition notEquals(T value) =>
      WhereCondition(toString(), '!=', value, sourceColumn: this);

  WhereCondition isNull() =>
      WhereCondition(toString(), 'IS', null, sourceColumn: this);

  WhereCondition isNotNull() =>
      WhereCondition(toString(), 'IS NOT', null, sourceColumn: this);

  WhereCondition inList(List<T> values) =>
      WhereCondition(toString(), 'IN', values, sourceColumn: this);

  WhereCondition notInList(List<T> values) =>
      WhereCondition(toString(), 'NOT IN', values, sourceColumn: this);
}

/// Maps a Dart [String] to a database TEXT/VARCHAR column.
class TextColumn extends Column<String> {
  const TextColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'string';

  WhereCondition contains(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%', sourceColumn: this);

  WhereCondition startsWith(String value) =>
      WhereCondition(name!, 'LIKE', '$value%', sourceColumn: this);

  WhereCondition endsWith(String value) =>
      WhereCondition(name!, 'LIKE', '%$value', sourceColumn: this);
}

class IntColumn extends Column<int> {
  const IntColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'integer';

  WhereCondition greaterThan(int value) =>
      WhereCondition(name!, '>', value, sourceColumn: this);

  WhereCondition lessThan(int value) =>
      WhereCondition(name!, '<', value, sourceColumn: this);

  WhereCondition greaterThanOrEqual(int value) =>
      WhereCondition(name!, '>=', value, sourceColumn: this);

  WhereCondition lessThanOrEqual(int value) =>
      WhereCondition(name!, '<=', value, sourceColumn: this);

  WhereCondition between(int min, int max) =>
      WhereCondition(name!, 'BETWEEN', [min, max], sourceColumn: this);
}

class DoubleColumn extends Column<double> {
  const DoubleColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'doubleType';

  WhereCondition greaterThan(double value) =>
      WhereCondition(name!, '>', value, sourceColumn: this);

  WhereCondition lessThan(double value) =>
      WhereCondition(name!, '<', value, sourceColumn: this);

  WhereCondition greaterThanOrEqual(double value) =>
      WhereCondition(name!, '>=', value, sourceColumn: this);

  WhereCondition lessThanOrEqual(double value) =>
      WhereCondition(name!, '<=', value, sourceColumn: this);

  WhereCondition between(double min, double max) =>
      WhereCondition(name!, 'BETWEEN', [min, max], sourceColumn: this);
}

/// Maps a Dart [bool] to an integer column (1 for true, 0 for false).
/// Useful for databases like SQLite that lack a native BOOLEAN type.
class BoolColumn extends Column<bool> {
  const BoolColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'boolean';

  WhereCondition isTrue() => WhereCondition(name!, '=', 1, sourceColumn: this);
  WhereCondition isFalse() => WhereCondition(name!, '=', 0, sourceColumn: this);
}

/// Persists [DateTime] objects as ISO-8601 strings to maintain sorting and comparison capabilities.
class DateTimeColumn extends Column<DateTime> {
  const DateTimeColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'datetime';

  WhereCondition after(DateTime value) =>
      WhereCondition(name!, '>', value.toIso8601String(), sourceColumn: this);

  WhereCondition before(DateTime value) =>
      WhereCondition(name!, '<', value.toIso8601String(), sourceColumn: this);

  WhereCondition between(DateTime start, DateTime end) =>
      WhereCondition(name!, 'BETWEEN', [start, end], sourceColumn: this);
}

/// Represents a virtual column extracted from a JSON structure using a specific path.
///
/// This does not define a physical column but generates a `json_extract` expression
/// to query nested data within [rootColumn].
class JsonPathColumn<T> extends Column<T> {
  final String rootColumn;
  final String path;

  JsonPathColumn(this.rootColumn, this.path) : super(null);

  @override
  String get schemaType => 'json_path';

  /// Generates the SQL expression to extract the value at [path].
  @override
  String toString() => "json_extract($rootColumn, '\$.$path')";

  WhereCondition greaterThan(num value) =>
      WhereCondition(toString(), '>', value, sourceColumn: this);
  WhereCondition lessThan(num value) =>
      WhereCondition(toString(), '<', value, sourceColumn: this);
  WhereCondition greaterThanOrEqual(num value) =>
      WhereCondition(toString(), '>=', value, sourceColumn: this);
  WhereCondition lessThanOrEqual(num value) =>
      WhereCondition(toString(), '<=', value, sourceColumn: this);
  WhereCondition contains(String value) =>
      WhereCondition(toString(), 'LIKE', '%$value%', sourceColumn: this);

  /// Chains a sub-path to the current JSON extraction path.
  JsonPathColumn<R> key<R>(String subPath) {
    return JsonPathColumn<R>(rootColumn, '$path.$subPath');
  }

  /// Chains an array index selection to the current JSON extraction path.
  JsonPathColumn<R> index<R>(int i) {
    return JsonPathColumn<R>(rootColumn, '$path[$i]');
  }
}

/// A physical column storing arbitrary JSON data.
/// Acts as a factory for [JsonPathColumn] to query internal fields.
class JsonColumn extends Column<dynamic> {
  const JsonColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'json';

  WhereCondition containsPattern(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%', sourceColumn: this);

  /// Creates a virtual column pointing to a specific key within this JSON object.
  JsonPathColumn<T> key<T>(String path) => JsonPathColumn<T>(name!, path);
}

/// Specialized column for storing JSON arrays.
class ArrayColumn extends Column<List<dynamic>> {
  const ArrayColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'array';

  WhereCondition containsPattern(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%', sourceColumn: this);

  /// Creates a virtual column pointing to a specific index within this array.
  JsonPathColumn<T> index<T>(int index) => JsonPathColumn<T>(name!, '[$index]');
}

/// Specialized column for storing JSON objects (Maps).
class ObjectColumn extends Column<Map<String, dynamic>> {
  const ObjectColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'object';

  WhereCondition containsPattern(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%', sourceColumn: this);

  JsonPathColumn<T> key<T>(String path) => JsonPathColumn<T>(name!, path);
}

/// Maps Dart [Enum]s to database strings using the enum's `name`.
class EnumColumn<T extends Enum> extends Column<T> {
  const EnumColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'string';

  @override
  WhereCondition equals(T value) =>
      WhereCondition(name!, '=', value.name, sourceColumn: this);

  @override
  WhereCondition notEquals(T value) =>
      WhereCondition(name!, '!=', value.name, sourceColumn: this);

  @override
  WhereCondition inList(List<T> values) =>
      WhereCondition(
        name!,
        'IN',
        values.map((e) => e.name).toList(),
        sourceColumn: this,
      );

  @override
  WhereCondition notInList(List<T> values) =>
      WhereCondition(
        name!,
        'NOT IN',
        values.map((e) => e.name).toList(),
        sourceColumn: this,
      );
}

/// Represents the Primary Key column.
///
/// Can be mapped to an [int] (auto-increment) or [String] (UUID).
/// Usage: `IdColumn()` implies default 'id' name, or `IdColumn('uuid')`.
class IdColumn extends Column<dynamic> {
  const IdColumn([String? name = 'id', bool isNullable = false, bool isGuarded = true])
      : super(name, isNullable: isNullable, isGuarded: isGuarded);

  @override
  String get schemaType => 'id';
}

/// Represents the 'created_at' timestamp column.
class CreatedAtColumn extends DateTimeColumn {
  const CreatedAtColumn([
    String? name = 'created_at',
    bool isNullable = true,
    bool isGuarded = true,
  ]) : super(name, isNullable: isNullable, isGuarded: isGuarded);
}

/// Represents the 'updated_at' timestamp column.
class UpdatedAtColumn extends DateTimeColumn {
  const UpdatedAtColumn([
    String? name = 'updated_at',
    bool isNullable = true,
    bool isGuarded = true,
  ]) : super(name, isNullable: isNullable, isGuarded: isGuarded);
}

/// Represents the 'deleted_at' timestamp column for Soft Deletes.
class DeletedAtColumn extends DateTimeColumn {
  const DeletedAtColumn([
    String? name = 'deleted_at',
    bool isNullable = true,
    bool isGuarded = true,
  ]) : super(name, isNullable: isNullable, isGuarded: isGuarded);
}