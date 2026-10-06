# Contributing to Bavard

Thanks for your interest in improving Bavard! This document covers the essentials
for working on the codebase.

## Setup

```bash
git clone https://github.com/ILDaviz/bavard.git
cd bavard
dart pub get
```

Requirements: Dart SDK `^3.10.1`. Docker is optional — only needed for the
database integration suites (SQLite and PostgreSQL).

## Development workflow

Before opening a PR, make sure all of these pass:

```bash
dart format lib test                        # formatting is enforced in CI
dart analyze                                # must be clean (--fatal-infos in CI)
dart test                                   # unit suite (mock DB, no Docker needed)
```

The full matrix, including code generation and real databases, runs with:

```bash
make test-all
```

which executes, in order:

1. Unit tests (`dart test`)
2. Codegen example suite (`example/builder_usage`, runs `build_runner` + tests)
3. SQLite integration suite (Docker)
4. PostgreSQL integration suite (Docker Compose)

### Testing conventions

- Unit tests run against `MockDatabaseSpy` (see `package:bavard/testing.dart`):
  configure responses by SQL substring and assert on the generated SQL/bindings.
  They need no database and must stay hermetic.
- Cross-database behavior belongs in `example/shared_test_suite` so both the
  SQLite and PostgreSQL Docker suites execute it.
- Generator changes must extend `test/generators/` and, when they affect
  generated output, the end-to-end expectations in `example/builder_usage`.

### Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/) prefixes:
`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `style:`.
See `git log` for examples.

### Releases

Maintainers cut releases with `make release v=X.Y.Z`, which bumps `pubspec.yaml`,
tags and pushes. `CHANGELOG.md` must be updated in the same release cycle.