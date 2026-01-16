# Bavard Monorepo

This repository contains the source code for the Bavard ORM and its documentation.

## Structure

- **[packages/bavard](packages/bavard)**: The Dart package source code.
- **[packages/documentation](packages/documentation)**: The documentation website (VitePress).

## Development

This project is set up as a Dart Workspace.

### Running Tests

To run tests for the Bavard package:

```bash
make test
```

### Documentation

To run the documentation site locally:

```bash
cd packages/documentation
yarn install
yarn docs:dev
```
