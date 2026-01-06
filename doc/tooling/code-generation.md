# Code Generation

::: info
**Optional Feature**
Code generation is **not required** to use Bavard. It is provided purely as a convenience to generate typed getters/setters and reduce boilerplate. You can fully utilize the ORM without it.
:::

Bavard includes a code generator to create typed accessors, eliminating the need to work with raw `attributes` maps.

## @fillable

This annotation is used to generate, based on the provided schema, the various elements necessary to make the model typed. By adding the various getters and setters, the map of fillables and protecting the guarded fields.

### Setup

1. Add `build_runner` and `bavard` to your dev dependencies.
2. In your model file, add the `part` directive.
3. Annotate the class with `@fillable`.
4. Mix in the generated class (e.g., `$UserFillable`).
5. Define the `static const schema`.

```dart
import 'package:bavard/bavard.dart';

part 'user.fillable.dart';

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

### Running the Builder

```bash
dart run build_runner build
```

### Generated Features

The generator creates:
1. **Typed Getters/Setters**: `user.name`, `user.age`.
2. **Fillable/Guarded Lists**: Automatically derived from the schema (using `isGuarded`).
3. **Casting Rules**: Automatically derived from the column types, ensuring correct hydration of types like `DateTime`, `bool`, and `JSON`.
4. **Static Schema**: Enables type-safe queries like `User().query().where(User.schema.age.greaterThan(18))`.

### Type Modifiers

In the schema definition:
- `isNullable: true`: The Dart getter will be nullable (e.g., `int?`).
- `isGuarded: true`: The field will be added to the `guarded` list and excluded from `fillable`.

### Standard Columns

You can include standard columns in your schema to enable type-safe queries (e.g., `User.schema.createdAt`). The generator will **not** create duplicate accessors for these, as they are handled by the core mixins (`Model`, `HasTimestamps`, `HasSoftDeletes`).

- **`IdColumn`**: Resolves to the model's `primaryKey`.
- **`CreatedAtColumn`**: Resolves to `created_at` (or custom name).
- **`UpdatedAtColumn`**: Resolves to `updated_at` (or custom name).
- **`DeletedAtColumn`**: Resolves to `deleted_at`.

The column name is optional and will be resolved dynamically from the model's configuration.

```dart
static const schema = (
  id: IdColumn(), // Automatically resolves to primaryKey
  createdAt: CreatedAtColumn(),
  updatedAt: UpdatedAtColumn(),
  // ... other columns
);
```

::: warning Custom Column Names
If you have overridden the standard column names in your Model (e.g., `primaryKey => 'uuid'`), you **must** pass the name explicitly to the column constructor: `id: IdColumn('uuid')`.
This is required for the generator to correctly configure data casting (e.g. converting string UUIDs or timestamps) at runtime.
:::

## @bavardPivot

For Many-to-Many relationships, you can create strongly-typed `Pivot` classes to access data on the intermediate table.

1. Create a class that extends `Pivot`.
2. Add the `part` directive.
3. Annotate the class with `@bavardPivot`.
4. Add the generated mixin.
5. Define your pivot-specific columns in a `static const schema` record.

```dart
// user_role.dart
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';

import 'user_role.pivot.g.dart';

@bavardPivot
class UserRole extends Pivot with $UserRole {
  UserRole(super.attributes);

  static const schema = (
    createdAt: DateTimeColumn('created_at'),
    isActive: BoolColumn('is_active'),
  );
}
```

The pivot generator creates:
1. **Typed Getters/Setters**: `pivot.createdAt`, `pivot.isActive`.
2. **Static Columns List**: `UserRole.columns`, which can be passed to the `belongsToMany(...).using()` method.

::: tip
**Pro Tip:** If you don't want to use code generation for pivots, you can manually define getters/setters and the `columns` list. See the [Relationships Guide](/relationships/index#manual-pivot-no-code-generation) for more details.
:::
