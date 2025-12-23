# Installation

Add Bavard to your `pubspec.yaml` dependencies:

> [!IMPORTANT]
> For now, the project is under development and has not been released on pub.dev. As soon as it is ready, you will find it online. To use it, you need to download it and manage it as an external repository for the project.
>

```yaml
dependencies:
  bavard: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Requirements

- Dart SDK: `^3.10.1`
- `uuid`: `^4.5.2`

## Development Dependencies

If you plan to use code generation for typed models, add these dev dependencies:

```yaml
dev_dependencies:
  build_runner: ^2.10.4
  source_gen: ^4.1.1
  analyzer: ^9.0.0
```
