import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/src/grammars/postgres_grammar.dart';
import 'package:bavard/schema.dart';

// ==========================================
// 1. ADAPTER & INFRASTRUCTURE
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
    // Not using named parameters here because we are transforming ? -> $i
    // But wait, the `postgres` package execute() takes positional args as a List if using legacy query?
    // Modern `execute` takes `parameters: `.
    // If we use $1, $2, we supply a List.
    return {}; // Unused helper if we pass list directly
  }

  List<dynamic> _prepareArgs(List<dynamic> args) {
    return args.map((arg) {
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
      Sql(transformedSql), // usage of $1 implies named? No, parameters: [...] works with $1 if strictly positional?
      // Actually, standard postgres package with 'Sql' object:
      // If the query uses $1, $2... we pass parameters: [val1, val2]
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
  Future<int> execute(String sql, [List<dynamic>? arguments]) async {
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
  Stream<List<Map<String, dynamic>>> watch(
      String sql,
      {
        List<dynamic>? parameters,
      }) {
    // Polling fallback or similar, for now just simple fetch
    return Stream.fromFuture(getAll(sql, parameters));
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
  Future<int> execute(String sql, [List? arguments]) async {
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
// 2. MODELS (With Dispatcher)
// ==========================================

class User extends Model with HasTimestamps {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  HasOne<Profile> profile() => hasOne(Profile.new);
  HasMany<Post> posts() => hasMany(Post.new);
  HasMany<Comment> comments() => hasMany(Comment.new);
  HasManyThrough<Comment, Post> postComments() {
    return hasManyThroughPolymorphic(
      Comment.new,
      Post.new,
      name: 'commentable',
      type: 'posts',
    );
  }

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'profile':
        return profile();
      case 'posts':
        return posts();
      case 'comments':
        return comments();
      case 'postComments':
        return postComments();
      default:
        return super.getRelation(name);
    }
  }
}

class Profile extends Model with HasTimestamps {
  @override
  String get table => 'profiles';
  Profile([super.attributes]);
  @override
  Profile fromMap(Map<String, dynamic> map) => Profile(map);

  BelongsTo<User> user() => belongsTo(User.new);

  @override
  Relation? getRelation(String name) {
    return name == 'user' ? user() : null;
  }
}

class Post extends Model with HasTimestamps {
  @override
  String get table => 'posts';
  Post([super.attributes]);
  @override
  Post fromMap(Map<String, dynamic> map) => Post(map);

  BelongsTo<User> author() => belongsTo(User.new, foreignKey: 'user_id');

  BelongsToMany<Category> categories() {
    return belongsToMany(
      Category.new,
      'category_post',
    ).withPivot(['created_at']);
  }

  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'author':
        return author();
      case 'categories':
        return categories();
      case 'comments':
        return comments();
      default:
        return super.getRelation(name);
    }
  }
}

class Category extends Model with HasTimestamps {
  @override
  String get table => 'categories';
  Category([super.attributes]);
  @override
  Category fromMap(Map<String, dynamic> map) => Category(map);

  BelongsToMany<Post> posts() => belongsToMany(Post.new, 'category_post');

  @override
  Relation? getRelation(String name) {
    return name == 'posts' ? posts() : null;
  }
}

class Video extends Model with HasTimestamps {
  @override
  String get table => 'videos';
  Video([super.attributes]);
  @override
  Video fromMap(Map<String, dynamic> map) => Video(map);

  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');

  @override
  Relation? getRelation(String name) {
    return name == 'comments' ? comments() : null;
  }
}

class Comment extends Model with HasTimestamps {
  @override
  String get table => 'comments';
  Comment([super.attributes]);
  @override
  Comment fromMap(Map<String, dynamic> map) => Comment(map);

  MorphTo<Model> commentable() =>
      morphToTyped('commentable', {'posts': Post.new, 'videos': Video.new});
  BelongsTo<User> author() => belongsTo(User.new);

  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'commentable':
        return commentable();
      case 'author':
        return author();
      default:
        return super.getRelation(name);
    }
  }
}

class Task extends Model with HasTimestamps, HasSoftDeletes {
  @override
  String get table => 'tasks';

  Task([super.attributes]);

  @override
  Task fromMap(Map<String, dynamic> map) => Task(map);

  @override
  Map<String, String> get casts => {'metadata': 'json'};
}

class Product extends Model with HasTimestamps {
  @override
  String get table => 'products';
  Product([super.attributes]);
  @override
  Product fromMap(Map<String, dynamic> map) => Product(map);

  @override
  Future<bool> onSaving() async {
    if (attributes.containsKey('name')) {
      attributes['name'] = attributes['name'].toString().toUpperCase();
    }

    return true;
  }
}

// ==========================================
// 3. MAIN TEST SUITE
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
  await db.execute(Sql.named('CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT, email TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE profiles (id SERIAL PRIMARY KEY, user_id INTEGER, bio TEXT, website TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE posts (id SERIAL PRIMARY KEY, user_id INTEGER, title TEXT, content TEXT, views INTEGER DEFAULT 0, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE comments (id SERIAL PRIMARY KEY, user_id INTEGER, commentable_type TEXT, commentable_id INTEGER, body TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE categories (id SERIAL PRIMARY KEY, name TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE videos (id SERIAL PRIMARY KEY, title TEXT, url TEXT, created_at TEXT, updated_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE category_post (post_id INTEGER, category_id INTEGER, created_at TEXT, PRIMARY KEY(post_id, category_id))'));
  await db.execute(Sql.named('CREATE TABLE tasks (id SERIAL PRIMARY KEY, title TEXT, metadata TEXT,created_at TEXT, updated_at TEXT, deleted_at TEXT)'));
  await db.execute(Sql.named('CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT, price DOUBLE PRECISION, created_at TEXT, updated_at TEXT)'));
  print('✅ Database & Schema Initialized.');

  // TEST 1: Basic CRUD & Validation
  await runTest('CRUD Operations', () async {
    // Create
    final user = User({
      'name': 'David',
      'email': 'david@test.com',
      'created_at': isoNow(),
    });
    await user.save();
    if (user.id == null) throw 'User ID is null after save';

    // Read
    final fetched = await User().query().find(user.id);
    if (fetched == null || fetched.attributes['name'] != 'David')
      throw 'Fetch failed or data mismatch';

    // Update
    fetched.attributes['name'] = 'David Updated';
    await fetched.save();

    // Read again
    final updated = await User().query().find(user.id);
    if (updated!.attributes['name'] != 'David Updated') throw 'Update failed';

    // Delete
    await updated.delete();

    // Check deletion
    final deleted = await User().query().find(user.id);
    if (deleted != null) throw 'Delete failed (User still exists)';

    // Restore for next tests
    await User({
      'name': 'David',
      'email': 'david@test.com',
      'created_at': isoNow(),
    }).save();
  });

  // TEST 2: Query Builder (Where, Order, Limit)
  await runTest('Query Builder Capabilities', () async {
    // Setup dummy data
    for (var i = 1; i <= 5; i++) {
      await Post({
        'title': 'Post $i',
        'views': i * 10,
        'created_at': isoNow(),
      }).save();
    }

    // Where
    final p3 = await Post().query().where('views', 30).first();
    if (p3?.attributes['title'] != 'Post 3') throw 'Where clause failed';

    // Greater Than
    final popular = await Post().query().where('views', 30, '>').get();
    if (popular.length != 2)
      throw 'Where operator (>) failed. Expected 2, got ${popular.length}';

    // Order By & Limit
    final top = await Post()
        .query()
        .orderBy('views', direction: 'desc')
        .limit(1)
        .get();
    if (top.first.attributes['title'] != 'Post 5')
      throw 'OrderBy or Limit failed';
  });

  // TEST 3: Edge Case - Orphan Relations
  await runTest('Orphan Relation Handling (Null Safety)', () async {
    // Post without user
    final orphanPost = Post({
      'title': 'Orphan',
      'user_id': 9999,
      'created_at': isoNow(),
    });
    await orphanPost.save();

    final loaded = await Post()
        .query()
        .withRelations(['author'])
        .find(orphanPost.id);
    final author = loaded!.getRelated<User>('author');

    if (author != null)
      throw 'Orphan post returned an author object! Should be null.';
  });

  // TEST 4: Nested Eager Loading (Users -> Posts -> Comments)
  await runTest('Nested Relations (Deep Loading)', () async {
    final u = await User().query().first();
    final p = await Post().query().first();

    // Assign post to user
    p!.attributes['user_id'] = u!.id;
    await p.save();

    // Add comment to post
    await Comment({
      'body': 'Nested test',
      'commentable_type': 'posts',
      'commentable_id': p.id,
      'user_id': u.id,
    }).save();

    // Load User with Posts
    final userWithPosts = await User()
        .query()
        .withRelations(['posts'])
        .find(u.id);
    final posts = userWithPosts!.getRelationList<Post>('posts');

    if (posts.isEmpty) throw 'Failed to load posts';

    // Now load comments for that post
    final postWithComments = await Post()
        .query()
        .withRelations(['comments'])
        .find(posts.first.id);
    final comments = postWithComments!.getRelationList<Comment>('comments');

    if (comments.isEmpty) throw 'Failed to load nested comments';
    if (comments.first.attributes['body'] != 'Nested test')
      throw 'Comment data mismatch';
  });

  // TEST 5: Transactions & Rollback
  await runTest('Transactions (Rollback)', () async {
    final startCount = await User().query().count();

    try {
      await DatabaseManager().transaction((txn) async {
        await User({'name': 'Rollback User', 'email': 'fail@test.com'}).save();
        throw Exception('Simulated Crash');
      });
    } catch (e) {
      // Expected
    }

    final endCount = await User().query().count();
    if (startCount != endCount)
      throw 'Rollback failed! Record persisted despite error.';
  });

  // TEST 6: BelongsToMany with Metadata
  await runTest('BelongsToMany (Pivot Data)', () async {
    final p = await Post().query().first();
    final c = Category({'name': 'Edge', 'created_at': isoNow()});
    await c.save();

    await p!.categories().attach(c, {'created_at': '2025-01-01'});

    final result = await Post()
        .query()
        .withRelations(['categories'])
        .find(p.id);
    final cats = result!.getRelationList<Category>('categories');

    if (cats.isEmpty) throw 'No categories found';
    final pivot = cats.first.pivot;

    if (pivot == null) throw 'Pivot object is null';
    if (pivot.attributes['created_at'] != '2025-01-01')
      throw 'Pivot metadata mismatch';
  });

  // TEST 7: Polymorphism (MorphTo)
  await runTest('Polymorphic Relations', () async {
    final v = Video({
      'title': 'Poly Vid',
      'url': 'http',
      'created_at': isoNow(),
    });
    await v.save();

    final c = Comment({
      'body': 'Video Comment',
      'commentable_type': 'videos', // Matches MorphToTyped map key
      'commentable_id': v.id,
    });
    await c.save();

    final loadedComment = await Comment()
        .query()
        .withRelations(['commentable'])
        .find(c.id);
    final parent = loadedComment!.getRelated<Model>('commentable');

    if (parent == null) throw 'Polymorphic parent not loaded';
    if (parent is! Video)
      throw 'Polymorphic parent is wrong type. Expected Video, got ${parent.runtimeType}';
    if (parent.attributes['title'] != 'Poly Vid')
      throw 'Polymorphic parent data mismatch';
  });

  // TEST 8: Soft Deletes
  await runTest('Soft Deletes (Logical Deletion)', () async {
    final t = Task({
      'title': 'Secret Task',
      'created_at': isoNow(),
      'updated_at': isoNow(),
    });
    await t.save();
    final id = t.id;

    // 1. Logical Delete
    await t.delete();

    // 2. Verification: Standard query should NOT find it
    final search = await Task().query().find(id);
    if (search != null)
      throw 'Soft Deleted record was found by standard query!';

    // 3. Verification: Record MUST exist physically in DB with deleted_at set
    final softDeletedTask = await Task().withTrashed().find(id);
    if (softDeletedTask == null) throw 'Record was physically deleted from DB!';
    if (softDeletedTask.attributes['deleted_at'] == null) throw 'deleted_at column is null!';
  });

  // TEST 9: JSON Casting
  await runTest('Attribute Casting (JSON)', () async {
    final config = {'theme': 'dark', 'notifications': true};

    final t = Task({
      'title': 'Config Task',
      'metadata': config, // Passing a Map, ORM should serialize it
      'created_at': isoNow(),
      'updated_at': isoNow(),
    });

    await t.save();

    final fetched = await Task().query().find(t.id);

    // Verify that reading from DB returns a Map, not a String
    final meta = fetched!.attributes['metadata'];

    if (meta is! Map)
      throw 'JSON Cast failed: Expected Map, got ${meta.runtimeType}';
    if (meta['theme'] != 'dark') throw 'JSON content mismatch';
  });

  // TEST 10: Advanced Query (WhereIn, WhereNull)
  await runTest('Advanced Clauses (WhereIn, WhereNull)', () async {
    await Post().query().delete();

    final p1 = Post({
      'title': 'A',
      'views': 10,
      'created_at': isoNow(),
      'updated_at': isoNow(),
    });
    await p1.save();

    final p2 = Post({
      'title': 'B',
      'views': 20,
      'created_at': isoNow(),
      'updated_at': isoNow(),
    });
    await p2.save();

    final p3 = Post({
      'title': 'C',
      'views': 30,
      'created_at': isoNow(),
      'updated_at': isoNow(),
    });
    await p3.save();

    // WHERE IN
    final inResults = await Post().query().whereIn('id', [p1.id, p3.id]).get();

    if (inResults.length != 2) {
      throw 'WhereIn failed. Expected 2, got ${inResults.length}';
    }

    // WHERE NULL (Create orphan post, user_id will be null)
    final orphan = Post({
      'title': 'NullCheck',
      'created_at': isoNow(),
      'updated_at': isoNow(),
    });
    await orphan.save();

    final nullResults = await Post().query().whereNull('user_id').get();
    if (nullResults.isEmpty) throw 'WhereNull failed';
  });

  // TEST 11: Performance / Stress Test
  await runTest('Performance & Stress Test (Bulk Operations)', () async {
    final int count = 100;
    final stopwatch = Stopwatch()..start();

    // Use transaction for bulk insert to be realistic
    await DatabaseManager().transaction((txn) async {
      for (var i = 0; i < count; i++) {
        await User({
          'name': 'Stress User $i',
          'email': 'stress$i@test.com',
          'created_at': isoNow(),
        }).save();
      }
    });

    stopwatch.stop();
    //print('    -> Inserted $count records in ${stopwatch.elapsedMilliseconds}ms');

    final countWatch = Stopwatch()..start();
    final totalUsers = await User().query().count();
    countWatch.stop();

    if (totalUsers! < count)
      throw 'Bulk insert failed. Total users: $totalUsers';

    final queryWatch = Stopwatch()..start();
    // Fetch a large chunk
    final manyUsers = await User().query().limit(count).get();
    queryWatch.stop();
    //print('    -> Fetched ${manyUsers.length} records in ${queryWatch.elapsedMilliseconds}ms');

    if (manyUsers.length != count)
      throw 'Bulk fetch returned wrong number of records';
  });

  // TEST 12: Type Safety Verification
  await runTest('Type Safety Verification', () async {
    // SQLite uses dynamic typing, but the driver maps them to Dart types.
    // We want to ensure our Model attributes preserve these types (e.g. Int stays Int, not String).

    final p = Post({
      'title': 'Typed Post',
      'views': 99999, // Integer
      'created_at': isoNow(),
    });
    await p.save();

    final fetched = await Post().query().find(p.id);
    if (fetched == null) throw 'Could not find typed post';

    final attrs = fetched.attributes;

    // 1. Check String
    if (attrs['title'] is! String) {
      throw 'Type Error: "title" should be String, got ${attrs['title'].runtimeType} (${attrs['title']})';
    }

    // 2. Check Integer (Critical for SQLite)
    if (attrs['views'] is! int) {
      throw 'Type Error: "views" should be int, got ${attrs['views'].runtimeType} (${attrs['views']})';
    }

    // 3. Check ID (AutoIncrement Integer)
    if (attrs['id'] is! int) {
      throw 'Type Error: "id" should be int, got ${attrs['id'].runtimeType} (${attrs['id']})';
    }

    // Active for debug.
    // print('    -> Types verified: String=${attrs['title'].runtimeType}, Int=${attrs['views'].runtimeType}');
  });

  // TEST 13: HasManyThrough (User -> Post -> Comments)
  await runTest('HasManyThrough (User -> Post -> Comments)', () async {
    final user = User({
      'name': 'ThroughUser',
      'email': 'through@test.com',
      'created_at': isoNow(),
    });
    await user.save();

    final post = Post({
      'user_id': user.id,
      'title': 'ThroughPost',
      'created_at': isoNow(),
    });
    await post.save();

    await Comment({
      'body': 'ThroughComment',
      'commentable_type': 'posts',
      'commentable_id': post.id,
      'user_id': user.id,
    }).save();

    final fetchedUser = await User()
        .query()
        .withRelations(['postComments'])
        .find(user.id);
    if (fetchedUser == null) throw 'User not found';

    final comments = fetchedUser.getRelationList<Comment>('postComments');
    if (comments.isEmpty) throw 'No comments found via HasManyThrough';
    if (comments.first.attributes['body'] != 'ThroughComment')
      throw 'Comment content mismatch';
  });

  // TEST 14: Lifecycle Hooks (onCreating)
  await runTest('Lifecycle Hooks (onCreating)', () async {
    final product = Product({
      'name': 'laptop',
      'price': 999.99,
      'created_at': isoNow(),
    });
    await product.save();

    final fetched = await Product().query().find(product.id);
    if (fetched == null) throw 'Product not found';

    // Verify hook modified the data (laptop -> LAPTOP)
    if (fetched.attributes['name'] != 'LAPTOP') {
      throw 'Hook failed: Name should be LAPTOP, got ${fetched.attributes['name']}';
    }
  });

  // TEST 15: Aggregates (Sum, Avg, Max)
  await runTest('Aggregates (Sum, Avg, Max)', () async {
    await Post().query().delete();
    // Insert dummy posts with views: 10, 20, 30
    await Post({'title': 'P1', 'views': 10, 'created_at': isoNow()}).save();
    await Post({'title': 'P2', 'views': 20, 'created_at': isoNow()}).save();
    await Post({'title': 'P3', 'views': 30, 'created_at': isoNow()}).save();

    final sum = await Post().query().sum('views');
    if (sum != 60) throw 'Sum failed: Expected 60, got $sum';

    final avg = await Post().query().avg('views');
    if (avg is! num || ((avg as num).toDouble() - 20.0).abs() > 0.001) {
      throw 'Avg failed: Expected 20.0, got $avg (${avg.runtimeType})';
    }

    final max = await Post().query().max('views');
    if (max != 30) throw 'Max failed: Expected 30, got $max';

    final min = await Post().query().min('views');
    if (min != 10) throw 'Min failed: Expected 10, got $min';
  });

  print('\n🎉 --- ALL SYSTEMS GO: CORE IS STABLE --- 🎉');

  // Only for debug.
  //printAllDbTables(db);
}

String isoNow() => DateTime.now().toIso8601String();

Future<void> runTest(String name, Future<void> Function() testBody) async {
  stdout.write('Testing: $name... ');
  try {
    await testBody();
    print('✅ PASS');
  } catch (e, s) {
    print('❌ FAIL');
    print('   Error: $e');
    print('   Stack: $s');
  }
}

void printAllDbTables(Connection db) async {
  print('\n════════════════════════════════════════════════════════════');
  print('🔍 FULL DATABASE DUMP');
  print('════════════════════════════════════════════════════════════');

  final tablesResult = await db.execute(
    Sql.named("SELECT table_name as name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"),
  );

  if (tablesResult.isEmpty) {
    print('⚠️  No tables found in database.');
    return;
  }

  for (final row in tablesResult) {
    final tableName = row.toColumnMap()['name'];
    try {
      final rows = await db.execute(Sql.named('SELECT * FROM "$tableName"'));
      _printTable(rows, tableName);
    } catch (e) {
      print('❌ Error reading table $tableName: $e');
    }
  }
  print('════════════════════════════════════════════════════════════\n');
}

void _printTable(Result rows, String tableName) {
  if (rows.isEmpty) {
    print('\n--- Table: $tableName (0 rows) ---');
    return;
  }

  final List<Map<String, dynamic>> data = [];
  for (var row in rows) {
    data.add(row.toColumnMap());
  }

  final columns = data.first.keys.toList();
  final widths = {for (var c in columns) c: c.length};

  for (var row in data) {
    for (var col in columns) {
      final valString = row[col].toString();
      if (valString.length > widths[col]!) {
        widths[col] = valString.length;
      }
    }
  }

  print('\n--- Table: $tableName (${data.length} rows) ---');

  final header = columns.map((c) => c.padRight(widths[c]!)).join(' | ');
  print(header);
  print(columns.map((c) => '-' * widths[c]!).join('-+-'));

  for (var row in data) {
    print(
      columns
          .map((col) {
        final val = row[col].toString();
        return val.padRight(widths[col]!);
      })
          .join(' | '),
    );
  }
}
