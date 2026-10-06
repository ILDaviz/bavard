# Creating Models

Each database table corresponds to a class that extends `Model`.

## Basic Model

At a minimum, you must override `table` and `fromMap`.

```dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';

class User extends Model {
  @override
  String get table => 'users';

  // Define schema for query safety and automatic casting
  @override
  List<SchemaColumn> get columns => [
    IdColumn(),
    TextColumn('name'),
    BoolColumn('is_active'),
  ];

  // Constructor that passes attributes to the super class
  User([super.attributes]);

  // Factory method for hydration
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

### Relationships & `getRelation`

For eager loading (`withRelations`) and relation resolution, Bavard needs to map a relationship name (e.g. `'posts'`) to its definition method. There are two ways to provide this mapping:

#### Option 1: Code generation (recommended)

If your model is annotated with `@fillable` and you run `build_runner`, the `getRelation` override is **generated automatically** from the signature of every method or getter returning a `Relation` subtype — no boilerplate needed:

```dart
@fillable
class User extends Model with $UserFillable {
  // ... (table, schema, etc.)

  // Just define the relationship: getRelation dispatch is generated.
  HasMany<Post> posts() => hasMany(Post.new);
}
```

See [Code Generation](/tooling/code-generation) for setup details.

#### Option 2: Manual override

If you don't use code generation (runtime-first), override `getRelation` yourself:

```dart
class User extends Model {
  HasMany<Post> posts() => hasMany(Post.new);

  @override
  Relation? getRelation(String name) {
    if (name == 'posts') return posts();
    return super.getRelation(name);
  }
}
```

::: warning Only for the manual path
The `getRelation` override is required **only** when you don't use `@fillable` code generation.
Without it (in the manual path), Bavard will not be able to find and load related models dynamically.
:::

## Accessing Attributes

By default, attributes are stored in a `Map<String, dynamic>`.

```dart
final user = User();

// Setter
user.attributes['name'] = 'Mario';

// Getter
print(user.attributes['name']);
```

### Typed Helpers

Bavard includes the `HasAttributeHelpers` mixin by default, which provides cleaner access:

```dart
// Bracket notation
user['name'] = 'Mario';

// Typed getters
String? name = user.string('name');
int? age = user.integer('age');
bool? active = user.boolean('is_active');
```

## Manual Implementation (No Code Generation)

While code generation is recommended to reduce boilerplate, you can define your models using standard Dart code. This gives you full control and requires no background processes.

To implement a model manually, you should:
1. Define explicit **getters and setters** using `getAttribute<T>()` and `setAttribute()`.
2. Override the **`columns`** list to define the schema and automatic casting.
3. (Optional) Define `fillable` or `guarded` attributes for mass assignment.

```dart
class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  // 1. Explicit Getters & Setters
  String? get name => getAttribute<String>('name');
  set name(String? value) => setAttribute('name', value);

  int? get age => getAttribute<int>('age');
  set age(int? value) => setAttribute('age', value);

  // 2. Define Schema (Enables automatic casting)
  @override
  List<SchemaColumn> get columns => [
    IntColumn('age'),
    BoolColumn('is_active'),
    JsonColumn('metadata'),
  ];

  // 3. Mass Assignment Protection
  @override
  List<String> get fillable => ['name', 'age'];
}
```

### Full Model Template

Here is a complete, ready-to-use template combining schema, typed accessors, casts, and relationships — a good starting point for new models:

```dart
import 'package:bavard/bavard.dart';
import 'post.dart';

class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);

  // SCHEMA
  static const schema = (
    name: TextColumn('name'),
    age: IntColumn('age'),
    isActive: BoolColumn('is_active'),
    metadata: JsonColumn('metadata'),
  );

  // ACCESSORS
  String? get name => getAttribute<String>('name');
  set name(String? value) => setAttribute('name', value);

  int? get age => getAttribute<int>('age');
  set age(int? value) => setAttribute('age', value);

  bool? get isActive => getAttribute<bool>('is_active');
  set isActive(bool? value) => setAttribute('is_active', value);

  // RELATIONSHIPS
  HasMany<Post> posts() => hasMany(Post.new);

  @override
  Relation? getRelation(String name) {
    if (name == 'posts') return posts();
    return super.getRelation(name);
  }

  // CASTS
  @override
  Map<String, String> get casts => {
    'age': 'int',
    'is_active': 'bool',
    'metadata': 'json',
  };
}
```

## Model with Code Generation (Recommended)

For full type safety and better IDE support, use the `@fillable` annotation and `build_runner`.

1. **Annotate the class** and add the **mixin**.
2. **Define the schema** in `static const schemaTypes`.
3. **Add the part directive**.

```dart
import 'package:bavard/bavard.dart';

part 'user.g.dart'; // Name of the generated file

@fillable
class User extends Model with $UserFillable {
  @override
  String get table => 'users';

  static const schema = (
    id: IdColumn(),
    createdAt: CreatedAtColumn(),
    name: TextColumn('name'),
    email: TextColumn('email'),
    age: IntColumn('age'),
    isActive: BoolColumn('is_active'),
  );

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

Run the generator:
```bash
dart run build_runner build
```

Now you can use typed accessors:
```dart
user.name = 'Mario';
user.age = 30;
print(user.email);
```

## Dirty Checking

Bavard tracks changes made to a model's attributes. This allows it to perform optimized `UPDATE` queries that only modify the columns that have actually changed.

- `isDirty([attribute])`: Returns `true` if the model or a specific attribute has been modified.
- `getDirty()`: Returns a `Map` of all modified attributes and their new values.

```dart
final user = await User().query().find(1);

user.name = 'Updated Name';

print(user.isDirty()); // true
print(user.isDirty('name')); // true
print(user.isDirty('email')); // false
print(user.getDirty()); // {'name': 'Updated Name'}

await user.save(); // Only 'name' will be updated in the DB
print(user.isDirty()); // false
```
