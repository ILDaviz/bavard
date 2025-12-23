# Bavard Test Environment

This directory contains a standalone test environment for verifying **Bavard ORM** functionality against a real SQLite database. It covers all major relationship types, CRUD operations, and eager loading.

## Structure
- `Dockerfile`: Containerizes the Dart environment and installs system dependencies (`sqlite3`).
- `main.dart`: A comprehensive test script that implements a `SqliteAdapter`, defines models, and executes complex queries.
- `schema.sql`: The SQLite schema containing tables for all relationship types (HasOne, HasMany, BelongsToMany, Polymorphic).

## Prerequisites
- Docker installed on your machine.

## How to Run

From the **root directory** of the project, run the following command:

```bash
mkdir -p examples/sqlite-docker/data && \
docker build -f examples/sqlite-docker/Dockerfile -t bavard-test . && \
docker run --rm -v $(pwd)/examples/sqlite-docker/data:/app/test/data bavard-test

or

docker build -f examples/sqlite-docker/Dockerfile -t bavard-test . && docker run --rm bavard-test
```

## What it tests
1. **Initial Setup**: Adapter registration and schema migration.
2. **HasOne / BelongsTo**: One-to-one relationship between `User` and `Profile`.
3. **HasMany**: One-to-many relationship between `User` and `Post`.
4. **BelongsToMany**: Many-to-many relationship between `Post` and `Category` with **Pivot data**.
5. **Polymorphic (MorphMany/MorphTo)**: One-to-many polymorphic relationship where both `Post` and `Video` can have `Comment`s.

## Notes
- The `pubspec.yaml` inside this folder links the `bavard` package via a local path (`/app/bavard`).
- The database is created in-memory (or as a local file inside the container) and destroyed when the container exits.
