import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'annotations.dart';

Builder pivotGenerator(BuilderOptions options) =>
    LibraryBuilder(PivotGenerator(), generatedExtension: '.pivot.g.dart');

class PivotGenerator extends GeneratorForAnnotation<BavardPivot> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@BavardPivot works only on classes.');
    }

    final className = element.name;
    final buffer = StringBuffer();
    final columnsData = <_ColumnInfo>[];

    final schemaField = element.getField('schema');

    if (schemaField != null && schemaField.isStatic) {
      AstNode? astNode;

      final resolver = buildStep.resolver as dynamic;
      final fragment = (schemaField as dynamic).firstFragment;
      astNode = await resolver.astNodeFor(fragment, resolve: true);

      if (astNode is VariableDeclaration) {
        final initializer = astNode.initializer;

        if (initializer is RecordLiteral) {
          for (var field in initializer.fields) {
            if (field is NamedExpression) {
              final propertyName = field.name.label.name;
              final expression = field.expression;

              if (expression is InstanceCreationExpression) {
                final typeName = expression.staticType?.element?.name;
                
                // Determine Dart type
                String? baseType;
                switch (typeName) {
                  case 'TextColumn':
                    baseType = 'String';
                    break;
                  case 'IntColumn':
                  case 'IntegerColumn':
                    baseType = 'int';
                    break;
                  case 'DoubleColumn':
                    baseType = 'double';
                    break;
                  case 'BoolColumn':
                  case 'BooleanColumn':
                    baseType = 'bool';
                    break;
                  case 'DateTimeColumn':
                    baseType = 'DateTime';
                    break;
                  case 'JsonColumn':
                    baseType = 'dynamic';
                    break;
                  case 'ArrayColumn':
                    baseType = 'List<dynamic>';
                    break;
                  case 'ObjectColumn':
                    baseType = 'Map<String, dynamic>';
                    break;
                }

                if (baseType != null) {
                   final dartType = (baseType != 'dynamic') ? '$baseType?' : baseType;
                   
                   columnsData.add(_ColumnInfo(
                     propertyName: propertyName,
                     dartType: dartType,
                   ));
                }
              }
            }
          }
        }
      }
    }

    buffer.writeln('mixin _\$${className} on Pivot {');

    for (final col in columnsData) {
      // Getter
      buffer.writeln('  ${col.dartType} get ${col.propertyName} => get($className.schema.${col.propertyName});');

      // Setter
      buffer.writeln(
          '  set ${col.propertyName}(${col.dartType} value) => set($className.schema.${col.propertyName}, value);');
    }

    // Static Schema List
    // We generate 'columns' instead of 'schema' to avoid conflict with the static Record 'schema'.
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
