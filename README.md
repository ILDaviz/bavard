# Bavard ORM 🗣️

[![pub.dev](https://img.shields.io/pub/v/bavard.svg)](https://pub.dev/packages/bavard)

**The Eloquent-style ORM for Dart.**

> **Work in Progress**: This project is currently under active development. APIs may change.

Bavard brings the elegance and simplicity of Eloquent to the Dart ecosystem. It is designed to provide a fluent, expressive interface for database interactions, prioritizing developer experience, runtime flexibility, and readability.

---

## 🚀 Key Features

- ⚡️ **Runtime-first architecture:** Code generation is 100% optional. Bavard leverages Dart's runtime capabilities and mixins to work entirely without build processes.
- 🏗️ **Fluent Query Builder:** Construct complex SQL queries using an expressive and type-safe interface.
- 🔗 **Rich Relationship Mapping:** Full support for One-to-One, One-to-Many, Many-to-Many, Polymorphic, and HasManyThrough relations.
- 🧩 **Smart Data Casting:** Automatic hydration and dehydration of complex types like JSON, DateTime, and Booleans between Dart and your database.
- 🏭 **Production-ready features:** Built-in support for Soft Deletes, Automatic Timestamps, and Global Scopes out of the box.
- 📱 **Offline-first ready:** Native support for client-side UUIDs and a driver-agnostic architecture, ideal for local-first applications.
- 🕵️ **Dirty Checking:** Optimized database updates by tracking only the attributes that have actually changed.
- 🚀 **Eager Loading:** Powerful eager loading system to eliminate N+1 query problems.
- 🌐 **Database Agnostic:** Flexible adapter system with native support for SQLite and PostgreSQL.

---

## 📚 Documentation

For detailed guides, API references, and usage examples, please visit our documentation:

👉 **[Read the Documentation](https://ildaviz.github.io/bavard/)**

---

## 🧪 Examples & Integration

To see Bavard in action with a real database environment, check the integration suite:

*   [SQLite + Docker Integration Test](example/sqlite-docker/)
*   [PostgreSQL + Docker Integration Test](example/postgresql-docker/)

---

## 🤝 Contributing

Bavard is open-source. Feel free to explore the code, report issues, or submit pull requests.
