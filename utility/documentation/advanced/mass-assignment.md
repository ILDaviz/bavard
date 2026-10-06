# Mass Assignment

Mass assignment is the process of sending an array of data to the model to set its attributes. While convenient, it can be a security risk if users pass unexpected fields (like `is_admin`).

Bavard protects against this using `fillable` and `guarded`.

## Fillable (Whitelist)

Define which attributes can be mass-assigned.

```dart
class User extends Model {
  @override
  List<String> get fillable => ['name', 'email', 'bio'];
}

// Only 'name' and 'email' will be set. 'is_admin' is ignored.
user.fill({
  'name': 'Mario',
  'email': 'mario@example.com',
  'is_admin': true,
});
```

## Guarded (Blacklist)

Define which attributes *cannot* be mass-assigned.

```dart
class User extends Model {
  @override
  List<String> get guarded => ['id', 'is_admin', 'api_key'];
}
```

> **Default:** By default, models are totally guarded (`['*']`). You must configure one of these to use `fill()`.

## Bypassing Protection

For internal use (e.g., seeding), you can bypass protection:

```dart
// Per instance
user.forceFill({'is_admin': true});

// Globally
HasGuardsAttributes.unguard();
// ... operations ...
HasGuardsAttributes.reguard();
```
