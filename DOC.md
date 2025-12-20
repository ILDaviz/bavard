# Documentation Update for Bavard ORM

Based on my analysis of the source code, I've identified several features and improvements that should be documented. Here's the updated documentation with new sections and enhancements:

```markdown
# Bavard ORM

> [!CAUTION]
> **This project is under active development. APIs and documentation may change.**

**A Eloquent-inspired ORM for Dart/Flutter**

Bavard is an Object-Relational Mapping library that brings the Active Record pattern to Dart. If you're familiar with Laravel's Eloquent, you'll feel right at home. The goal is to simplify database interactions with SQLite, PostgreSQL, or PowerSync while keeping your code clean and readable.

---

## Table of Contents

- [Installation](#installation)
- [Initial Setup](#initial-setup)
- [Convention Over Configuration](#convention-over-configuration)
- [Creating a Model](#creating-a-model)
- [CRUD Operations](#crud-operations)
- [Query Builder](#query-builder)
- [Relationships](#relationships)
- [Type Casting](#type-casting)
- [Mixins and Advanced Features](#mixins-and-advanced-features)
- [Mass Assignment Protection](#mass-assignment-protection)
- [Lifecycle Hooks](#lifecycle-hooks)
- [Transactions](#transactions)
- [Watch (Reactive Streams)](#watch-reactive-streams)
- [Code Generation](#code-generation)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Implementing a Database Adapter](#implementing-a-database-adapter)
- [Best Practices](#best-practices)

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

## Convention Over Configuration

Bavard follows the **Convention over Configuration** paradigm, popularized by Ruby on Rails. The idea is simple: by following sensible defaults and naming conventions, you can eliminate boilerplate configuration and focus on what makes your application unique.

### Why Convention Over Configuration?

- **Less boilerplate**: No XML files, no annotation overload, no configuration classes
- **Predictable behavior**: Once you learn the conventions, you know what to expect
- **Faster development**: Spend time on business logic, not on wiring things together
- **Easier onboarding**: New team members can understand the codebase quickly

### Naming Conventions

#### Table Names

By default, Bavard expects table names to be **plural** and **snake_case**:

| Model Class | Expected Table |
|-------------|----------------|
| `User` | `users` |
| `BlogPost` | `blog_posts` |
| `Category` | `categories` |
| `UserRole` | `user_roles` |

```dart
class User extends Model {
  @override
  String get table => 'users';  // Convention: plural, snake_case
}
```

#### Primary Keys

The default primary key is assumed to be `id`:

```dart
class User extends Model {
  @override
  String get primaryKey => 'id';  // This is the default, no need to specify
}
```

If your table uses a different primary key, override it:

```dart
class User extends Model {
  @override
  String get primaryKey => 'uuid';  // Custom primary key
}
```

#### Foreign Keys

Foreign keys follow the pattern `{singular_table_name}_id`:

| Relationship | Expected Foreign Key |
|--------------|---------------------|
| Post belongs to User | `user_id` on `posts` table |
| Comment belongs to Post | `post_id` on `comments` table |
| Profile belongs to User | `user_id` on `profiles` table |

```dart
// Bavard infers foreign key as 'user_id'
class Post extends Model {
  BelongsTo<User> author() => belongsTo(User.new);
  // Equivalent to: belongsTo(User.new, foreignKey: 'user_id', ownerKey: 'id')
}
```

The `Utils.foreignKey()` helper generates these automatically:

```dart
Utils.foreignKey('users');      // 'user_id'
Utils.foreignKey('categories'); // 'category_id'
Utils.foreignKey('blog_posts'); // 'blog_post_id'
```

#### Pivot Tables (Many-to-Many)

For many-to-many relationships, pivot tables should be named by joining the two table names in **alphabetical order**, separated by an underscore:

| Models | Expected Pivot Table |
|--------|---------------------|
| User ↔ Role | `role_user` |
| Post ↔ Tag | `post_tag` |
| Category ↔ Product | `category_product` |

Pivot table columns follow the foreign key convention:

```
role_user
├── user_id
└── role_id
```

#### Polymorphic Relationships

Polymorphic relationships use a `{name}_type` and `{name}_id` column pair:

| Morphable Name | Type Column | ID Column |
|----------------|-------------|-----------|
| `commentable` | `commentable_type` | `commentable_id` |
| `taggable` | `taggable_type` | `taggable_id` |
| `imageable` | `imageable_type` | `imageable_id` |

The `type` column stores the table name of the parent model:

```dart
// comments table
// ├── id
// ├── body
// ├── commentable_type  ('posts' or 'videos')
// └── commentable_id    (the parent's ID)

class Comment extends Model {
  MorphTo<Model> commentable() => morphToTyped('commentable', {
    'posts': Post.new,
    'videos': Video.new,
  });
}
```

#### Timestamps

When using `HasTimestamps`, Bavard expects these columns:

| Column | Purpose |
|--------|---------|
| `created_at` | Set when record is first created |
| `updated_at` | Updated on every save |

You can customize these:

```dart
class Post extends Model with HasTimestamps {
  @override
  String get createdAtColumn => 'date_created';
  
  @override
  String get updatedAtColumn => 'date_modified';
}
```

#### Soft Deletes

When using `HasSoftDeletes`, Bavard expects:

| Column | Purpose |
|--------|---------|
| `deleted_at` | Timestamp when record was soft-deleted (null if active) |

### Relationship Conventions

#### HasOne and HasMany

The foreign key is assumed to be on the **related** table:

```dart
class User extends Model {
  // Bavard looks for 'user_id' on the 'profiles' table
  HasOne<Profile> profile() => hasOne(Profile.new);
  
  // Bavard looks for 'user_id' on the 'posts' table
  HasMany<Post> posts() => hasMany(Post.new);
}
```

#### BelongsTo

The foreign key is assumed to be on the **current** model's table:

```dart
class Post extends Model {
  // Bavard looks for 'user_id' on the 'posts' table
  BelongsTo<User> author() => belongsTo(User.new);
}
```

#### HasManyThrough

Keys are inferred from the intermediate model:

```dart
class Country extends Model {
  // Country -> User (via country_id) -> Post (via user_id)
  HasManyThrough<Post, User> posts() => hasManyThrough(Post.new, User.new);
}
```

Expected schema:
```
countries: id, name
users:     id, country_id, name
posts:     id, user_id, title
```

### Overriding Conventions

Every convention can be overridden when your schema doesn't match:

```dart
class Post extends Model {
  @override
  String get table => 'blog_entries';  // Non-standard table name
  
  @override
  String get primaryKey => 'entry_id';  // Non-standard primary key
  
  // Non-standard foreign key
  BelongsTo<User> author() => belongsTo(
    User.new,
    foreignKey: 'author_uuid',
    ownerKey: 'uuid',
  );
  
  // Non-standard pivot table and keys
  BelongsToMany<Tag> tags() => belongsToMany(
    Tag.new,
    'entry_tags',           // Custom pivot table
    foreignPivotKey: 'entry_id',
    relatedPivotKey: 'tag_id',
  );
}
```

### Convention Summary Table

| Element | Convention | Example |
|---------|------------|---------|
| Table name | Plural, snake_case | `users`, `blog_posts` |
| Primary key | `id` | `id` |
| Foreign key | `{singular_table}_id` | `user_id`, `post_id` |
| Pivot table | Alphabetical join | `post_tag`, `role_user` |
| Pivot columns | Both foreign keys | `post_id`, `tag_id` |
| Morph type | `{name}_type` | `commentable_type` |
| Morph ID | `{name}_id` | `commentable_id` |
| Created timestamp | `created_at` | `created_at` |
| Updated timestamp | `updated_at` | `updated_at` |
| Soft delete | `deleted_at` | `deleted_at` |

---

## Creating a Model

Each database table corresponds to a class that extends `Model`.

### Basic Model (without code generation)

```dart
class User extends Model {
  @override
  String get table => 'users';
  
  User([super.attributes]);
  
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

### Model with Code Generation (recommended)

For type-safe attribute access, use the `@fillable` annotation:

```dart
import 'package:bavard/bavard.dart';

part 'user.fillable.g.dart';

@fillable
class User extends Model with $UserFillable {
  @override
  String get table => 'users';

  static const schemaTypes = {
    'name': 'string',
    'email': 'string',
    'age': 'int',
    'is_active': 'bool',
    'is_admin': 'bool:guarded',
    'created_at': 'datetime',
    'settings': 'json',
  };

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

Run the generator:

```bash
dart run build_runner build
```

Now you can use typed getters and setters like `user.name`, `user.email`, etc.

---

## CRUD Operations

### Creating a record

**Basic usage (without code generation):**

```dart
final user = User({'name': 'Mario', 'email': 'mario@example.com'});
await user.save();

// After save, the id is automatically populated
print(user.id); // 1
```

**Using attribute setters:**

```dart
final user = User();
user.attributes['name'] = 'Mario';
user.attributes['email'] = 'mario@example.com';
await user.save();
```

**With code generation (recommended):**

After running `build_runner`, you get typed getters and setters:

```dart
final user = User();
user.name = 'Mario';
user.email = 'mario@example.com';
user.age = 30;
user.isActive = true;
await user.save();

// After save, access attributes with type safety
print(user.id);    // 1
print(user.name);  // 'Mario'
print(user.email); // 'mario@example.com'
```

You can also mix constructor initialization with setters:

```dart
final user = User({'name': 'Mario'});
user.email = 'mario@example.com';
user.age = 30;
await user.save();
```

### Reading records

**Without code generation:**

```dart
final user = await User().query().find(1);
print(user?.attributes['name']);
```

**With code generation:**

```dart
// Find by ID
final user = await User().query().find(1);
print(user?.name);  // Typed access

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

// Access typed attributes
for (final user in activeUsers) {
  print('${user.name} is ${user.age} years old');
  print('Email: ${user.email}');
  print('Active: ${user.isActive}');
}
```

### Updating a record

**Without code generation:**

```dart
final user = await User().query().find(1);
user?.attributes['name'] = 'Luigi';
await user?.save();
```

**With code generation:**

```dart
final user = await User().query().findOrFail(1);
user.name = 'Luigi';
user.email = 'luigi@example.com';
user.age = 32;
await user.save();

// Bavard tracks only modified fields (dirty checking)
// and sends to the DB only those that actually changed
```

### Deleting a record

```dart
final user = await User().query().find(1);
await user?.delete();
```

### Bulk Operations

You can perform updates and deletes on multiple records at once using the query builder:

```dart
// Update multiple records
final rowsAffected = await User()
    .query()
    .where('status', 'inactive')
    .update({'archived': true, 'archived_at': DateTime.now().toIso8601String()});

print('Archived $rowsAffected users');

// Delete multiple records
final deletedCount = await User()
    .query()
    .where('created_at', '2020-01-01', operator: '<')
    .delete();

print('Deleted $deletedCount old records');
```

> **Note:** Bulk operations bypass model lifecycle hooks (`onSaving`, `onDeleting`, etc.) since they operate directly on the database without hydrating individual models.

---

## Query Builder

The Query Builder provides a fluent interface for building SQL queries safely.

### Basic WHERE clauses

```dart
// Simple equality
await User().query().where('status', 'active').get();

// With operators
await User().query()
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

### Nested WHERE Groups

For complex logical conditions, you can group WHERE clauses with parentheses:

```dart
// AND group: WHERE status = 'active' AND (role = 'admin' OR role = 'editor')
await User()
    .query()
    .where('status', 'active')
    .whereGroup((q) {
      q.where('role', 'admin').orWhere('role', 'editor');
    })
    .get();

// OR group: WHERE age > 18 OR (status = 'pending' AND created_at > '2023-01-01')
await User()
    .query()
    .where('age', 18, operator: '>')
    .orWhereGroup((q) {
      q.where('status', 'pending').where('created_at', '2023-01-01', operator: '>');
    })
    .get();

// Deep nesting is supported
await User()
    .query()
    .where('a', 1)
    .whereGroup((q1) {
      q1.where('b', 2).orWhereGroup((q2) {
        q2.where('c', 3).where('d', 4);
      });
    })
    .get();
// Generates: WHERE a = ? AND (b = ? OR (c = ? AND d = ?))
```

### Selecting specific columns

```dart
final users = await User().query()
    .select(['id', 'name', 'email'])
    .get();

// With raw expressions for aggregates
final stats = await Order().query()
    .select(['customer_id'])
    .selectRaw('COUNT(*) as order_count')
    .selectRaw('SUM(total) as total_spent')
    .groupBy(['customer_id'])
    .get();
```

### Ordering and pagination

```dart
final users = await User().query()
    .orderBy('created_at', direction: 'DESC')
    .limit(10)
    .offset(20)
    .get();
```

### Aggregations

```dart
final count = await User().query().where('active', 1).count();
final total = await Order().query().sum('amount');
final average = await Product().query().avg('price');
final max = await Score().query().max('points');
final min = await Score().query().min('points');
final exists = await User().query().where('email', 'test@example.com').exists();
final notExist = await User().query().where('email', 'ghost@example.com').notExist();
```

### GROUP BY and HAVING

```dart
final results = await Order().query()
    .select(['customer_id', 'COUNT(*) as order_count', 'SUM(total) as total_spent'])
    .where('status', 'completed')
    .groupBy(['customer_id'])
    .having('COUNT(*)', 3, operator: '>=')
    .orderBy('total_spent', direction: 'DESC')
    .get();

// Multiple HAVING conditions
await Order().query()
    .select(['customer_id', 'COUNT(*) as count'])
    .groupBy(['customer_id'])
    .having('COUNT(*)', 5, operator: '>=')
    .having('SUM(total)', 100, operator: '>')
    .get();

// OR HAVING
await Order().query()
    .select(['customer_id', 'COUNT(*) as count'])
    .groupBy(['customer_id'])
    .having('COUNT(*)', 10, operator: '>=')
    .orHaving('SUM(total)', 5000, operator: '>')
    .get();

// Raw HAVING for complex expressions
await Product().query()
    .select(['category', 'AVG(price) as avg_price'])
    .groupBy(['category'])
    .havingRaw('AVG(price) > ? AND COUNT(*) >= ?', bindings: [50, 10])
    .get();

// HAVING BETWEEN
await Order().query()
    .select(['customer_id', 'COUNT(*) as order_count'])
    .groupBy(['customer_id'])
    .havingBetween('COUNT(*)', 5, 20)
    .get();

// HAVING NULL checks
await Order().query()
    .select(['customer_id', 'MAX(discount) as max_discount'])
    .groupBy(['customer_id'])
    .havingNotNull('MAX(discount)')
    .get();
```

> **Note:** When using `count()` with `groupBy()`, Bavard wraps the query in a subquery to return the total number of groups. Other aggregates like `sum()`, `avg()`, `min()`, and `max()` throw an exception when combined with `groupBy()` since the result would be ambiguous.

### JOIN

```dart
final users = await User().query()
    .join('profiles', 'users.id', '=', 'profiles.user_id')
    .leftJoin('orders', 'users.id', '=', 'orders.user_id')
    .rightJoin('subscriptions', 'users.id', '=', 'subscriptions.user_id')
    .get();
```

### Raw WHERE clauses

For complex conditions, use raw SQL (with bindings for safety):

```dart
await User().query()
    .whereRaw('age > ? AND created_at > ?', bindings: [18, '2024-01-01'])
    .get();
```

### Debugging Queries

Bavard provides helpful methods for debugging your queries:

```dart
// Get the compiled SQL string
final sql = User().query().where('active', 1).toSql();
print(sql); // SELECT users.* FROM users WHERE active = ?

// Get SQL with bindings substituted (for debugging only!)
final rawSql = User().query().where('active', 1).toRawSql();
print(rawSql); // SELECT users.* FROM users WHERE active = 1

// Chain debug methods
await User().query()
    .where('status', 'active')
    .printQueryAndBindings()  // Prints query and bindings separately
    .printRawSql()            // Prints SQL with substituted values
    .get();
```

> **Warning:** Never use `toRawSql()` output for actual database queries. It's intended for debugging only and doesn't properly escape values.

---

## Relationships

Bavard supports all classic ORM relationships.

### HasOne (One to One)

```dart
class User extends Model {
  @override
  String get table => 'users';
  
  HasOne<Profile> profile() => hasOne(Profile.new);
}

// Usage
final user = await User().query().find(1);
final profile = await user?.profile().getResult();
print(profile?.bio);
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

for (final post in recentPosts) {
  print(post.title);
}

// Create a related model
final newPost = await user.posts().create({
  'title': 'My New Post',
  'content': 'Hello World!',
});
// The foreign key (user_id) is automatically set
```

### BelongsTo (Inverse of HasOne/HasMany)

```dart
class Post extends Model {
  BelongsTo<User> author() => belongsTo(User.new, foreignKey: 'user_id');
}

// Usage
final author = await post.author().getResult();
print(author?.name);
```

### BelongsToMany (Many to Many)

For relationships that go through a pivot table:

```dart
class User extends Model {
  BelongsToMany<Role> roles() => belongsToMany(
    Role.new,
    'role_user',
    foreignPivotKey: 'user_id',
    relatedPivotKey: 'role_id',
  );
}

// Usage
final roles = await user.roles().get();
for (final role in roles) {
  print(role.name);
}
```

### HasManyThrough (Distant Relationships)

To reach models "through" an intermediate:

```dart
class Country extends Model {
  // Country -> User -> Post
  HasManyThrough<Post, User> posts() => hasManyThrough(Post.new, User.new);
}

// Usage
final posts = await country.posts().get();
```

### Polymorphic Relationships

When a model can belong to multiple types of parents:

```dart
class Comment extends Model {
  MorphTo<Model> commentable() => morphToTyped('commentable', {
    'posts': Post.new,
    'videos': Video.new,
  });
}

class Post extends Model {
  MorphMany<Comment> comments() => morphMany(Comment.new, 'commentable');
  MorphOne<Image> featuredImage() => morphOne(Image.new, 'imageable');
}

// Usage
final comments = await post.comments().get();
final image = await post.featuredImage().getResult();

// Inverse (from comment to parent)
final parent = await comment.commentable().getResult();
```

### Polymorphic Many-to-Many

```dart
class Post extends Model {
  MorphToMany<Tag> tags() => morphToMany(Tag.new, 'taggable');
}

// Usage
final tags = await post.tags().get();
```

### Eager Loading

To avoid the N+1 problem, load relationships in advance:

> [!WARNING]  
> Only one level of nested relations is allowed.

```dart
final users = await User().query()
    .withRelations(['posts', 'profile'])
    .get();

// Access relationships without additional queries
for (final user in users) {
  final posts = user.getRelationList<Post>('posts');
  final profile = user.getRelated<Profile>('profile');
  
  print('${user.name} has ${posts.length} posts');
  print('Bio: ${profile?.bio}');
}
```

### Defining getRelation for Eager Loading

To enable eager loading, implement `getRelation` in your model:

```dart
class User extends Model {
  HasMany<Post> posts() => hasMany(Post.new);
  HasOne<Profile> profile() => hasOne(Profile.new);
  
  @override
  Relation? getRelation(String name) {
    switch (name) {
      case 'posts':
        return posts();
      case 'profile':
        return profile();
      default:
        return null;
    }
  }
}
```

### Relationships and Global Scopes

Relationships automatically respect global scopes defined on the related model. For example, if `Post` uses `HasSoftDeletes`, then `user.posts().get()` will automatically exclude soft-deleted posts:

```dart
class Post extends Model with HasSoftDeletes {
  @override
  String get table => 'posts';
}

class User extends Model {
  HasMany<Post> posts() => hasMany(Post.new);
}

// This query automatically excludes soft-deleted posts
final activePosts = await user.posts().get();
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
    'metadata': 'object',
  };
}
```

### Reading with casts

```dart
final user = User({
  'age': '25',           // String from DB
  'is_active': 1,        // Int from DB
  'created_at': '2024-01-15T10:30:00.000',
  'settings': '{"theme":"dark"}',
});

// Values are automatically converted
print(user.getAttribute<int>('age'));           // 25 (int)
print(user.getAttribute<bool>('is_active'));    // true (bool)
print(user.getAttribute<DateTime>('created_at')); // DateTime object
print(user.getAttribute<Map>('settings'));      // {'theme': 'dark'}
```

### Writing with casts

```dart
final user = User();
user.setAttribute('is_active', true);    // Stored as 1
user.setAttribute('created_at', DateTime.now()); // Stored as ISO string
user.setAttribute('settings', {'theme': 'dark'}); // Stored as JSON string
```

### Supported Types

| Cast | Dart Type | Read Behavior | Write Behavior |
|------|-----------|---------------|----------------|
| `int` | `int` | Parses strings, converts nums | Passthrough |
| `double` | `double` | Parses strings, converts ints | Passthrough |
| `bool` | `bool` | Accepts 1/0, "true"/"false", "1"/"0" | Converts to 1/0 |
| `datetime` | `DateTime` | Parses ISO-8601 strings | Converts to ISO string |
| `json` | `dynamic` | Decodes JSON strings | Encodes to JSON string |
| `array` | `List<dynamic>` | Decodes JSON arrays | Encodes to JSON string |
| `object` | `Map<String, dynamic>` | Decodes JSON objects | Encodes to JSON string |

### Enum Support

```dart
enum UserStatus { active, inactive, pending }

final user = User({'status': 'active'});
final status = user.getEnum('status', UserStatus.values);
print(status); // UserStatus.active

// Also works with integer indices
final user2 = User({'status': 0});
final status2 = user2.getEnum('status', UserStatus.values);
print(status2); // UserStatus.active

// Writing enums
user.setAttribute('status', UserStatus.pending);
print(user.attributes['status']); // 'pending' (stored as string name)
```

### Helper Methods

The `HasAttributeHelpers` mixin provides convenient typed accessors:

```dart
final user = User({...});

// Typed helpers
String? name = user.string('name');
int? age = user.integer('age');
double? score = user.doubleNum('score');
bool? active = user.boolean('is_active');
DateTime? created = user.date('created_at');
Map<String, dynamic>? settings = user.json('settings');
T? status = user.enumeration('status', UserStatus.values);

// Bracket notation
user['name'] = 'Mario';
print(user['name']);
```

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

final post = Post();
post.title = 'Hello World';
await post.save();

print(post.createdAt); // Set automatically
print(post.updatedAt); // Set automatically
```

Customize column names:

```dart
class Post extends Model with HasTimestamps {
  @override
  String get createdAtColumn => 'date_created';
  
  @override
  String get updatedAtColumn => 'date_modified';
}
```

Disable timestamps:

```dart
class LegacyPost extends Model with HasTimestamps {
  @override
  bool get timestamps => false;
}
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
print(user.trashed); // true

// Normal queries automatically exclude deleted records
final activeUsers = await User().query().get();

// Include deleted records too
final allUsers = await User().withTrashed().get();

// Only deleted records
final deletedUsers = await User().onlyTrashed().get();

// Restore a record
await user.restore();
print(user.trashed); // false

// Permanently delete from database
await user.forceDelete();
```

### UUID as Primary Key

```dart
class Document extends Model with HasUuids {
  @override
  String get table => 'documents';
}

// UUID is generated automatically before save
final doc = Document();
doc.title = 'Report Q4';
await doc.save();

print(doc.id); // "550e8400-e29b-41d4-a716-446655440000"
```

The `HasUuids` mixin also sets `incrementing` to `false`, indicating the primary key is not auto-incremented.

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

class ActiveScope implements Scope {
  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('is_active', 1);
  }
}

class Project extends Model with HasGlobalScopes {
  @override
  List<Scope> get globalScopes => [
    TenantScope(currentTenantId),
    ActiveScope(),
  ];
}

// All queries automatically include scope conditions
final projects = await Project().query().get();
// SQL: SELECT * FROM projects WHERE tenant_id = ? AND is_active = ?

// Bypass all scopes
final allProjects = await Project().withoutGlobalScopes().get();

// Bypass specific scope
final allTenantProjects = await Project().withoutGlobalScope<ActiveScope>().get();
```

---

## Mass Assignment Protection

Protect your models from unauthorized mass assignments:

### Using fillable (whitelist)

```dart
class User extends Model {
  @override
  List<String> get fillable => ['name', 'email', 'bio'];
}

// Only whitelisted fields are assigned
user.fill({
  'name': 'Mario',
  'email': 'mario@example.com',
  'is_admin': true,  // Ignored!
});

print(user.name);  // 'Mario'
print(user.attributes.containsKey('is_admin')); // false
```

### Using guarded (blacklist)

```dart
class User extends Model {
  @override
  List<String> get guarded => ['id', 'is_admin', 'api_key'];
}

// All fields except guarded ones are assigned
user.fill({
  'name': 'Mario',
  'is_admin': true,  // Ignored!
});
```

### Default behavior

By default, all models are **totally guarded** (`guarded => ['*']`). You must explicitly define `fillable` or adjust `guarded` to allow mass assignment.

### Bypassing protection

```dart
// forceFill() bypasses all protection (use with caution!)
user.forceFill({
  'name': 'Mario',
  'is_admin': true,  // Assigned!
});

// Temporarily disable protection globally (for seeders, tests)
HasGuardsAttributes.unguard();
user.fill({'is_admin': true}); // Works now
HasGuardsAttributes.reguard(); // Re-enable protection
```

### Check if fillable

```dart
if (user.isFillable('email')) {
  user.fill({'email': 'new@example.com'});
}
```

---

## Lifecycle Hooks

Intercept Model lifecycle events:

```dart
class User extends Model {
  @override
  Future<bool> onSaving() async {
    // Executed before every save (insert or update)
    // Return false to cancel the operation
    
    // Example: Generate slug
    attributes['slug'] = generateSlug(attributes['name']);
    
    // Example: Validate
    if (attributes['email'] == null) {
      return false; // Cancel save
    }
    
    return true; // Proceed with save
  }
  
  @override
  Future<void> onSaved() async {
    // Executed after a successful save
    await invalidateCache();
    await sendWelcomeEmail();
  }
  
  @override
  Future<bool> onDeleting() async {
    // Executed before delete
    // Return false to prevent deletion
    
    if (await hasActiveSubscription()) {
      return false; // Prevent deletion
    }
    return true;
  }
  
  @override
  Future<void> onDeleted() async {
    // Executed after successful delete
    await cleanupRelatedFiles();
    await notifyAdmins();
  }
}
```

### Hook execution order

**For save:**
1. `onSaving()` — Return `false` to abort
2. INSERT or UPDATE executed
3. Record refreshed from DB
4. `onSaved()`

**For delete:**
1. `onDeleting()` — Return `false` to abort
2. DELETE executed
3. `onDeleted()`

---

## Transactions

Execute multiple operations atomically:

```dart
await DatabaseManager().transaction((txn) async {
  final user = User();
  user.name = 'Mario';
  user.email = 'mario@example.com';
  await user.save();
  
  final profile = Profile();
  profile.userId = user.id;
  profile.bio = 'Hello!';
  await profile.save();
  
  final settings = UserSettings();
  settings.userId = user.id;
  settings.theme = 'dark';
  await settings.save();
  
  // If anything fails, everything is rolled back
  return user; // Return value from transaction
});
```

### Transaction state

```dart
// Check if currently in a transaction
if (DatabaseManager().inTransaction) {
  print('Inside a transaction');
}
```

### Error handling

```dart
try {
  await DatabaseManager().transaction((txn) async {
    await user.save();
    throw Exception('Something went wrong');
  });
} on TransactionException catch (e) {
  print('Transaction failed: ${e.message}');
  print('Was rolled back: ${e.wasRolledBack}');
}
```

---

## Watch (Reactive Streams)

For reactive UIs with Flutter, use `watch()` instead of `get()`:

```dart
final stream = User().query()
    .where('active', 1)
    .orderBy('name')
    .watch();

// The stream emits new data whenever the underlying data changes
```

### Flutter integration

```dart
class UserListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<User>>(
      stream: User().query()
          .where('active', 1)
          .orderBy('name')
          .watch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        final users = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name ?? ''),
              subtitle: Text(user.email ?? ''),
            );
          },
        );
      },
    );
  }
}
```

> **Note:** Reactive streams require adapter support. The adapter must implement `watch()` to emit updates when data changes.

---

## Code Generation

Bavard includes a code generator to create typed accessors, eliminating the need to work with raw `attributes` maps.

### Setup

1. Add the `@fillable` annotation to your model
2. Define a `static const schemaTypes` map with field names and types
3. Mix in the generated `$ModelNameFillable` mixin
4. Add the `part` directive for the generated file

```dart
import 'package:bavard/bavard.dart';

part 'user.fillable.g.dart';

@fillable
class User extends Model with $UserFillable {
  @override
  String get table => 'users';

  static const schemaTypes = {
    'name': 'string',
    'email': 'string',
    'age': 'int',
    'score': 'double',
    'is_active': 'bool',
    'is_admin': 'bool:guarded',
    'created_at': 'datetime',
    'settings': 'json',
    'tags': 'array',
  };

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

### Generate the code

```bash
dart run build_runner build
```

Or watch for changes:

```bash
dart run build_runner watch
```

### Usage

After generation, use your model with full type safety:

```dart
// Create with typed setters
final user = User();
user.name = 'David';
user.email = 'david@example.com';
user.age = 28;
user.isActive = true;
user.settings = {'theme': 'dark', 'language': 'en'};
user.tags = ['developer', 'dart'];
await user.save();

// Read with typed getters
print(user.name);      // String?: 'David'
print(user.age);       // int?: 28
print(user.isActive);  // bool?: true
print(user.createdAt); // DateTime?
print(user.settings);  // dynamic: {'theme': 'dark', ...}
print(user.tags);      // List<dynamic>?: ['developer', 'dart']

// Update
user.name = 'David Updated';
user.score = 95.5;
await user.save();

// Query and iterate
final users = await User().query()
    .where('is_active', 1)
    .orderBy('name')
    .get();

for (final u in users) {
  print('${u.name} (${u.email}) - Age: ${u.age}');
}
```

### Type modifiers

| Modifier | Effect | Example |
|----------|--------|---------|
| `:guarded` | Excluded from `fillable` list | `'is_admin': 'bool:guarded'` |
| `?` | Explicitly nullable (default) | `'name': 'string?'` |
| `!` | Non-nullable | `'email': 'string!'` |

```dart
static const schemaTypes = {
  'name': 'string',            // String? name (nullable by default)
  'email': 'string!',          // String email (non-nullable)
  'api_key': 'string:guarded', // String? apiKey (protected from fill())
  'is_admin': 'bool:guarded',  // bool? isAdmin (protected)
};
```

### Generated fillable list

The generator automatically creates the `fillable` list, excluding `:guarded` fields:

```dart
// Generated in user.fillable.g.dart
mixin $UserFillable on Model {
  @override
  List<String> get fillable => const ['name', 'email', 'age', 'score', 'is_active', 'created_at', 'settings', 'tags'];
  // Note: 'is_admin' and 'api_key' are excluded because they're marked as :guarded
  
  String? get name => getAttribute('name');
  set name(String? value) => setAttribute('name', value);
  
  // ... other getters/setters
}
```

### Benefits

- **Type safety**: Catch type errors at compile time
- **IDE autocomplete**: Full IntelliSense support for all attributes
- **Cleaner code**: `user.name` instead of `user.attributes['name']`
- **Automatic casting**: Values are properly converted based on types
- **Mass assignment protection**: `:guarded` fields automatically protected

---

## Error Handling

Bavard defines specific exceptions for granular error handling:

```dart
try {
  final user = await User().query().findOrFail(999);
} on ModelNotFoundException catch (e) {
  print('Model: ${e.model}');
  print('ID: ${e.id}');
  print('Message: ${e.message}');
}

try {
  await User().query().where('invalid; DROP TABLE', 'x').get();
} on InvalidQueryException catch (e) {
  print('Invalid query: ${e.message}');
}

try {
  await DatabaseManager().transaction((txn) async {
    throw Exception('Oops!');
  });
} on TransactionException catch (e) {
  print('Transaction failed: ${e.message}');
  print('Rolled back: ${e.wasRolledBack}');
  print('Original error: ${e.originalError}');
}

try {
  await someQuery.get();
} on QueryException catch (e) {
  print('SQL: ${e.sql}');
  print('Bindings: ${e.bindings}');
  print('Error: ${e.message}');
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

### Catching all ORM exceptions

All exceptions extend `BavardException`:

```dart
try {
  // Any ORM operation
} on BavardException catch (e) {
  print('ORM error: ${e.message}');
}
```

---

## Testing

Bavard provides a `MockDatabaseSpy` for testing your models without a real database connection.

### Setup

Import the testing utilities:

```dart
import 'package:bavard/testing.dart';
```

### Basic Usage

```dart
void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  test('creates a user', () async {
    final user = User({'name': 'David'});
    await user.save();

    // Verify the INSERT was executed
    expect(dbSpy.history.any((sql) => sql.contains('INSERT INTO users')), isTrue);
  });
}
```

### Configuring Mock Responses

You can configure responses based on SQL patterns:

```dart
final dbSpy = MockDatabaseSpy(
  // Default data returned for unmatched queries
  [{'id': 1, 'name': 'Default'}],
  // Smart responses based on SQL substrings
  {
    'FROM users': [
      {'id': 1, 'name': 'David'},
      {'id': 2, 'name': 'Mario'},
    ],
    'FROM posts': [
      {'id': 1, 'title': 'Hello World', 'user_id': 1},
    ],
  },
);
DatabaseManager().setDatabase(dbSpy);
```

### Inspecting Queries

```dart
test('queries with correct parameters', () async {
  await User().query().where('active', 1).get();

  expect(dbSpy.lastSql, contains('WHERE active = ?'));
  expect(dbSpy.lastArgs, [1]);
  
  // Full history of all queries
  print(dbSpy.history);
});
```

### Testing Transactions

```dart
test('transaction commits on success', () async {
  await DatabaseManager().transaction((txn) async {
    final user = User({'name': 'David'});
    await user.save();
    return user;
  });

  expect(dbSpy.history, contains('BEGIN TRANSACTION'));
  expect(dbSpy.history, contains('COMMIT'));
  expect(dbSpy.history, isNot(contains('ROLLBACK')));
});

test('transaction rolls back on failure', () async {
  dbSpy.shouldFailTransaction = true;

  try {
    await DatabaseManager().transaction((txn) async {
      await User({'name': 'David'}).save();
    });
  } catch (e) {
    // Expected
  }

  expect(dbSpy.history, contains('BEGIN TRANSACTION'));
  expect(dbSpy.history, contains('ROLLBACK'));
});
```

### Updating Mock Data at Runtime

```dart
test('updates mock responses', () async {
  dbSpy.setMockData({
    'FROM users WHERE id = ?': [
      {'id': 1, 'name': 'Updated Name'},
    ],
  });

  final user = await User().query().find(1);
  expect(user?.attributes['name'], 'Updated Name');
});
```

---

## Implementing a Database Adapter

To use Bavard with your preferred database, implement `DatabaseAdapter`:

```dart
class MyAdapter implements DatabaseAdapter {
  final MyDatabaseConnection _connection;
  
  MyAdapter(this._connection);
  
  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _connection.query(sql, arguments);
  }
  
  @override
  Future<Map<String, dynamic>> get(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final results = await getAll(sql, arguments);
    return results.isNotEmpty ? results.first : {};
  }
  
  @override
  Future<int> execute(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _connection.execute(sql, arguments);
  }
  
  @override
  Future<dynamic> insert(
    String table,
    Map<String, dynamic> values,
  ) async {
    // Build and execute INSERT, return generated ID
    final keys = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    final sql = 'INSERT INTO $table ($keys) VALUES ($placeholders)';
    
    await _connection.execute(sql, values.values.toList());
    return await _connection.lastInsertId();
  }
  
  @override
  Stream<List<Map<String, dynamic>>> watch(
    String sql, {
    List<dynamic>? parameters,
  }) {
    // Return a stream that emits when data changes
    return _connection.watchQuery(sql, parameters);
  }
  
  @override
  bool get supportsTransactions => true;
  
  @override
  Future<T> transaction<T>(
    Future<T> Function(TransactionContext txn) callback,
  ) async {
    await _connection.execute('BEGIN');
    try {
      final context = MyTransactionContext(_connection);
      final result = await callback(context);
      await _connection.execute('COMMIT');
      return result;
    } catch (e) {
      await _connection.execute('ROLLBACK');
      rethrow;
    }
  }
}

class MyTransactionContext implements TransactionContext {
  final MyDatabaseConnection _connection;
  
  MyTransactionContext(this._connection);
  
  @override
  Future<List<Map<String, dynamic>>> getAll(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _connection.query(sql, arguments);
  }
  
  @override
  Future<Map<String, dynamic>> get(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final results = await getAll(sql, arguments);
    return results.isNotEmpty ? results.first : {};
  }
  
  @override
  Future<int> execute(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _connection.execute(sql, arguments);
  }
  
  @override
  Future<dynamic> insert(
    String table,
    Map<String, dynamic> values,
  ) async {
    // Same as adapter's insert
  }
}
```

---

## Best Practices

1. **Follow the conventions** — Let Bavard do the heavy lifting with sensible defaults
2. **Use code generation** — Get type safety and better IDE support
3. **Always use `query()`** — Returns a typed `QueryBuilder<T>` for your model
4. **Define `casts`** — Ensure correct type conversions between DB and Dart
5. **Use `fillable` or `guarded`** — Protect sensitive fields from mass assignment
6. **Prefer `withRelations()`** — Avoid N+1 queries by eager loading
7. **Use transactions** — For operations that must be atomic
8. **Handle exceptions** — Catch specific exceptions for better error handling
9. **Leverage lifecycle hooks** — For validation, caching, and side effects
10. **Use soft deletes** — When you need to preserve data history
11. **Write tests** — Use `MockDatabaseSpy` to verify your queries and model behavior

---

## License

Bavard is released under the MIT License. See the LICENSE file for details.
```