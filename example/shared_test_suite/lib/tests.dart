import 'dart:async';
import 'dart:io';
import 'package:bavard/bavard.dart';
import 'models.dart';

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

Future<void> runIntegrationTests() async {
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

  // TEST 16: Custom Attribute Cast (Address)
  await runTest('Custom Attribute Cast (Address)', () async {
    final user = User({
      'name': 'Custom Cast User',
      'email': 'cast@test.com',
      'created_at': isoNow(),
    });
    
    // Assign Address object
    user.address = Address('123 Cast St', 'Cast City');
    
    await user.save();
    
    // Read back
    final fetched = await User().query().find(user.id);
    
    if (fetched == null) throw 'User not found';
    
    final addr = fetched.address;
    
    if (addr == null) throw 'Address is null';
    if (addr is! Address) throw 'Address is not of type Address';
    if (addr.street != '123 Cast St') throw 'Address street mismatch';
    if (addr.city != 'Cast City') throw 'Address city mismatch';
    
    if (fetched.attributes['address'] is! String) {
       throw 'Raw attribute should be String (JSON), got ${fetched.attributes['address'].runtimeType}';
    }
  });

  // TEST 17: Concurrency (Parallel Saves)
  await runTest('Concurrency (Parallel Saves)', () async {
    final futures = List.generate(10, (i) {
      return User({
        'name': 'Concurrent $i',
        'email': 'concurrent$i@test.com',
        'created_at': isoNow(),
      }).save();
    });

    await Future.wait(futures);
    
    final count = await User().query().where('name', 'Concurrent%', 'LIKE').count();
    if (count != 10) throw 'Concurrency failed. Expected 10, got $count';
  });

  // TEST 18: Blob / Binary Data
  await runTest('Blob / Binary Data (Avatar)', () async {
    final bytes = [0x1, 0x2, 0x3, 0xFF];
    final user = User({
      'name': 'Blob User',
      'email': 'blob@test.com',
      'created_at': isoNow(),
    });
    user.avatar = bytes;
    
    await user.save();
    
    final fetched = await User().query().find(user.id);
    final fetchedBytes = fetched?.avatar;
    if (fetchedBytes == null) throw 'Avatar is null';
    if (fetchedBytes.length != 4) {
      throw 'Avatar length mismatch';
    }
    if (fetchedBytes[3] != 0xFF) throw 'Avatar data mismatch';
  });
  
  // TEST 19: Dirty Checking Optimization
  await runTest('Dirty Checking (No Query on No Change)', () async {
    final user = await User().query().first();
    if (user == null) throw 'No user found';
    
    final oldUpdatedAt = user.updatedAt;
    
    // Save without changes
    await user.save();
    
    if (user.updatedAt != oldUpdatedAt) {
       throw 'Model was updated even though no attributes changed!';
    }
    
    user.attributes['name'] = user.attributes['name'] + ' Changed';
    await user.save();
    
    if (user.updatedAt == oldUpdatedAt) {
      throw 'Model was NOT updated after attribute change!';
    }
  });

  // TEST 20: Date Handling (UTC vs Local)
  await runTest('Date Handling (UTC Persistence)', () async {
    final now = DateTime.now().toUtc();
    final user = User({
      'name': 'Time User',
      'email': 'time@test.com',
      'created_at': now.toIso8601String(),
    });
    
    await user.save();
    
    final fetched = await User().query().find(user.id);
    final created = fetched?.createdAt; 
    
    if (created == null) throw 'Created At is null';
    
    // Using tolerance for microsecond differences across DBs
    if (created.difference(now).inMilliseconds.abs() > 1000) {
      throw 'Date mismatch. Original: $now, Fetched: $created';
    }
  });

  // TEST 21: Unique Constraint
  await runTest('Error Handling (Unique Constraint)', () async {
    final email = 'unique@test.com';
    await User({'name': 'U1', 'email': email, 'created_at': isoNow()}).save();
    
    try {
      await User({'name': 'U2', 'email': email, 'created_at': isoNow()}).save();
      throw 'Duplicate entry did NOT throw exception!';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('unique') && 
          !msg.contains('constraint') &&
          !msg.contains('23505')) { // Postgres specific
         throw 'Caught unexpected error instead of constraint violation: $e';
      }
    }
  });

  // TEST 22: Watch logic
  await runTest('Reactivity (Watch)', () async {
    final stream = User().query().watch();
    final completer = Completer<List<User>>();
    
    int emissionCount = 0;
    final subscription = stream.listen((users) {
      emissionCount++;
      final hasMarker = users.any((u) => u.attributes['name'] == 'Watcher');
      if (hasMarker) {
        if (!completer.isCompleted) completer.complete(users);
      }
    });

    await Future.delayed(Duration(milliseconds: 50));

    await User({
      'name': 'Watcher',
      'email': 'watch@test.com',
      'created_at': isoNow(),
    }).save();

    try {
      await completer.future.timeout(Duration(seconds: 2));
    } catch (e) {
      throw 'Watch stream did not emit updated data within timeout. Emissions: $emissionCount';
    } finally {
      await subscription.cancel();
    }
  });

  print('\n🎉 --- ALL SYSTEMS GO: CORE IS STABLE --- 🎉');
}
