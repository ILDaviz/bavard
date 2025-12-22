import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:bavard/src/generators/utility.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'annotations.dart';

Builder pivotGenerator(BuilderOptions options) =>
    LibraryBuilder(PivotGenerator(), generatedExtension: '.pivot.g.dart');

class PivotGenerator extends GeneratorForAnnotation<BavardPivot> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {

    final fileName = buildStep.inputId.pathSegments.last;

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@BavardPivot works only on classes.');
    }

    final className = element.name;
    final buffer = StringBuffer();
    final columnsData = <ColumnInfo>[];

    final schemaField = element.getField('schema');

    await getColumnFromSchema(schemaField, buildStep, columnsData);

    buffer.writeln();
    buffer.writeln("import 'package:bavard/bavard.dart';");
    buffer.writeln("import 'package:bavard/schema.dart';");
    buffer.writeln("import './$fileName';");
    buffer.writeln();

    buffer.writeln('mixin \$${className} on Pivot {');

    for (final col in columnsData) {
      buffer.writeln();
      buffer.writeln('  /// Accessor for [${col.propertyName}] (DB: ${col.dbName})');
      buffer.writeln('  ${col.dartType} get ${col.propertyName} => get($className.schema.${col.propertyName});');
      buffer.writeln(
          '  set ${col.propertyName}(${col.dartType} value) => set($className.schema.${col.propertyName}, value);');
    }

    buffer.writeln();

    final colList = columnsData.map((c) => '$className.schema.${c.propertyName}').join(', ');
    buffer.writeln('  static List<Column> get columns => [$colList];');

    buffer.writeln('}');
    return buffer.toString();
  }
}

class _ColumnInfo {
  final String propertyName;
  final String dartType;

  _ColumnInfo({
    required this.propertyName,
    required this.dartType,
  });
}
