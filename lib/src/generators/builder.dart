import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import '../../bavard.dart';

/// Entry point for the build runner system.
///
/// Registers the [FillableGenerator] to process classes and output `.fillable.g.dart` part-files.
Builder fillableGenerator(BuilderOptions options) =>
    LibraryBuilder(FillableGenerator(), generatedExtension: '.fillable.g.dart');

/// Code generator for classes annotated with `@Fillable`.
///
/// Introspects the static `schemaTypes` map in the source class to generate:
/// 1. A `mixin` containing type-safe accessors (getters/setters).
/// 2. An overridden `fillable` list to enforce mass-assignment security (excluding 'guarded' fields).
class FillableGenerator extends GeneratorForAnnotation<Fillable> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Utility to strip metadata (e.g., 'int:guarded' -> 'int').
    String baseType(String value) {
      return value.split(':').first;
    }

    // Utility to identify fields protected from mass assignment.
    bool isGuarded(String value) {
      return value.split(':').skip(1).contains('guarded');
    }

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@fillable can only be applied to classes.',
      );
    }

    final className = element.name;

    // Enforce the contract: Model must define `static const schemaTypes`.
    // This map acts as the single source of truth for field definitions.
    final castsField = element.getField('schemaTypes');
    if (castsField == null || !castsField.isStatic) {
      throw InvalidGenerationSourceError(
        'Model $className must define a static const Map<String, String> schemaTypes to be used with @fillable.',
      );
    }

    // Reflect on the compile-time constant value of the map.
    final schemaTypesObject = castsField.computeConstantValue();
    final schemaTypes = schemaTypesObject?.toMapValue();

    if (schemaTypes == null || schemaTypes.isEmpty) {
      throw InvalidGenerationSourceError(
        'Could not read a valid, non-empty constant Map value from schemaTypes.',
      );
    }

    final buffer = StringBuffer();
    final fieldsToGenerate = <String, String>{};

    // Unpack DartObject wrappers into raw strings for generation.
    schemaTypes.forEach((key, value) {
      final fieldName = key?.toStringValue();
      final castType = value?.toStringValue();
      if (fieldName != null && castType != null) {
        fieldsToGenerate[fieldName] = castType;
      }
    });

    // Construct the whitelist for `fillable`, filtering out any sensitive 'guarded' fields.
    final fillableNames = fieldsToGenerate.entries
        .where((e) => !isGuarded(e.value))
        .map((e) => "'${e.key}'")
        .join(', ');

    buffer.writeln("import 'package:bavard/bavard.dart';");
    buffer.writeln();

    buffer.writeln('mixin \$${className}Fillable on Model {');

    // Generate the mass-assignment whitelist.
    buffer.writeln('  @override');
    buffer.writeln('  List<String> get fillable => const [$fillableNames];');

    // Generate strongly-typed wrappers around the dynamic `getAttribute` / `setAttribute`.
    fieldsToGenerate.forEach((name, castType) {
      final cleanType = baseType(castType);
      final ormType = OrmCastType.fromString(cleanType);

      // Default to nullable unless explicitly marked with '!' (though DBs often default to null).
      final nullable = OrmCastType.isNullable(cleanType);
      final dartType = ormType?.dartType(nullable: nullable) ?? 'dynamic';

      buffer.writeln(' ');
      buffer.writeln('  /// Type-safe accessor for [$name].');
      buffer.writeln('  $dartType get $name {');
      buffer.writeln('    final value = getAttribute(\'$name\');');
      buffer.writeln('    return value as $dartType;');
      buffer.writeln('  }');

      buffer.writeln(
        '  set $name($dartType value) => setAttribute(\'$name\', value);',
      );
      buffer.writeln(' ');
    });

    buffer.writeln('}');

    return buffer.toString();
  }
}
