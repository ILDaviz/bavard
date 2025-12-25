---
layout: home

hero:
  name: "Bavard"
  text: "An Eloquent-inspired ORM for Dart/Flutter"
  tagline: "Simplify interactions with SQLite, PostgreSQL, PowerSync, or whatever database you prefer. Keep your code clean and readable."
  actions:
    - theme: brand
      text: Get Started
      link: /guide/
    - theme: alt
      text: View on GitHub
      link: https://github.com/ILDaviz/bavard

features:
  - title: Flutter ready
    details: Seamlessly integrated with Flutter for mobile, desktop, and web applications.
  - title: Fluent query builder
    details: Write readable queries like `User().query().where(User.schema.age.greaterThan(18)).get()`.
  - title: Active record pattern
    details: Models are responsible for saving themselves. `user.save()`, `user.delete()`.
  - title: Framework agnostic
    details: Works with any database driver via the `DatabaseAdapter` interface.
  - title: Powerful relations
    details: HasOne, HasMany, BelongsTo, ManyToMany, and Polymorphic relations supported out of the box.
  - title: Zero boilerplate
    details: Code generation is completely optional. Bavard works entirely at runtime, allowing you to use standard Dart syntax without waiting for build_runner.
  - title: Offline-first ready
    details: Native support for client-side UUIDs and driver-agnostic architecture, perfect for local-first apps.
  - title: Production-ready
    details: Built-in support for soft deletes, automatic timestamps, and global scopes out of the box.
  - title: Smart Data Casting
    details: Automatic hydration of complex types like JSON, DateTime, and Booleans between Dart and your database.
---
