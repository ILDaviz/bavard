---
layout: home

hero:
  name: "Bavard ORM"
  text: "A Eloquent-inspired ORM for Dart/Flutter"
  tagline: "Simplify database interactions with SQLite, PostgreSQL, or PowerSync while keeping your code clean and readable."
  actions:
    - theme: brand
      text: Get Started
      link: /guide/
    - theme: alt
      text: View on GitHub
      link: https://github.com/ILDaviz/bavard

features:
  - title: Fluent Query Builder
    details: Write readable queries like `User().query().where(User.schema.age.greaterThan(18)).get()`.
  - title: Active Record Pattern
    details: Models are responsible for saving themselves. `user.save()`, `user.delete()`.
  - title: Framework Agnostic
    details: Works with any database driver via the `DatabaseAdapter` interface.
  - title: Powerful Relations
    details: HasOne, HasMany, BelongsTo, ManyToMany, and Polymorphic relations supported out of the box.
---
