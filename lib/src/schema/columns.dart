class WhereCondition {
  final String column;
  final String operator;
  final dynamic value;
  final String boolean;

  const WhereCondition(this.column, this.operator, this.value, {this.boolean = 'AND'});
}

abstract class Column<T> {
  final String? name;
  final bool isNullable;
  final bool isGuarded;

  const Column(this.name, {this.isNullable = false, this.isGuarded = false});

  String get schemaType;

  @override
  String toString() => name ?? '';

  WhereCondition equals(T value) =>
      WhereCondition(toString(), '=', value);

  WhereCondition notEquals(T value) =>
      WhereCondition(toString(), '!=', value);

  WhereCondition isNull() =>
      WhereCondition(toString(), 'IS', null);

  WhereCondition isNotNull() =>
      WhereCondition(toString(), 'IS NOT', null);

  WhereCondition inList(List<T> values) =>
      WhereCondition(toString(), 'IN', values);

  WhereCondition notInList(List<T> values) =>
      WhereCondition(toString(), 'NOT IN', values);
}

class TextColumn extends Column<String> {
  const TextColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'string';

  WhereCondition contains(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%');

  WhereCondition startsWith(String value) =>
      WhereCondition(name!, 'LIKE', '$value%');

  WhereCondition endsWith(String value) =>
      WhereCondition(name!, 'LIKE', '%$value');
}

class IntColumn extends Column<int> {
  const IntColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'integer';

  WhereCondition greaterThan(int value) =>
      WhereCondition(name!, '>', value);

  WhereCondition lessThan(int value) =>
      WhereCondition(name!, '<', value);

  WhereCondition greaterThanOrEqual(int value) =>
      WhereCondition(name!, '>=', value);

  WhereCondition lessThanOrEqual(int value) =>
      WhereCondition(name!, '<=', value);

  WhereCondition between(int min, int max) =>
      WhereCondition(name!, 'BETWEEN', [min, max]);
}

class DoubleColumn extends Column<double> {
  const DoubleColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'doubleType';

  WhereCondition greaterThan(double value) =>
      WhereCondition(name!, '>', value);

  WhereCondition lessThan(double value) =>
      WhereCondition(name!, '<', value);

  WhereCondition greaterThanOrEqual(double value) =>
      WhereCondition(name!, '>=', value);

  WhereCondition lessThanOrEqual(double value) =>
      WhereCondition(name!, '<=', value);

  WhereCondition between(double min, double max) =>
      WhereCondition(name!, 'BETWEEN', [min, max]);
}

class BoolColumn extends Column<bool> {
  const BoolColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'boolean';

  WhereCondition isTrue() => WhereCondition(name!, '=', 1);
  WhereCondition isFalse() => WhereCondition(name!, '=', 0);
}

class DateTimeColumn extends Column<DateTime> {
  const DateTimeColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'datetime';

  WhereCondition after(DateTime value) =>
      WhereCondition(name!, '>', value.toIso8601String());

  WhereCondition before(DateTime value) =>
      WhereCondition(name!, '<', value.toIso8601String());

  WhereCondition between(DateTime start, DateTime end) =>
      WhereCondition(name!, 'BETWEEN', [start, end]);
}

class JsonPathColumn<T> extends Column<T> {
  final String rootColumn;
  final String path;

  JsonPathColumn(this.rootColumn, this.path) : super(null);

  @override
  String get schemaType => 'json_path';

  @override
  String toString() => "json_extract($rootColumn, '\$.$path')";

  WhereCondition greaterThan(num value) => WhereCondition(toString(), '>', value);
  WhereCondition lessThan(num value) => WhereCondition(toString(), '<', value);
  WhereCondition greaterThanOrEqual(num value) => WhereCondition(toString(), '>=', value);
  WhereCondition lessThanOrEqual(num value) => WhereCondition(toString(), '<=', value);
  WhereCondition contains(String value) => WhereCondition(toString(), 'LIKE', '%$value%');
  JsonPathColumn<R> key<R>(String subPath) {
    return JsonPathColumn<R>(rootColumn, '$path.$subPath');
  }
  JsonPathColumn<R> index<R>(int i) {
    return JsonPathColumn<R>(rootColumn, '$path[$i]');
  }
}

class JsonColumn extends Column<dynamic> {
  const JsonColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'json';

  WhereCondition containsPattern(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%');

  JsonPathColumn<T> key<T>(String path) => JsonPathColumn<T>(name!, path);
}

class ArrayColumn extends Column<List<dynamic>> {
  const ArrayColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'array';

  WhereCondition containsPattern(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%');

  JsonPathColumn<T> index<T>(int index) => JsonPathColumn<T>(name!, '[$index]');
}

class ObjectColumn extends Column<Map<String, dynamic>> {
  const ObjectColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'object';

  WhereCondition containsPattern(String value) =>
      WhereCondition(name!, 'LIKE', '%$value%');

  JsonPathColumn<T> key<T>(String path) => JsonPathColumn<T>(name!, path);
}

class EnumColumn<T extends Enum> extends Column<T> {
  const EnumColumn(super.name, {super.isNullable, super.isGuarded});

  @override
  String get schemaType => 'string';

  @override
  WhereCondition equals(T value) => WhereCondition(name!, '=', value.name);

  @override
  WhereCondition notEquals(T value) => WhereCondition(name!, '!=', value.name);

  @override
  WhereCondition inList(List<T> values) =>
      WhereCondition(name!, 'IN', values.map((e) => e.name).toList());

  @override
  WhereCondition notInList(List<T> values) =>
      WhereCondition(name!, 'NOT IN', values.map((e) => e.name).toList());
}