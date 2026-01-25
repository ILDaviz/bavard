/// Represents a column definition in a table blueprint.
class ColumnDefinition {
  final String name;
  final String type;
  bool isNullable = false;
  bool isPrimaryKey = false;
  bool isAutoIncrement = false;
  bool isUnique = false;
  bool isUnsigned = false;
  dynamic defaultValue;
  
  // Additional properties for specific types
  int? length;
  int? precision;
  int? scale;
  List<String>? allowedValues;
  bool useCurrent = false;

  ColumnDefinition(this.name, this.type);

  ColumnDefinition nullable() {
    isNullable = true;
    return this;
  }
  
  ColumnDefinition primary() {
    isPrimaryKey = true;
    return this;
  }

  ColumnDefinition unique() {
    isUnique = true;
    return this;
  }

  ColumnDefinition unsigned() {
    isUnsigned = true;
    return this;
  }
  
  ColumnDefinition useCurrentTimestamp() {
    useCurrent = true;
    return this;
  }
  
  ColumnDefinition defaultTo(dynamic value) {
    defaultValue = value;
    return this;
  }
}

/// Represents an index or constraint definition.
class IndexDefinition {
  final String type;
  final List<String> columns;
  final String? name;
  String? _language;

  IndexDefinition(this.type, this.columns, {this.name});

  String? get languageValue => _language;

  IndexDefinition language(String lang) {
    _language = lang;
    return this;
  }
}

/// Defines the schema of a table to be created.
class Blueprint {
  final String table;
  final List<ColumnDefinition> columns = [];
  final List<IndexDefinition> commands = [];

  Blueprint(this.table);

  // --- ID & Increments ---

  void id() {
    bigIncrements('id');
  }

  ColumnDefinition increments(String name) {
     return unsignedInteger(name)..isPrimaryKey = true..isAutoIncrement = true;
  }

  ColumnDefinition bigIncrements(String name) {
     return unsignedBigInteger(name)..isPrimaryKey = true..isAutoIncrement = true;
  }

  // --- Strings ---

  ColumnDefinition string(String name, [int length = 255]) {
    final col = ColumnDefinition(name, 'string')..length = length;
    columns.add(col);
    return col;
  }

  ColumnDefinition char(String name, [int length = 255]) {
    final col = ColumnDefinition(name, 'char')..length = length;
    columns.add(col);
    return col;
  }

  ColumnDefinition text(String name) {
    final col = ColumnDefinition(name, 'text');
    columns.add(col);
    return col;
  }
  
  ColumnDefinition mediumText(String name) {
    final col = ColumnDefinition(name, 'mediumText');
    columns.add(col);
    return col;
  }
  
  ColumnDefinition longText(String name) {
    final col = ColumnDefinition(name, 'longText');
    columns.add(col);
    return col;
  }

  // --- Integers ---

  ColumnDefinition integer(String name) {
    final col = ColumnDefinition(name, 'integer');
    columns.add(col);
    return col;
  }

  ColumnDefinition tinyInteger(String name) {
    final col = ColumnDefinition(name, 'tinyInteger');
    columns.add(col);
    return col;
  }

  ColumnDefinition smallInteger(String name) {
    final col = ColumnDefinition(name, 'smallInteger');
    columns.add(col);
    return col;
  }

  ColumnDefinition mediumInteger(String name) {
    final col = ColumnDefinition(name, 'mediumInteger');
    columns.add(col);
    return col;
  }

  ColumnDefinition bigInteger(String name) {
    final col = ColumnDefinition(name, 'bigInteger');
    columns.add(col);
    return col;
  }

  ColumnDefinition unsignedInteger(String name) {
    return integer(name).unsigned();
  }

  ColumnDefinition unsignedTinyInteger(String name) {
    return tinyInteger(name).unsigned();
  }

  ColumnDefinition unsignedSmallInteger(String name) {
    return smallInteger(name).unsigned();
  }

  ColumnDefinition unsignedMediumInteger(String name) {
    return mediumInteger(name).unsigned();
  }

  ColumnDefinition unsignedBigInteger(String name) {
    return bigInteger(name).unsigned();
  }

  // --- Floats & Decimals ---

  ColumnDefinition float(String name) {
    final col = ColumnDefinition(name, 'float');
    columns.add(col);
    return col;
  }

  ColumnDefinition double(String name) {
    final col = ColumnDefinition(name, 'double');
    columns.add(col);
    return col;
  }

  ColumnDefinition decimal(String name, [int precision = 8, int scale = 2]) {
    final col = ColumnDefinition(name, 'decimal')
      ..precision = precision
      ..scale = scale;
    columns.add(col);
    return col;
  }

  // --- Boolean ---

  ColumnDefinition boolean(String name) {
    final col = ColumnDefinition(name, 'boolean');
    columns.add(col);
    return col;
  }

  // --- Date & Time ---

  ColumnDefinition date(String name) {
    final col = ColumnDefinition(name, 'date');
    columns.add(col);
    return col;
  }

  ColumnDefinition dateTime(String name) {
    final col = ColumnDefinition(name, 'dateTime');
    columns.add(col);
    return col;
  }
  
  ColumnDefinition dateTimeTz(String name) {
    final col = ColumnDefinition(name, 'dateTimeTz');
    columns.add(col);
    return col;
  }

  ColumnDefinition time(String name) {
    final col = ColumnDefinition(name, 'time');
    columns.add(col);
    return col;
  }
  
  ColumnDefinition timeTz(String name) {
    final col = ColumnDefinition(name, 'timeTz');
    columns.add(col);
    return col;
  }

  ColumnDefinition timestamp(String name) {
    final col = ColumnDefinition(name, 'timestamp');
    columns.add(col);
    return col;
  }
  
  ColumnDefinition timestampTz(String name) {
    final col = ColumnDefinition(name, 'timestampTz');
    columns.add(col);
    return col;
  }
  
  void timestamps() {
    timestamp('created_at').nullable();
    timestamp('updated_at').nullable();
  }
  
  void timestampsTz() {
    timestampTz('created_at').nullable();
    timestampTz('updated_at').nullable();
  }
  
  ColumnDefinition softDeletes([String name = 'deleted_at']) {
    return timestamp(name).nullable();
  }
  
  ColumnDefinition softDeletesTz([String name = 'deleted_at']) {
    return timestampTz(name).nullable();
  }

  // --- Binary ---

  ColumnDefinition binary(String name) {
    final col = ColumnDefinition(name, 'binary');
    columns.add(col);
    return col;
  }

  // --- JSON ---

  ColumnDefinition json(String name) {
    final col = ColumnDefinition(name, 'json');
    columns.add(col);
    return col;
  }
  
  ColumnDefinition jsonb(String name) {
    final col = ColumnDefinition(name, 'jsonb');
    columns.add(col);
    return col;
  }

  // --- UUID / ULID ---

  ColumnDefinition uuid(String name) {
    final col = ColumnDefinition(name, 'uuid');
    columns.add(col);
    return col;
  }

  // --- Specialty ---
  
  ColumnDefinition enumCol(String name, List<String> allowed) {
    final col = ColumnDefinition(name, 'enum')..allowedValues = allowed;
    columns.add(col);
    return col;
  }

  ColumnDefinition ipAddress(String name) {
    final col = ColumnDefinition(name, 'ipAddress');
    columns.add(col);
    return col;
  }
  
  ColumnDefinition macAddress(String name) {
    final col = ColumnDefinition(name, 'macAddress');
    columns.add(col);
    return col;
  }

  void rememberToken() {
    string('remember_token', 100).nullable();
  }

  void morphs(String name) {
    unsignedBigInteger('${name}_id');
    string('${name}_type');
    index(['${name}_type', '${name}_id']);
  }
  
  void uuidMorphs(String name) {
    uuid('${name}_id');
    string('${name}_type');
    index(['${name}_type', '${name}_id']);
  }

  // --- Indexes ---

  IndexDefinition primary(dynamic columns) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('primary', list);
    commands.add(index);
    return index;
  }

  IndexDefinition unique(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('unique', list, name: name);
    commands.add(index);
    return index;
  }

  IndexDefinition index(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('index', list, name: name);
    commands.add(index);
    return index;
  }

  IndexDefinition fullText(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('fulltext', list, name: name);
    commands.add(index);
    return index;
  }

  IndexDefinition spatialIndex(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('spatial', list, name: name);
    commands.add(index);
    return index;
  }
}
