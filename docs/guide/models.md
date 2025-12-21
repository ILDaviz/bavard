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
