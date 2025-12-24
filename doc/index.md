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
  - title: Fluent query builder
    details: Write readable queries like `User().query().where(User.schema.age.greaterThan(18)).get()`.
  - title: Active record pattern
    details: Models are responsible for saving themselves. `user.save()`, `user.delete()`.
  - title: Framework agnostic
    details: Works with any database driver via the `DatabaseAdapter` interface.
  - title: Powerful relations
    details: HasOne, HasMany, BelongsTo, ManyToMany, and Polymorphic relations supported out of the box.
---
