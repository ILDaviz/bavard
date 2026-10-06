# Bavard Example Project

This is a demonstrative Flutter project that illustrates how to integrate and use **Bavard ORM** in a real-world application. 
The app is an simple Todo List that manages tasks and associated notes using relational relationships.

## Key Features Demonstrated

- **Database Setup**: Configuration of `SqfliteAdapter` with FFI initialization for Desktop support (macOS/Windows/Linux).
- **Migrations**: Schema definition via chronological migration classes.
- **Model Builder**: Usage of `@fillable` annotations and `schema` definition to automatically generate typed getters, setters, and casts.
- **Relationships**: Implementation of a **One-to-Many** relationship between `Todo` and `Post` models (each Todo can have multiple notes/posts).
- **Local Persistence**: The database is saved directly in the project root (`bavard_example.db`) for easy inspection during development.

## Project Structure

- `lib/models/`: Contains Bavard models with builder logic.
- `lib/migrations/`: Contains the database schema modification history.
- `lib/db.dart`: Central configuration for the adapter and migration registry.
- `lib/main.dart`: Flutter UI interacting with models via fluent queries.

## Getting Started

**Install dependencies**:
```bash
flutter pub get
```

**Code Generation (Builder)**:
Run the builder to generate `.g.dart` files for the models:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Execution**:
Launch the app on macOS (or your preferred platform):
```bash
flutter run -d macos
```

The database will be automatically created in the current folder upon the first launch.
