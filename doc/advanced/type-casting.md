# Type Casting

Bavard manages data conversion through the HasCasts mixin, acting as a bridge between raw database values and Dart objects. Hydration occurs when fetching records; the framework stores the raw data internally but lazily parses it—converting timestamps, booleans, or JSON strings into their respective objects—only when you access an attribute via getAttribute. Conversely, Dehydration prepares data for storage or comparison. When setting values or saving a model, the framework serializes rich Dart objects back into database-compatible primitives (like integers for booleans), ensuring complex structures are correctly encoded for persistence and dirty checking.

## Defining Casts

The recommended way to define casts is by overriding the `columns` getter with a list of `SchemaColumn` objects. This provides both runtime type conversion and the foundation for type-safe queries.

```dart
class User extends Model {
  @override
  List<SchemaColumn> get columns => [
    IntColumn('age'),
    DoubleColumn('score'),
    BoolColumn('is_active'),
    DateTimeColumn('created_at'),
    JsonColumn('settings'),
    ArrayColumn('tags'),
    ObjectColumn('metadata'),
  ];
}
```

### Advanced: Explicit Overrides

If you need to define a cast without adding a full schema column, or to override a schema-derived cast, you can still use the `casts` map:

```dart
@override
Map<String, String> get casts => {
  'legacy_field': 'int',
};
```


## Supported Types

| Cast Type | Dart Type | Behavior |
|-----------|-----------|----------|
| `int` | `int` | Parses strings, converts nums |
| `double` | `double` | Parses strings, converts nums |
| `bool` | `bool` | `1`/`0`, `"true"`/`"false"` -> `bool` |
| `datetime` | `DateTime` | ISO-8601 string <-> `DateTime` |
| `json` | `dynamic` | JSON string <-> Decoded JSON |
| `array` | `List` | JSON string <-> `List` |
| `object` | `Map` | JSON string <-> `Map` |

## Custom Attribute Casting

For complex types not covered by the standard casts, you can define your own transformation logic by implementing the `AttributeCast<T, R>` interface.

This allows you to seamlessly transform raw database values into custom Dart objects and vice versa.

### Implementation

1.  Create a class that implements `AttributeCast<T, R>`, where:
    *   `T`: The runtime type (e.g., `Address`).
    *   `R`: The raw database type (e.g., `String`).
2.  Implement the `get` method to transform from the database value to the runtime value.
3.  Implement the `set` method to transform from the runtime value to the database value.

```dart
import 'dart:convert';
import 'package:bavard/bavard.dart';

class Address {
  final String street;
  final String city;

  Address(this.street, this.city);

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(json['street'], json['city']);
  }

  Map<String, dynamic> toJson() => {'street': street, 'city': city};
}

class AddressCast implements AttributeCast<Address, String> {
  @override
  Address get(String rawValue, Map<String, dynamic> attributes) {
    return Address.fromJson(jsonDecode(rawValue));
  }

  @override
  String set(Address value, Map<String, dynamic> attributes) {
    return jsonEncode(value.toJson());
  }
}
```

### Usage

Register your custom cast in the `casts` map of your model.

```dart
class User extends Model {
  // ...

  @override
  Map<String, dynamic> get casts => {
    'address': AddressCast(),
  };
  
  // Typed accessor
  Address? get address => getAttribute<Address>('address');
  set address(Address? value) => setAttribute('address', value);
}
```

Now you can work with `Address` objects directly:

```dart
final user = User();
user.address = Address('123 Main St', 'New York');

// Automatically serialized to JSON string for the DB
await user.save(); 

// Automatically deserialized back to Address object
print(user.address?.city); // "New York"
```

## Enum Casting

Bavard provides a helper to cast attributes to Dart Enums.

```dart
enum Status { active, inactive }

// Reading
final status = user.getEnum('status', Status.values);

// Writing
user.setAttribute('status', Status.active); // Stores 'active'
```
