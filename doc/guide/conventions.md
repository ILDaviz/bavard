# Convention Over Configuration

Bavard follows the **Convention over Configuration** paradigm, popularized by Ruby on Rails. The idea is simple: by following sensible defaults and naming conventions, you can eliminate boilerplate configuration and focus on what makes your application unique.

## Naming Conventions

### Table Names

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

### Primary Keys

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

### Foreign Keys

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

### Pivot Tables (Many-to-Many)

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

### Polymorphic Relationships

Polymorphic relationships use a `{name}_type` and `{name}_id` column pair:

| Morphable Name | Type Column | ID Column |
|----------------|-------------|-----------|
| `commentable` | `commentable_type` | `commentable_id` |
| `taggable` | `taggable_type` | `taggable_id` |

The `type` column stores the table name of the parent model.

### Timestamps

When using `HasTimestamps`, Bavard expects these columns:

| Column | Purpose |
|--------|---------|
| `created_at` | Set when record is first created |
| `updated_at` | Updated on every save |

### Soft Deletes

When using `HasSoftDeletes`, Bavard expects:

| Column | Purpose |
|--------|---------|
| `deleted_at` | Timestamp when record was soft-deleted (null if active) |

## Overriding Conventions

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
}
```
