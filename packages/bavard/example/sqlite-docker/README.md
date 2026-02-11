# Bavard Test Environment

This directory contains a standalone test environment for verifying **Bavard ORM** functionality against a real SQLite database. It covers all major relationship types, CRUD operations, and eager loading.

## Structure
- `Dockerfile`: Containerizes the Dart environment and installs system dependencies (`sqlite3`).
- `main.dart`: A comprehensive test script that implements a `SqliteAdapter`, defines models, and executes complex queries.

## Prerequisites
- Docker installed on your machine.

## How to Run

From the **root directory** of the project, run the following command:

```bash
// Save persistent data to a local directory
mkdir -p example/sqlite-docker/data && \
docker build -f example/sqlite-docker/Dockerfile -t bavard-test . && \
docker run --rm -v $(pwd)/example/sqlite-docker/data:/app/test/data bavard-test

or
// Save persistent data to an in-memory database
docker build -f example/sqlite-docker/Dockerfile -t bavard-test . && docker run --rm bavard-test
```

## Notes
- The `pubspec.yaml` inside this folder links the `bavard` package via a local path (`/app/bavard`).
- The database is created in-memory (or as a local file inside the container) and destroyed when the container exits.
