# Code Generation

Bavard includes a code generator to create typed accessors, eliminating the need to work with raw `attributes` maps.

## Setup

1. Add `build_runner` and `bavard` to your dev dependencies.
2. In your model file, add the `part` directive.
3. Annotate the class with `@fillable`.
4. Mix in the generated class (e.g., `$UserFillable`).
5. Define the `static const schema`.

```dart
import 'package:bavard/bavard.dart';

part 'user.fillable.g.dart';

@fillable
class User extends Model with $UserFillable {
  @override
  String get table => 'users';

  static const schema = (
    name: TextColumn('name'),
    email: TextColumn('email'),
    age: IntColumn('age', isNullable: true),
    isAdmin: BoolColumn('is_admin', isGuarded: true),
  );

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}
```

## Running the Builder

```bash
dart run build_runner build
```

## Generated Features

The generator creates:
1. **Typed Getters/Setters**: `user.name`, `user.age`.
2. **Fillable/Guarded Lists**: Automatically derived from the schema (using `isGuarded`).
3. **Casts Map**: Automatically derived from the column types.
4. **Static Schema**: Enables type-safe queries like `User().query().where(User.schema.age.greaterThan(18))`.

## Type Modifiers

In the schema definition:
- `isNullable: true`: The Dart getter will be nullable (e.g., `int?`).
- `isGuarded: true`: The field will be added to the `guarded` list and excluded from `fillable`.
