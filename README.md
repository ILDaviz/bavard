# Bavard ORM 🗣️

**The Eloquent-style ORM for Dart.**

> **Work in Progress**: This project is currently under active development. APIs may change.

Bavard brings the elegance and simplicity of Eloquent to the Dart ecosystem. It is designed to provide a fluent, expressive interface for database interactions, prioritizing developer experience, runtime flexibility, and readability.

## Structure

- **[packages/bavard](packages/bavard)**: The Dart package source code. [![pub.dev](https://img.shields.io/pub/v/bavard.svg)](https://pub.dev/packages/bavard)
- **[packages/bavard_cli](packages/bavard_cli)**: The Dart package cli tool. [![pub.dev](https://img.shields.io/pub/v/bavard_cli.svg)](https://pub.dev/packages/bavard_cli)
- **[packages/bavard_migration](packages/bavard_migration)**: The Dart package migration tool. [![pub.dev](https://img.shields.io/pub/v/bavard_migration.svg)](https://pub.dev/packages/bavard_migration)
- **[packages/documentation](packages/documentation)**: The documentation website (VitePress).
- **[packages/bavard_example_project](packages/bavard_example_project)**: demonstrative Flutter project that illustrates how to integrate and use **Bavard ORM**

---

## 📚 Documentation

For detailed guides, API references, and usage examples, please visit our documentation:

👉 **[Read the Documentation](https://ildaviz.github.io/bavard/)**

## 🚀 Key Features

- 💙 **Flutter ready:** Seamlessly integrated with Flutter for mobile, desktop, and web applications.
- ⚡️ **Runtime-first architecture:** Code generation is 100% optional. Bavard leverages Dart's runtime capabilities and mixins to work entirely without build processes.
- 🏗️ **Fluent Query Builder:** Construct complex SQL queries using an expressive and type-safe interface.
- 🔗 **Rich Relationship Mapping:** Full support for One-to-One, One-to-Many, Many-to-Many, Polymorphic, and HasManyThrough relations.
- 🧩 **Smart Data Casting:** Automatic hydration and dehydration of complex types like JSON, DateTime, and Booleans between Dart and your database.
- 🏭 **Production-ready features:** Built-in support for Soft Deletes, Automatic Timestamps, and Global Scopes out of the box.
- 📱 **Offline-first ready:** Native support for client-side UUIDs and a driver-agnostic architecture, ideal for local-first applications.
- 🕵️ **Dirty Checking:** Optimized database updates by tracking only the attributes that have actually changed.
- 🚀 **Eager Loading:** Powerful eager loading system to eliminate N+1 query problems.
- 🌐 **Database Agnostic:** Flexible adapter system with native support for SQLite and PostgreSQL.

### Running Tests

To run tests for the all Bavard package:

```bash
make test
```
