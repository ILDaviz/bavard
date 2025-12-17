# Bavard ORM

**A Laravel Eloquent-inspired ORM for Dart/Flutter**

Bavard is an Object-Relational Mapping library that brings the Active Record pattern to Dart. If you're familiar with Laravel's Eloquent, you'll feel right at home. The goal is to simplify database interactions with SQLite, PostgreSQL, or PowerSync while keeping your code clean and readable.

---

## Installation

Add Bavard to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  bavard: ^0.0.1
```

Then run:

```bash
dart pub get
```

---

## Initial Setup

Before using Models, you need to configure the database adapter. This should be done once, typically in your app's `main()`:

```dart
import 'package:bavard/bavard.dart';

void main() {
  // Configure your adapter (SQLite, PowerSync, etc.)
  final myDatabaseAdapter = MyCustomAdapter();
  DatabaseManager().setDatabase(myDatabaseAdapter);
  
  // Now you can use Models
}
```

The adapter must implement the `DatabaseAdapter` interface, which defines the basic methods for queries, inserts, updates, and deletes.

---

## Creating a Model

Each database table corresponds to a class that extends `Model`:

```dart
class User extends Model {
  @override
  String get table => 'users';
  
  User([super.attributes]);
  
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

That's all you need to get started. Bavard follows "convention over configuration": if you don't specify anything, it assumes the primary key is `id`.

---

## CRUD Operations

### Creating a record

```dart
final user = User({'name': 'Mario', 'email': 'mario@example.com'});
await user.save();

// After save, the id is automatically populated
print(user.id); // 1
```

### Reading records

```dart
// Find by ID
final user = await User().query().find(1);

// Find or throw exception
final user = await User().query().findOrFail(1);

// First result
final user = await User().query().where('email', 'mario@example.com').first();

// All records
final users = await User().query().get();

// With conditions
final activeUsers = await User()
    .query()
    .where('active', 1)
    .where('age', 18, operator: '>=')
    .orderBy('name')
    .limit(10)
    .get();
```

### Updating a record

```dart
final user = await User().query().find(1);
user.attributes['name'] = 'Luigi';
await user.save();

// Bavard tracks only modified fields (dirty checking)
// and sends to the DB only those that actually changed
```

### Deleting a record

```dart
final user = await User().query().find(1);
await user.delete();
```

---

## Query Builder

The Query Builder provides a fluent interface for building SQL queries safely:

```dart
// WHERE with various operators
await User().query()
    .where('status', 'active')
    .where('age', 21, operator: '>=')
    .where('name', '%mario%', operator: 'LIKE')
    .get();

// OR WHERE
await User().query()
    .where('role', 'admin')
    .orWhere('role', 'superadmin')
    .get();

// WHERE IN
await User().query()
    .whereIn('id', [1, 2, 3])
    .get();

// WHERE NULL / NOT NULL
await User().query()
    .whereNull('deleted_at')
    .whereNotNull('email_verified_at')
    .get();

// Subquery with EXISTS
final subQuery = Post().query().whereRaw('user_id = users.id');
await User().query().whereExists(subQuery).get();
```

### Aggregations

```dart
final count = await User().query().where('active', 1).count();
final total = await Order().query().sum('amount');
final average = await Product().query().avg('price');
final max = await Score().query().max('points');
final min = await Score().query().min('points');
```

### GROUP BY and HAVING

```dart
await Order().query()
    .select(['customer_id', 'COUNT(*) as order_count', 'SUM(total) as total_spent'])
    .where('status', 'completed')
    .groupBy(['customer_id'])
    .having('COUNT(*)', 3, operator: '>=')
    .orderBy('total_spent', direction: 'DESC')
    .get();
```

### JOIN

```dart
await User().query()
    .join('profiles', 'users.id', '=', 'profiles.user_id')
    .leftJoin('orders', 'users.id', '=', 'orders.user_id')
    .get();
```

---

## Relationships

Bavard supports all classic ORM relationships.

### HasOne (One to One)

```dart
class User extends Model {
  @override
  String get table => 'users';
  
  HasOne<Profile> profile() => hasOne(Profile.new);
  
  // ...
}

// Usage
final user = await User().query().find(1);
final profile = await user.profile().getResult();
```

### HasMany (One to Many)

```dart
class User extends Model {
  HasMany<Post> posts() => hasMany(Post.new);
}

// Usage
final posts = await user.posts().get();

// With additional filters
final recentPosts = await user.posts()
    .where('published', true)
    .orderBy('created_at', direction: 'DESC')
    .limit(5)
    .get();
```

### BelongsTo (Inverse of HasOne/HasMany)

```dart
class Post extends Model {
  BelongsTo<User> author() => belongsTo(User.new, foreignKey: 'user_id');
}

final author = await post.author().getResult();
```

### BelongsToMany (Many to Many)

For relationships that go through a pivot table:

```dart
class User extends Model {
  BelongsToMany<Role> roles() => belongsToMany(
    Role.new,
    'role_user',  // pivot table
    foreignPivotKey: 'user_id',
    relatedPivotKey: 'role_id',
  );
}

final roles = await user.roles().get();
```

### HasManyThrough (Distant Relationships)

To reach models "through" an intermediate:

```dart
class Country extends Model {
  // Country -> User -> Post
  HasManyThrough<Post, User> posts() => hasManyThrough(Post.new, User.new);
}

final posts = await country.posts().get();
```

### Polymorphic Relationships

When a model can belong to multiple types of parents:

```dart
class Comment extends Model {
  // A comment can belong to Post or Video
  MorphTo<Model> commentable() => morphToTyped('commentable', {
    'posts': Post.new,
    'videos': Video.new,
  });
}

class Post extends Model {
  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');
}
```

### Eager Loading

To avoid the N+1 problem, load relationships in advance:

```dart
final users = await User().query()
    .withRelations(['posts', 'profile'])
    .get();

// Now access relationships without additional queries
for (final user in users) {
  final posts = user.getRelationList<Post>('posts');
  final profile = user.getRelated<Profile>('profile');
}
```

---

## Type Casting

Define how fields are converted between database and Dart:

```dart
class User extends Model {
  @override
  Map<String, String> get casts => {
    'age': 'int',
    'score': 'double',
    'is_active': 'bool',
    'created_at': 'datetime',
    'settings': 'json',
    'tags': 'array',
  };
}

// Values are converted automatically
final user = User({'age': '25', 'is_active': 1});
print(user.getAttribute<int>('age'));        // 25 (int)
print(user.getAttribute<bool>('is_active')); // true (bool)
```

### Supported Types

| Cast | Dart Type | Notes |
|------|-----------|-------|
| `int` | `int` | Converts numeric strings |
| `double` | `double` | Converts strings and ints |
| `bool` | `bool` | Accepts 1/0, "true"/"false" |
| `datetime` | `DateTime` | Parses from ISO-8601 |
| `json` | `dynamic` | Automatic JSON decode |
| `array` | `List<dynamic>` | For JSON arrays |
| `object` | `Map<String, dynamic>` | For JSON objects |

---

## Mixins and Advanced Features

### Automatic Timestamps

```dart
class Post extends Model with HasTimestamps {
  @override
  String get table => 'posts';
}

// created_at is set on insert
// updated_at is refreshed on every save
```

### Soft Deletes

Instead of physically deleting records, mark a deletion date:

```dart
class User extends Model with HasSoftDeletes {
  @override
  String get table => 'users';
}

// "Delete" (sets deleted_at)
await user.delete();

// Normal queries automatically exclude deleted records
final activeUsers = await User().query().get();

// Include deleted records too
final allUsers = await User().withTrashed().get();

// Only deleted records
final deletedUsers = await User().onlyTrashed().get();

// Restore a record
await user.restore();

// Actually delete from database
await user.forceDelete();
```

### UUID as Primary Key

```dart
class Document extends Model with HasUuids {
  @override
  String get table => 'documents';
}

// UUID is generated automatically before save
final doc = Document({'title': 'Report'});
await doc.save();
print(doc.id); // "550e8400-e29b-41d4-a716-446655440000"
```

### Global Scopes

Apply automatic filters to all queries of a Model:

```dart
class TenantScope implements Scope {
  final int tenantId;
  TenantScope(this.tenantId);
  
  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('tenant_id', tenantId);
  }
}

class Project extends Model with HasGlobalScopes {
  @override
  List<Scope> get globalScopes => [TenantScope(currentTenantId)];
}

// All queries automatically filter by tenant
final projects = await Project().query().get();

// Temporary bypass
final allProjects = await Project().withoutGlobalScopes().get();
```

---

## Mass Assignment Protection

Protect your models from unauthorized mass assignments:

```dart
class User extends Model {
  // Only these fields can be assigned via fill()
  @override
  List<String> get fillable => ['name', 'email', 'bio'];
  
  // Or, block specific fields
  @override
  List<String> get guarded => ['is_admin', 'api_key'];
}

// fill() respects the rules
user.fill({
  'name': 'Mario',
  'is_admin': true,  // Ignored!
});

// forceFill() bypasses protection (use with caution)
user.forceFill({'is_admin': true});
```

---

## Lifecycle Hooks

Intercept Model lifecycle events:

```dart
class User extends Model {
  @override
  Future<bool> onSaving() async {
    // Executed before every save
    // Return false to cancel the operation
    attributes['slug'] = generateSlug(attributes['name']);
    return true;
  }
  
  @override
  Future<void> onSaved() async {
    // Executed after a successful save
    await invalidateCache();
  }
  
  @override
  Future<bool> onDeleting() async {
    // Executed before delete
    // Return false to prevent deletion
    if (await hasActiveSubscription()) {
      return false;
    }
    return true;
  }
  
  @override
  Future<void> onDeleted() async {
    // Executed after delete
    await cleanupRelatedFiles();
  }
}
```

---

## Transactions

Execute multiple operations atomically:

```dart
await DatabaseManager().transaction((txn) async {
  final user = User({'name': 'Mario'});
  await user.save();
  
  final profile = Profile({'user_id': user.id, 'bio': 'Hello!'});
  await profile.save();
  
  // If anything fails, everything is rolled back
});
```

---

## Watch (Reactive Streams)

For reactive UIs with Flutter, use `watch()` instead of `get()`:

```dart
final stream = User().query()
    .where('active', 1)
    .orderBy('name')
    .watch();

// In a Flutter widget
StreamBuilder<List<User>>(
  stream: stream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return ListView(
      children: snapshot.data!.map((user) => UserTile(user)).toList(),
    );
  },
)
```

The stream automatically emits new data when records change in the database (requires adapter support).

---

## Code Generation

Bavard includes a code generator to create typed accessors:

```dart
@fillable
class User extends Model with $UserFillable {
  static const schemaTypes = {
    'name': 'string',
    'age': 'int',
    'email': 'string',
    'is_admin': 'bool:guarded',  // Not fillable
  };
  
  // ...
}

// After running build_runner, you can use:
user.name = 'Mario';      // Typed setter
print(user.age);          // Typed getter (int?)
```

Run the generator:

```bash
dart run build_runner build
```

---

## Error Handling

Bavard defines specific exceptions to handle errors granularly:

```dart
try {
  final user = await User().query().findOrFail(999);
} on ModelNotFoundException catch (e) {
  print('User not found: ${e.id}');
}

try {
  await User().query().where('invalid; DROP TABLE', 'x').get();
} on InvalidQueryException catch (e) {
  print('Invalid query: ${e.message}');
}

try {
  await DatabaseManager().transaction((txn) async {
    // operations that fail
  });
} on TransactionException catch (e) {
  print('Transaction failed: ${e.message}');
  print('Rollback executed: ${e.wasRolledBack}');
}
```

### Exception Types

| Exception | When Thrown |
|-----------|-------------|
| `ModelNotFoundException` | `findOrFail()` or `firstOrFail()` finds no record |
| `QueryException` | SQL execution fails |
| `TransactionException` | Transaction fails or is rolled back |
| `InvalidQueryException` | Invalid SQL structure (bad identifiers, operators) |
| `DatabaseNotInitializedException` | Using DB before calling `setDatabase()` |
| `MassAssignmentException` | Attempting to mass-assign guarded fields |
| `RelationNotFoundException` | Undefined relationship accessed |

---

## Implementing a Database Adapter

To use Bavard with your preferred database, implement `DatabaseAdapter`:

```dart
class MyAdapter implements DatabaseAdapter {
  @override
  Future<List<Map<String, dynamic>>> getAll(String sql, [List<dynamic>? args]) async {
    // Execute the query and return results
  }
  
  @override
  Future<Map<String, dynamic>> get(String sql, [List<dynamic>? args]) async {
    // Execute query and return first result
  }
  
  @override
  Future<void> execute(String sql, [List<dynamic>? args]) async {
    // Execute UPDATE, DELETE, DDL
  }
  
  @override
  Future<dynamic> insert(String table, Map<String, dynamic> values) async {
    // Insert and return generated ID
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watch(String sql, {List<dynamic>? parameters}) {
    // Return a stream for reactive queries
  }
  
  @override
  Future<T> transaction<T>(Future<T> Function(TransactionContext) callback) async {
    // Handle the transaction
  }
  
  @override
  bool get supportsTransactions => true;
}
```

The `TransactionContext` interface mirrors the adapter methods, ensuring all operations within the callback participate in the transaction.

---

## Best Practices

1. **Always use `query()`** to get a typed QueryBuilder
2. **Define `casts`** to ensure correct types
3. **Use `fillable` or `guarded`** to protect sensitive fields
4. **Prefer `withRelations()`** to avoid N+1 queries
5. **Use transactions** for operations that must be atomic
6. **Handle exceptions** appropriately in your app
7. **Leverage lifecycle hooks** for cross-cutting concerns like validation or caching

---

## Project Structure

```
bavard/
├── lib/
│   ├── bavard.dart              # Main entry point
│   └── src/
│       ├── core/
│       │   ├── model.dart       # Base Model class
│       │   ├── query_builder.dart
│       │   ├── database_adapter.dart
│       │   ├── database_manager.dart
│       │   ├── exceptions.dart
│       │   └── concerns/        # Mixins (timestamps, soft deletes, etc.)
│       ├── relations/           # Relationship definitions
│       └── generators/          # Code generation
```

---

## License

Bavard is released under the MIT License. See the LICENSE file for details.