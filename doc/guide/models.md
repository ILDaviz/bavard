# Creating Models

Each database table corresponds to a class that extends `Model`.

## Basic Model

At a minimum, you must override `table` and `fromMap`.

```dart
import 'package:bavard/bavard.dart';

class User extends Model {
  @override
  String get table => 'users';

  // Constructor that passes attributes to the super class
  User([super.attributes]);

  // Factory method for hydration
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

### Relationships & `getRelation`

If the model defines relationships, it is **necessary** to override the `getRelation` method. This method maps relationship names (used in lazy loading) to the corresponding definition methods. For this ORM to function correctly, it must always be defined for each model.
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

::: tip
**Use the CLI!**
You don't have to type this boilerplate manually. Use the CLI tool to generate it for you:
```bash
dart run bavard make:model User --columns=name:string,age:int
```
See the [CLI Guide](../tooling/cli.md) for more details.
:::

While code generation is recommended to reduce boilerplate, you can define your models using standard Dart code. This gives you full control and requires no background processes.

To implement a model manually, you should:
1. Define explicit **getters and setters** using `getAttribute<T>()` and `setAttribute()`.
2. Override the `casts` map to define how data should be hydrated.
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

  // 2. Define Casts
  @override
  Map<String, String> get casts => {
    'age': 'int',
    'is_active': 'bool',
    'metadata': 'json',
  };

  // 3. Mass Assignment Protection
  @override
  List<String> get fillable => ['name', 'age'];
}
```

## Model with Code Generation (Recommended)

For full type safety and better IDE support, use the `@fillable` annotation and `build_runner`.

1. **Annotate the class** and add the **mixin**.
2. **Define the schema** in `static const schemaTypes`.
3. **Add the part directive**.

```dart
import 'package:bavard/bavard.dart';

part 'user.fillable.g.dart'; // Name of the generated file

@fillable
class User extends Model with $UserFillable {
  @override
  String get table => 'users';

  static const schema = (
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
