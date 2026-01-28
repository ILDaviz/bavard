/// Represents a column definition in a table blueprint.
/// Contains all necessary attributes like type, nullability, primary keys, etc.
class ColumnDefinition {
  final String name;
  final String type;
  bool isNullable = false;
  bool isPrimaryKey = false;
  bool isAutoIncrement = false;
  bool isUnique = false;
  bool isUnsigned = false;
  
  /// Indicates if this column should be modified instead of being created from scratch.
  bool isChange = false;
  dynamic defaultValue;
  
  // Additional properties for specific types
  int? length;
  int? precision;
  int? scale;
  List<String>? allowedValues;
  bool useCurrent = false;

  ColumnDefinition(this.name, this.type);

  /// Makes the column optional (can contain NULL).
  ColumnDefinition nullable() {
    isNullable = true;
    return this;
  }
  
  /// Sets the column as the primary key of the table.
  ColumnDefinition primary() {
    isPrimaryKey = true;
    return this;
  }

  /// Applies a unique constraint to the column.
  ColumnDefinition unique() {
    isUnique = true;
    return this;
  }

  /// Specifies that the numeric column does not accept negative values.
  ColumnDefinition unsigned() {
    isUnsigned = true;
    return this;
  }
  
  /// Sets the current timestamp as the default value (for date/time fields).
  ColumnDefinition useCurrentTimestamp() {
    useCurrent = true;
    return this;
  }
  
  /// Defines a default value for the column.
  ColumnDefinition defaultTo(dynamic value) {
    defaultValue = value;
    return this;
  }

  /// Marks the column for a structural modification (ALTER COLUMN).
  ColumnDefinition change() {
    isChange = true;
    return this;
  }
}

/// Base class for all schema commands (indexes, renames, deletions).
abstract class Command {
  /// The command type (e.g., 'index', 'primary', 'foreign').
  String get type;
}

/// Represents an index or constraint definition.
class IndexDefinition extends Command {
  final String _type;
  final List<String> columns;
  final String? name;
  String? _language;

  IndexDefinition(this._type, this.columns, {this.name});

  @override
  String get type => _type;

  String? get languageValue => _language;

  /// Specifies the language for FullText indexes (e.g., 'english').
  IndexDefinition language(String lang) {
    _language = lang;
    return this;
  }
}

/// Command to delete an existing index.
class DropIndexCommand extends Command {
  final String name;
  final String _type; // 'index', 'unique', 'primary', 'foreign'

  DropIndexCommand(this.name, this._type);

  @override
  String get type => 'drop${_capitalize(_type)}';
  
  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Command to delete one or more columns.
class DropColumnCommand extends Command {
  final List<String> columns;

  DropColumnCommand(this.columns);

  @override
  String get type => 'dropColumn';
}

/// Command to rename an existing column.
class RenameColumnCommand extends Command {
  final String from;
  final String to;

  RenameColumnCommand(this.from, this.to);

  @override
  String get type => 'renameColumn';
}

/// Represents a Foreign Key definition.
class ForeignKeyDefinition extends Command {
  final String column;
  String? _onTable;
  String? _referencesColumn;
  String? _onDelete;
  String? _onUpdate;

  ForeignKeyDefinition(this.column);

  @override
  String get type => 'foreign';

  /// Specifies the column referenced in the external table.
  ForeignKeyDefinition references(String column) {
    _referencesColumn = column;
    return this;
  }

  /// Specifies the table being referenced.
  ForeignKeyDefinition on(String table) {
    _onTable = table;
    return this;
  }

  /// Defines the action to take when the parent record is deleted (e.g., 'cascade').
  ForeignKeyDefinition onDelete(String action) {
    _onDelete = action;
    return this;
  }

  /// Defines the action to take when the parent record is updated.
  ForeignKeyDefinition onUpdate(String action) {
    _onUpdate = action;
    return this;
  }

  String? get onTable => _onTable;
  String? get referencesColumn => _referencesColumn;
  String? get onDeleteValue => _onDelete;
  String? get onUpdateValue => _onUpdate;
}


/// Blueprint defines the structure of a table (schema) in a fluent way.
/// It is used to create new tables or modify existing ones.
class Blueprint {
  final String table;
  
  /// List of defined columns.
  final List<ColumnDefinition> columns = [];
  
  /// List of commands (indexes, constraints, etc.).
  final List<Command> commands = [];
  
  /// Specific list for dropping foreign keys.
  final List<DropIndexCommand> dropForeigns = [];

  Blueprint(this.table);

  // --- ID & Increments ---

  /// Adds an auto-incrementing ID column (big integer).
  void id() {
    bigIncrements('id');
  }

  /// Adds an auto-incrementing integer column as primary key.
  ColumnDefinition increments(String name) {
     return unsignedInteger(name)..isPrimaryKey = true..isAutoIncrement = true;
  }

  /// Adds an auto-incrementing big integer column as primary key.
  ColumnDefinition bigIncrements(String name) {
     return unsignedBigInteger(name)..isPrimaryKey = true..isAutoIncrement = true;
  }

  // --- Strings ---

  /// Adds a string column (VARCHAR).
  ColumnDefinition string(String name, [int length = 255]) {
    final col = ColumnDefinition(name, 'string')..length = length;
    columns.add(col);
    return col;
  }

  /// Adds a fixed-length character column (CHAR).
  ColumnDefinition char(String name, [int length = 255]) {
    final col = ColumnDefinition(name, 'char')..length = length;
    columns.add(col);
    return col;
  }

  /// Adds a text column for long strings.
  ColumnDefinition text(String name) {
    final col = ColumnDefinition(name, 'text');
    columns.add(col);
    return col;
  }
  
  /// Adds a medium-sized text column.
  ColumnDefinition mediumText(String name) {
    final col = ColumnDefinition(name, 'mediumText');
    columns.add(col);
    return col;
  }
  
  /// Adds a long text column.
  ColumnDefinition longText(String name) {
    final col = ColumnDefinition(name, 'longText');
    columns.add(col);
    return col;
  }

  // --- Integers ---

  /// Adds a standard integer column.
  ColumnDefinition integer(String name) {
    final col = ColumnDefinition(name, 'integer');
    columns.add(col);
    return col;
  }

  /// Adds a very small integer column.
  ColumnDefinition tinyInteger(String name) {
    final col = ColumnDefinition(name, 'tinyInteger');
    columns.add(col);
    return col;
  }

  /// Adds a small integer column.
  ColumnDefinition smallInteger(String name) {
    final col = ColumnDefinition(name, 'smallInteger');
    columns.add(col);
    return col;
  }

  /// Adds a medium-sized integer column.
  ColumnDefinition mediumInteger(String name) {
    final col = ColumnDefinition(name, 'mediumInteger');
    columns.add(col);
    return col;
  }

  /// Adds a big integer column (64-bit).
  ColumnDefinition bigInteger(String name) {
    final col = ColumnDefinition(name, 'bigInteger');
    columns.add(col);
    return col;
  }

  /// Adds an unsigned (non-negative) integer column.
  ColumnDefinition unsignedInteger(String name) {
    return integer(name).unsigned();
  }

  /// Adds an unsigned tiny integer column.
  ColumnDefinition unsignedTinyInteger(String name) {
    return tinyInteger(name).unsigned();
  }

  /// Adds an unsigned small integer column.
  ColumnDefinition unsignedSmallInteger(String name) {
    return smallInteger(name).unsigned();
  }

  /// Adds an unsigned medium integer column.
  ColumnDefinition unsignedMediumInteger(String name) {
    return mediumInteger(name).unsigned();
  }

  /// Adds an unsigned big integer column.
  ColumnDefinition unsignedBigInteger(String name) {
    return bigInteger(name).unsigned();
  }

  // --- Floats & Decimals ---

  /// Adds a single-precision floating-point column.
  ColumnDefinition float(String name) {
    final col = ColumnDefinition(name, 'float');
    columns.add(col);
    return col;
  }

  /// Adds a double-precision floating-point column.
  ColumnDefinition double(String name) {
    final col = ColumnDefinition(name, 'double');
    columns.add(col);
    return col;
  }

  /// Adds a decimal column for exact values (e.g., prices).
  ColumnDefinition decimal(String name, [int precision = 8, int scale = 2]) {
    final col = ColumnDefinition(name, 'decimal')
      ..precision = precision
      ..scale = scale;
    columns.add(col);
    return col;
  }

  // --- Boolean ---

  /// Adds a boolean column (True/False).
  ColumnDefinition boolean(String name) {
    final col = ColumnDefinition(name, 'boolean');
    columns.add(col);
    return col;
  }

  // --- Date & Time ---

  /// Adds a date column (without time).
  ColumnDefinition date(String name) {
    final col = ColumnDefinition(name, 'date');
    columns.add(col);
    return col;
  }

  /// Adds a date and time column.
  ColumnDefinition dateTime(String name) {
    final col = ColumnDefinition(name, 'dateTime');
    columns.add(col);
    return col;
  }
  
  /// Adds a date and time column with Timezone support.
  ColumnDefinition dateTimeTz(String name) {
    final col = ColumnDefinition(name, 'dateTimeTz');
    columns.add(col);
    return col;
  }

  /// Adds a time-only column.
  ColumnDefinition time(String name) {
    final col = ColumnDefinition(name, 'time');
    columns.add(col);
    return col;
  }
  
  /// Adds a time-only column with Timezone support.
  ColumnDefinition timeTz(String name) {
    final col = ColumnDefinition(name, 'timeTz');
    columns.add(col);
    return col;
  }

  /// Adds a timestamp column.
  ColumnDefinition timestamp(String name) {
    final col = ColumnDefinition(name, 'timestamp');
    columns.add(col);
    return col;
  }
  
  /// Adds a timestamp column with Timezone support.
  ColumnDefinition timestampTz(String name) {
    final col = ColumnDefinition(name, 'timestampTz');
    columns.add(col);
    return col;
  }
  
  /// Automatically adds 'created_at' and 'updated_at' columns.
  void timestamps() {
    timestamp('created_at').nullable();
    timestamp('updated_at').nullable();
  }
  
  /// Adds 'created_at' and 'updated_at' columns with Timezone support.
  void timestampsTz() {
    timestampTz('created_at').nullable();
    timestampTz('updated_at').nullable();
  }
  
  /// Adds a 'deleted_at' column for Soft Delete support.
  ColumnDefinition softDeletes([String name = 'deleted_at']) {
    return timestamp(name).nullable();
  }
  
  /// Adds 'deleted_at' for Soft Delete with Timezone support.
  ColumnDefinition softDeletesTz([String name = 'deleted_at']) {
    return timestampTz(name).nullable();
  }

  // --- Binary ---

  /// Adds a column for binary data (BLOB).
  ColumnDefinition binary(String name) {
    final col = ColumnDefinition(name, 'binary');
    columns.add(col);
    return col;
  }

  // --- JSON ---

  /// Adds a JSON column.
  ColumnDefinition json(String name) {
    final col = ColumnDefinition(name, 'json');
    columns.add(col);
    return col;
  }
  
  /// Adds a JSONB (optimized binary JSON) column.
  ColumnDefinition jsonb(String name) {
    final col = ColumnDefinition(name, 'jsonb');
    columns.add(col);
    return col;
  }

  // --- UUID / ULID ---

  /// Adds a column for UUID identifiers.
  ColumnDefinition uuid(String name) {
    final col = ColumnDefinition(name, 'uuid');
    columns.add(col);
    return col;
  }

  // --- Specialty ---
  
  /// Adds an ENUM column with a set of allowed values.
  ColumnDefinition enumCol(String name, List<String> allowed) {
    final col = ColumnDefinition(name, 'enum')..allowedValues = allowed;
    columns.add(col);
    return col;
  }

  /// Adds a column for IP addresses.
  ColumnDefinition ipAddress(String name) {
    final col = ColumnDefinition(name, 'ipAddress');
    columns.add(col);
    return col;
  }
  
  /// Adds a column for MAC addresses.
  ColumnDefinition macAddress(String name) {
    final col = ColumnDefinition(name, 'macAddress');
    columns.add(col);
    return col;
  }

  /// Adds a 'remember_token' column for authentication.
  void rememberToken() {
    string('remember_token', 100).nullable();
  }

  /// Adds the necessary columns for a standard polymorphic relationship.
  void morphs(String name) {
    unsignedBigInteger('${name}_id');
    string('${name}_type');
    index(['${name}_type', '${name}_id']);
  }
  
  /// Adds the necessary columns for a UUID-based polymorphic relationship.
  void uuidMorphs(String name) {
    uuid('${name}_id');
    string('${name}_type');
    index(['${name}_type', '${name}_id']);
  }

  // --- Indexes ---

  /// Creates a composite primary key.
  IndexDefinition primary(dynamic columns) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('primary', list);
    commands.add(index);
    return index;
  }

  /// Creates a unique index on one or more columns.
  IndexDefinition unique(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('unique', list, name: name);
    commands.add(index);
    return index;
  }

  /// Creates a standard index on one or more columns.
  IndexDefinition index(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('index', list, name: name);
    commands.add(index);
    return index;
  }

  /// Creates a FullText index for advanced text searches.
  IndexDefinition fullText(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('fulltext', list, name: name);
    commands.add(index);
    return index;
  }

  /// Creates a spatial index (GIST in Postgres) for geographical data.
  IndexDefinition spatialIndex(dynamic columns, [String? name]) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    final index = IndexDefinition('spatial', list, name: name);
    commands.add(index);
    return index;
  }

  // --- Drop Indexes ---

  /// Removes an existing index by its name.
  void dropIndex(String name) {
    commands.add(DropIndexCommand(name, 'index'));
  }

  /// Removes an existing unique constraint.
  void dropUnique(String name) {
    commands.add(DropIndexCommand(name, 'unique'));
  }

  /// Removes the existing primary key.
  void dropPrimary([String? name]) {
    commands.add(DropIndexCommand(name ?? 'primary', 'primary'));
  }

  // --- Foreign Keys ---

  /// Defines a foreign key constraint on a column.
  ForeignKeyDefinition foreign(String column) {
    final fk = ForeignKeyDefinition(column);
    commands.add(fk);
    return fk;
  }
  
  /// Removes a foreign key constraint. 
  /// Accepts the constraint name (String) or a list of columns to generate the standard name.
  void dropForeign(dynamic index) {
     String name;
     if (index is String) {
       name = index;
     } else if (index is List) {
       final cols = index.cast<String>();
       name = '${table}_${cols.join('_')}_foreign';
     } else {
       throw ArgumentError('dropForeign expects a String or List<String>');
     }
     
     final cmd = DropIndexCommand(name, 'foreign');
     dropForeigns.add(cmd);
  }

  // --- Column Modification ---

  /// Removes one or more columns from the table.
  void dropColumn(dynamic columns) {
    final list = columns is String ? [columns] : (columns as List).cast<String>();
    commands.add(DropColumnCommand(list));
  }

  /// Renames an existing column.
  void renameColumn(String from, String to) {
    commands.add(RenameColumnCommand(from, to));
  }
}
