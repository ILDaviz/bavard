import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:bavard/bavard.dart';
import 'package:bavard_migration/bavard_migration.dart';
import 'migrations/2026_02_11_000001_create_todos_table.dart';
import 'migrations/2026_02_11_000002_create_users_table.dart';
import 'migrations/2026_02_11_000003_create_posts_table.dart';

Future<void> setupDatabase() async {
  String path = join(Directory.current.path, "bavard_example_v2.db");
  
  print('--- DATABASE INFO ---');
  print('Current Directory: ${Directory.current.path}');
  print('Target DB Path: $path');
  print('---------------------');

  final db = await sql.openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {},
  );

  final adapter = SqfliteAdapter(db);
  DatabaseManager().setDatabase(adapter);

  final migrationRepo = MigrationRepository(adapter);
  final migrator = Migrator(adapter, migrationRepo);

  final migrations = [
    MigrationRegistryEntry(CreateTodosTable(), '2026_02_11_000001_create_todos_table'),
    MigrationRegistryEntry(CreateUsersTable(), '2026_02_11_000002_create_users_table'),
    MigrationRegistryEntry(CreatePostsTable(), '2026_02_11_000003_create_posts_table'),
  ];

  await migrator.runUp(migrations);
}

class SqfliteAdapter implements DatabaseAdapter {
  final sql.DatabaseExecutor _db;

  SqfliteAdapter(this._db);

  @override
  Grammar get grammar => SQLiteGrammar();

  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List<dynamic>? arguments]) async {
    return await _db.rawQuery(sql, arguments);
  }

  @override
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]) async {
    final results = await getAll(sql, arguments);
    if (results.isEmpty) return {};
    return results.first;
  }

  @override
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    final lowerSql = sql.trim().toLowerCase();
    if (lowerSql.startsWith('insert')) {
      return await _db.rawInsert(sql, arguments);
    } else if (lowerSql.startsWith('update')) {
      return await _db.rawUpdate(sql, arguments);
    } else if (lowerSql.startsWith('delete')) {
      return await _db.rawDelete(sql, arguments);
    } else {
      await _db.execute(sql, arguments);
      return 0;
    }
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    return await _db.insert(table, values);
  }

  @override
  bool get supportsTransactions => _db is sql.Database;

  @override
  Future<T> transaction<T>(Future<T> Function(TransactionContext txn) callback) async {
    if (_db is sql.Database) {
      return (_db as sql.Database).transaction((txn) async {
        final context = _SqfliteTransactionContext(txn);
        return await callback(context);
      });
    } else {
      throw UnimplementedError('Nested transactions or transactions inside a transaction context are not fully supported.');
    }
  }
}

class _SqfliteTransactionContext implements TransactionContext {
  final sql.Transaction _txn;
  _SqfliteTransactionContext(this._txn);

  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List<dynamic>? arguments]) => _txn.rawQuery(sql, arguments);

  @override
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? arguments]) async {
    final res = await _txn.rawQuery(sql, arguments);
    return res.isNotEmpty ? res.first : {};
  }

  @override
  Future<int> execute(String table, String sql, [List<dynamic>? arguments]) async {
    final lowerSql = sql.trim().toLowerCase();
    if (lowerSql.startsWith('insert')) return await _txn.rawInsert(sql, arguments);
    if (lowerSql.startsWith('update')) return await _txn.rawUpdate(sql, arguments);
    if (lowerSql.startsWith('delete')) return await _txn.rawDelete(sql, arguments);
    await _txn.execute(sql, arguments);
    return 0;
  }

  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) => _txn.insert(table, values);
}
