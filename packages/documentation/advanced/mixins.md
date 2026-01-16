# Mixins Overview

Bavard uses Dart mixins to provide optional functionality to your models. This allows you to compose your models with exactly the features they need, keeping them lightweight.

## Available Mixins

| Mixin | Description |
|-------|-------------|
| [HasTimestamps](timestamps.md) | Automatically manages `created_at` and `updated_at`. |
| [HasSoftDeletes](soft-deletes.md) | Enables "trash" functionality instead of permanent deletion. |
| [HasUuids](uuids.md) | Uses UUID v4 for the primary key instead of auto-incrementing integers. |
| [HasGlobalScopes](global-scopes.md) | Applies default query constraints (e.g., multi-tenancy). |
| `HasGuardsAttributes` | Provides mass-assignment protection (included by default in `Model`). |
| `HasEvents` | Provides lifecycle hooks (included by default in `Model`). |
