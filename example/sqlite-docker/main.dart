import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/src/grammars/sqlite_grammar.dart';
import 'package:shared_test_suite/tests.dart';

// ==========================================
// ADAPTER & INFRASTRUCTURE
// ==========================================

class SqliteAdapter implements DatabaseAdapter {
  final Database _db;

  SqliteAdapter(this._db);

  @override
  Grammar get grammar => SQLiteGrammar();

  List<dynamic> _sanitize(List<dynamic> args) {
    return args.map((arg) {
      if (arg is DateTime) return arg.toIso8601String();
      if (arg is bool) return arg ? 1 : 0;
      if (arg is List<int>) return arg; // Blob support
      if (arg is Map || arg is List) return jsonEncode(arg);

      return arg;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final result = _db.select(sql, _sanitize(arguments ?? []));
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> get(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final result = await getAll(sql, arguments);
    if (result.isEmpty) return {};
    return result.first;
  }

  @override
  Future<int> execute(
    String table,
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    _db.execute(sql, _sanitize(arguments ?? []));
    return _db.getUpdatedRows();
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders)';

    _db.execute(sql, _sanitize(values.values.toList()));
    return _db.lastInsertRowId;
  }

  @override
  bool get supportsTransactions => true;

  @override
  Future<T> transaction<T>(
    Future<T> Function(TransactionContext txn) callback,
  ) async {
    _db.execute('BEGIN TRANSACTION');
    try {
      final txnContext = _SqliteTransactionContext(_db, _sanitize);
      final result = await callback(txnContext);
      _db.execute('COMMIT');
      return result;
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}

class _SqliteTransactionContext implements TransactionContext {
  final Database _db;
  final List<dynamic> Function(List<dynamic>) _sanitize;

  _SqliteTransactionContext(this._db, this._sanitize);

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List? arguments,
  ]) async {
    final result = _db.select(sql, _sanitize(arguments ?? []));
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List? arguments]) async {
    final list = await getAll(sql, arguments);
    return list.isNotEmpty ? list.first : {};
  }

  @override
  Future<int> execute(String table, String sql, [List? arguments]) async {
    _db.execute(sql, _sanitize(arguments ?? []));
    return _db.getUpdatedRows();
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders)';
    _db.execute(sql, _sanitize(values.values.toList()));
    return _db.lastInsertRowId;
  }
}

// ==========================================
// MAIN TEST SUITE
// ==========================================

void main() async {
  print('\n🧪 --- STARTING BAVARD CORE & EDGE CASE TESTS (SQLite) --- 🧪\n');

  final dataDir = Directory('data');
  if (!dataDir.existsSync()) dataDir.createSync();

  final dbPath = 'data/test_v2.db';
  if (File(dbPath).existsSync()) File(dbPath).deleteSync();

  final db = sqlite3.open(dbPath);
  DatabaseManager().setDatabase(SqliteAdapter(db));

  db.execute('''
    CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT UNIQUE, address TEXT, avatar BLOB, created_at TEXT, updated_at TEXT);
    CREATE TABLE profiles (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, bio TEXT, website TEXT, created_at TEXT, updated_at TEXT);
    CREATE TABLE posts (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, title TEXT, content TEXT, views INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT);
    CREATE TABLE comments (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, commentable_type TEXT, commentable_id INTEGER, body TEXT, created_at TEXT, updated_at TEXT);
    CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, created_at TEXT, updated_at TEXT);
    CREATE TABLE videos (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, url TEXT, created_at TEXT, updated_at TEXT);
    CREATE TABLE category_post (post_id INTEGER, category_id INTEGER, created_at TEXT, PRIMARY KEY(post_id, category_id));
    CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, metadata TEXT,created_at TEXT, updated_at TEXT, deleted_at TEXT);
    CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, created_at TEXT, updated_at TEXT);
  ''');
  print('✅ Database & Schema Initialized.');

  await runIntegrationTests();

  print('🛑 Closing database connection...');
  db.dispose();
  print('👋 Test process finished.');
}
