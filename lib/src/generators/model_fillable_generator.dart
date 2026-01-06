import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:bavard/src/generators/utility.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

import '../../bavard.dart';

/// Entry point for the builder. Generates a `.fillable.dart` file containing
/// the mixin implementation for models annotated with `@Fillable`.
Builder fillableGenerator(BuilderOptions options) =>
    PartBuilder(<Generator>[FillableGenerator()], '.fillable.dart');

class FillableGenerator extends GeneratorForAnnotation<Fillable> {
  /// Analyzes the `schema` static field to generate strongly-typed accessors,
  /// fillable/guarded lists, and cast maps.
  ///
  /// This relies on AST analysis to parse the `schema` initializer (expected to be a RecordLiteral)
  /// since the column definitions cannot be evaluated at runtime during the build phase.
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@fillable works only on classes.');
    }

    final className = element.name;
    final buffer = StringBuffer();
    final columnsData = <ColumnInfo>[];

    final schemaField = element.getField('schema');

    await getColumnFromSchema(schemaField, buildStep, columnsData);

    buffer.writeln("import 'package:bavard/bavard.dart';");
    buffer.writeln();
    buffer.writeln('mixin \$${className}Fillable on Model {');
    buffer.writeln();

    final fillableItems = columnsData
        .where((c) => !c.isGuarded)
        .map((c) => "'${c.dbName}'")
        .join(', ');

    final guardedItems = columnsData
        .where((c) => c.isGuarded)
        .map((c) => "'${c.dbName}'")
        .join(', ');

    buffer.writeln('  /// FILLABLE');
    buffer.writeln('  @override');
    buffer.writeln('  List<String> get fillable => const [$fillableItems];');

    buffer.writeln();
    buffer.writeln('  /// GUARDED');
    buffer.writeln('  @override');
    buffer.writeln('  List<String> get guarded => const [$guardedItems];');

    buffer.writeln();
    buffer.writeln('  /// CASTS');
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, dynamic> get casts => {');
    for (var col in columnsData) {
      buffer.writeln("    '${col.dbName}': '${col.castType}',");
    }
    buffer.writeln('  };');

    // Check for mixins
    final supertypes = element.allSupertypes.map((t) => t.element.name).toSet();
    final hasTimestamps = supertypes.contains('HasTimestamps');
    final hasSoftDeletes = supertypes.contains('HasSoftDeletes');

    // Generate type-safe accessors that proxy to the underlying dynamic `getAttribute` / `setAttribute`.
    for (var col in columnsData) {
      // Skip accessors if handled by mixins or base Model
      if (col.columnType == 'IdColumn') continue;
      if (hasTimestamps &&
          (col.columnType == 'CreatedAtColumn' ||
              col.columnType == 'UpdatedAtColumn'))
        continue;
      if (hasSoftDeletes && col.columnType == 'DeletedAtColumn') continue;

      buffer.writeln();
      buffer.writeln(
        '  /// Accessor for [${col.propertyName}] (DB: ${col.dbName})',
      );
      buffer.writeln('  ${col.dartType} get ${col.propertyName} {');
      buffer.writeln("    return getAttribute('${col.dbName}');");
      buffer.writeln('  }');
      buffer.writeln(
        '  set ${col.propertyName}(${col.dartType} value) => setAttribute(\'${col.dbName}\', value);',
      );
    }

    buffer.writeln('}');
    return buffer.toString();
  }
}
