# Global Scopes

Global scopes allow you to add constraints to all queries for a given model. This is useful for implementing features like "Soft Deletes" (built-in) or Multi-Tenancy.

## Defining a Scope

Implement the `Scope` interface:

```dart
class TenantScope implements Scope {
  final int tenantId;
  TenantScope(this.tenantId);

  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('tenant_id', tenantId);
  }
}
```

## Applying the Scope

Use the `HasGlobalScopes` mixin and override `globalScopes`:

```dart
class Project extends Model with HasGlobalScopes {
  @override
  List<Scope> get globalScopes => [
    TenantScope(currentTenantId),
  ];
}
```

## Bypassing Scopes

To execute a query without applying the global scopes:

```dart
// Remove all scopes
await Project().withoutGlobalScopes().get();

// Remove specific scope
await Project().withoutGlobalScope<TenantScope>().get();
```
