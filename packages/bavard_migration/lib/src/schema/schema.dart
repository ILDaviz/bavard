import 'package:bavard/bavard.dart';

/// The Schema class provides a fluent way to manipulate your database tables.
///
/// It acts as a bridge between your migration definitions and the underlying
/// database, handling the generation and execution of DDL (Data Definition Language)
/// statements based on the database driver currently in use.
class Schema {
  final DatabaseAdapter _adapter;

  Schema(this._adapter);

  /// Creates a brand new table in the database.
  ///
  /// Use the [callback] to define your columns, indexes, and constraints on the
  /// [Blueprint] instance. This method will automatically compile and run the 
  /// necessary SQL to set up the table and any associated indexes.
  Future<void> create(String table, void Function(Blueprint) callback) async {
    final blueprint = Blueprint(table);
    callback(blueprint);
    
    final createSql = _adapter.grammar.compileCreateTable(blueprint);
    await _adapter.execute(table, createSql);

    final indexStatements = _adapter.grammar.compileIndexes(blueprint);
    for (final sql in indexStatements) {
      await _adapter.execute(table, sql);
    }
  }

  /// Modifies an existing table's structure.
  ///
  /// This is your go-to method for altering tables. Inside the [callback], you can 
  /// add new columns, rename existing ones, drop indexes, or change column types. 
  /// It intelligently sequences the operations (dropping constraints before columns, 
  /// etc.) to ensure the changes are applied smoothly.
  Future<void> table(String table, void Function(Blueprint) callback) async {
    final blueprint = Blueprint(table);
    callback(blueprint);

    final grammar = _adapter.grammar;
    final commands = <String>[];

    // Drop Constraints (Foreign Keys & Indexes)
    if (blueprint.dropForeigns.isNotEmpty) {
      commands.addAll(grammar.compileDropForeign(blueprint));
    }
    
    if (blueprint.commands.where((c) => c.type.startsWith('dropIndex') || c.type.startsWith('dropUnique') || c.type.startsWith('dropPrimary')).isNotEmpty) {
       commands.addAll(grammar.compileDropIndex(blueprint));
    }

    // Drop Columns
    if (blueprint.commands.where((c) => c.type == 'dropColumn').isNotEmpty) {
      commands.addAll(grammar.compileDropColumn(blueprint));
    }

    // Add Columns
    if (blueprint.columns.where((c) => !c.isChange).isNotEmpty) {
      commands.addAll(grammar.compileAdd(blueprint));
    }

    // Change Columns
    if (blueprint.columns.where((c) => c.isChange).isNotEmpty) {
      commands.addAll(grammar.compileChange(blueprint));
    }

    // Rename Columns
    if (blueprint.commands.where((c) => c.type == 'renameColumn').isNotEmpty) {
      commands.addAll(grammar.compileRenameColumn(blueprint));
    }

    // Add Indexes
    if (blueprint.commands.where((c) => c.type == 'index' || c.type == 'unique' || c.type == 'fulltext' || c.type == 'spatial').isNotEmpty) {
      commands.addAll(grammar.compileIndexes(blueprint));
    }

    for (final sql in commands) {
      await _adapter.execute(table, sql);
    }
  }

  /// Permanently removes a table from the database.
  ///
  /// Careful: this will delete the table and all its data immediately.
  Future<void> drop(String table) async {
    final sql = _adapter.grammar.compileDropTable(table);
    await _adapter.execute(table, sql);
  }

  /// Removes a table from the database only if it actually exists.
  ///
  /// This is a safer version of [drop] that prevents errors if the table 
  /// was already removed or never created in the first place.
  Future<void> dropIfExists(String table) async {
    await _adapter.execute(table, 'DROP TABLE IF EXISTS $table');
  }
}

