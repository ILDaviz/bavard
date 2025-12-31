import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:postgres/postgres.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/src/grammars/postgres_grammar.dart';
import 'package:shared_test_suite/tests.dart';

// ==========================================
// ADAPTER & INFRASTRUCTURE
// ==========================================

class PostgresAdapter implements DatabaseAdapter {
  final Connection _conn;

  PostgresAdapter(this._conn);

  @override
  Grammar get grammar => PostgresGrammar();

  /// Converts '?' placeholders to '$1', '$2', etc.
  String _transformSql(String sql) {
    int index = 1;
    return sql.replaceAllMapped('?', (_) => '\$${index++}');
  }

  /// Sanitize/Prepare arguments for Postgres driver
  /// The postgres package v3 handles most types, but we ensure consistency.
  Map<String, dynamic> _prepareParams(List<dynamic>? args) {
    if (args == null || args.isEmpty) return {};
    return {};
  }

  List<dynamic> _prepareArgs(List<dynamic> args) {
    return args.map((arg) {
      if (arg is List<int>) {
        return TypedValue(Type.byteArray, Uint8List.fromList(arg));
      }
      if (arg is Map || arg is List) return jsonEncode(arg);
      // Postgres driver handles DateTime, bool, int, double, String.
      return arg;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
      String sql,
      [
        List<dynamic>? arguments,
      ]) async {
    final transformedSql = _transformSql(sql);
    final result = await _conn.execute(
      Sql(transformedSql),
      parameters: _prepareArgs(arguments ?? []),
    );

    // Map ResultRow to Map<String, dynamic>
    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Future<Map<String, dynamic>> get(
      String sql,
      [
        List<dynamic>? arguments,
      ]) async {
    final result = await getAll(sql, arguments);
    if (result.isEmpty) return {};
    return result.first;
  }

  @override
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    final transformedSql = _transformSql(sql);
    final result = await _conn.execute(
      Sql(transformedSql),
      parameters: _prepareArgs(arguments ?? []),
    );
    return result.affectedRows;
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');

    // Postgres specific: RETURNING * to be safe against missing 'id' column
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders) RETURNING *';

    final transformedSql = _transformSql(sql);
    final result = await _conn.execute(
      Sql(transformedSql),
      parameters: _prepareArgs(values.values.toList()),
    );

    // Return the id if it exists
    if (result.isNotEmpty) {
      return result.first.toColumnMap()['id'];
    }
    return null;
  }

  @override
  bool get supportsTransactions => true;

  @override
  Future<T> transaction<T>(
      Future<T> Function(TransactionContext txn) callback,
      ) async {
    return await _conn.runTx((session) async {
      final txnAdapter = _PostgresTransactionContext(session, _transformSql, _prepareArgs);
      return await callback(txnAdapter);
    });
  }
}

class _PostgresTransactionContext implements TransactionContext {
  final TxSession _session;
  final String Function(String) _transformer;
  final List<dynamic> Function(List<dynamic>) _preparer;

  _PostgresTransactionContext(this._session, this._transformer, this._preparer);

  @override
  Future<List<Map<String, dynamic>>> getAll(
      String sql,
      [
        List? arguments,
      ]) async {
    final result = await _session.execute(
      Sql(_transformer(sql)),
      parameters: _preparer(arguments ?? []),
    );
    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List? arguments]) async {
    final list = await getAll(sql, arguments);
    return list.isNotEmpty ? list.first : {};
  }

  @override
  Future<int> execute(String table, String sql, [List? arguments]) async {
    final result = await _session.execute(
      Sql(_transformer(sql)),
      parameters: _preparer(arguments ?? []),
    );
    return result.affectedRows;
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.map((k) => '"$k"').join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO "$table" ($columns) VALUES ($placeholders) RETURNING *';

    final result = await _session.execute(
      Sql(_transformer(sql)),
      parameters: _preparer(values.values.toList()),
    );
    if (result.isNotEmpty) {
      return result.first.toColumnMap()['id'];
    }
    return null;
  }
}

// ==========================================
// MAIN TEST SUITE
// ==========================================

void main() async {
  print('\n🧪 --- STARTING BAVARD CORE & EDGE CASE TESTS (PostgreSQL) --- 🧪\n');

  // --- SETUP ---
  // Get ENV vars
  final host = Platform.environment['DB_HOST'] ?? 'localhost';
  final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
  final dbName = Platform.environment['DB_NAME'] ?? 'bavard_test';
  final user = Platform.environment['DB_USER'] ?? 'bavard';
  final pass = Platform.environment['DB_PASS'] ?? 'password';

  print('Connecting to Postgres at $host:$port/$dbName...');

  final endpoint = Endpoint(
    host: host,
    port: port,
    database: dbName,
    username: user,
    password: pass,
  );

  final db = await Connection.open(endpoint, settings: ConnectionSettings(sslMode: SslMode.disable));

  DatabaseManager().setDatabase(PostgresAdapter(db));

  // Clean Schema
  // Postgres requires CASCADE to drop tables with dependencies
  try {
    await db.execute(Sql.named('DROP TABLE IF EXISTS users CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS profiles CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS posts CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS comments CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS categories CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS videos CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS category_post CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS tasks CASCADE'));
    await db.execute(Sql.named('DROP TABLE IF EXISTS products CASCADE'));
  } catch (e) {
    print('Warning cleaning tables: $e');
  }

  // Create Schema (Adapted for Postgres)
  // SERIAL PRIMARY KEY replaces INTEGER PRIMARY KEY AUTOINCREMENT
  await db.execute(Sql.named('CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT, email TEXT UNIQUE, address TEXT, avatar BYTEA, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE profiles (id SERIAL PRIMARY KEY, user_id INTEGER, bio TEXT, website TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE posts (id SERIAL PRIMARY KEY, user_id INTEGER, title TEXT, content TEXT, views INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE comments (id SERIAL PRIMARY KEY, user_id INTEGER, commentable_type TEXT, commentable_id INTEGER, body TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE categories (id SERIAL PRIMARY KEY, name TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE videos (id SERIAL PRIMARY KEY, title TEXT, url TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE category_post (post_id INTEGER, category_id INTEGER, created_at TEXT, PRIMARY KEY(post_id, category_id))'));
  await db.execute(Sql.named('CREATE TABLE tasks (id SERIAL PRIMARY KEY, title TEXT, metadata TEXT,created_at TEXT, updated_at TEXT, deleted_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT, price DOUBLE PRECISION, created_at TEXT, updated_at TEXT)'));
  print('✅ Database & Schema Initialized.');

  await runIntegrationTests();

  print('🛑 Closing database connection...');
  await db.close();
  print('👋 Test process finished.');
}