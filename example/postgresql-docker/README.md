# Bavard Postgres Test Environment

This directory contains a standalone test environment for verifying **Bavard ORM** functionality against a real **PostgreSQL** database. It covers all major relationship types, CRUD operations, and eager loading.

## Structure
- `docker-compose.yaml`: Orchestrates the PostgreSQL database service and the Dart test application.
- `Dockerfile`: Containerizes the Dart environment (`app` service).
- `main.dart`: A comprehensive test script that implements a `PostgresAdapter`, defines models, and executes complex queries.

## Prerequisites
- Docker & Docker Compose installed on your machine.

## How to Run

From the **root directory** of the project, run the following command:

```bash
docker compose -f example/postgresql-docker/docker-compose.yaml up --build
```

This will:
1. Start a PostgreSQL 15 instance.
2. Build the Dart application container.
3. Wait for the database to be ready.
4. Run the test suite.

To clean up:
```bash
docker compose -f example/postgresql-docker/docker-compose.yaml down -v
```

## Notes
- The `pubspec.yaml` inside this folder links the `bavard` package via a local path (`/app/bavard`).
- The database data is not persisted (unless you remove the `-v` flag on down), making tests repeatable.
