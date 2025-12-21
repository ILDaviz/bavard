import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

import '../../bavard.dart';

/// Entry point for the builder. Generates a `.fillable.g.dart` file containing
/// the mixin implementation for models annotated with `@Fillable`.
Builder fillableGenerator(BuilderOptions options) =>
    LibraryBuilder(FillableGenerator(), generatedExtension: '.fillable.g.dart');

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
    final columnsData = <_ColumnInfo>[];

    final schemaField = element.getField('schema');

    // We specifically look for a static field named 'schema'.
    // AST resolution is required here to inspect the literal structure of the field's initializer.
    if (schemaField != null && schemaField.isStatic) {
      AstNode? astNode;

      final resolver = buildStep.resolver as dynamic;

      // Accessing the underlying AST node via fragments to handle recent analyzer API changes.
      final fragment = (schemaField as dynamic).firstFragment;
      astNode = await resolver.astNodeFor(fragment, resolve: true);

      if (astNode is VariableDeclaration) {
        final initializer = astNode.initializer;

        // Expects the schema to be defined as a Record, e.g.: static final schema = ( ... );
        if (initializer is RecordLiteral) {
          for (var field in initializer.fields) {
            if (field is NamedExpression) {
              final propertyName = field.name.label.name;
              final expression = field.expression;

              // Identifies column definitions like `TextColumn('name')`.
              if (expression is InstanceCreationExpression) {
                final typeName = expression.staticType?.element?.name;
                final args = expression.argumentList.arguments;

                // Extract DB column name from the first positional argument.
                String? dbName;
                if (args.isNotEmpty && args.first is SimpleStringLiteral) {
                  dbName = (args.first as SimpleStringLiteral).value;
                }

                bool isNullable = false;
                bool isGuarded = false;

                // Manually parse named arguments for configuration flags since we cannot instantiate the object.
                for (var arg in args) {
                  if (arg is NamedExpression) {
                    final argName = arg.name.label.name;
                    if (arg.expression is BooleanLiteral) {
                      final value = (arg.expression as BooleanLiteral).value;
                      if (argName == 'isNullable') isNullable = value;
                      if (argName == 'isGuarded') isGuarded = value;
                    }
                  }
                }

                String? baseType;
                String? castType;

                // Map ORM column types to Dart primitives.
                switch (typeName) {
                  case 'TextColumn':
                    baseType = 'String';
                    castType = 'string';
                    break;
                  case 'IntColumn':
                  case 'IntegerColumn':
                    baseType = 'int';
                    castType = 'int';
                    break;
                  case 'DoubleColumn':
                    baseType = 'double';
                    castType = 'double';
                    break;
                  case 'BoolColumn':
                  case 'BooleanColumn':
                    baseType = 'bool';
                    castType = 'bool';
                    break;
                  case 'DateTimeColumn':
                    baseType = 'DateTime';
                    castType = 'datetime';
                    break;
                  case 'JsonColumn':
                    baseType = 'dynamic';
                    castType = 'json';
                    break;
                  case 'ArrayColumn':
                    baseType = 'List<dynamic>';
                    castType = 'array';
                    break;
                  case 'ObjectColumn':
                    baseType = 'Map<String, dynamic>';
                    castType = 'object';
                    break;
                }

                if (dbName != null && baseType != null) {
                  final dartType = (isNullable && baseType != 'dynamic')
                      ? '$baseType?'
                      : baseType;

                  columnsData.add(_ColumnInfo(
                    propertyName: propertyName,
                    dbName: dbName,
                    dartType: dartType,
                    castType: castType!,
                    isGuarded: isGuarded,
                  ));
                }
              }
            }
          }
        }
      }
    }

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
    buffer.writeln('  Map<String, String> get casts => {');
    for (var col in columnsData) {
      buffer.writeln("    '${col.dbName}': '${col.castType}',");
    }
    buffer.writeln('  };');

    // Generate type-safe accessors that proxy to the underlying dynamic `getAttribute` / `setAttribute`.
    for (var col in columnsData) {
      buffer.writeln();
      buffer.writeln('  /// Accessor for [${col.propertyName}] (DB: ${col.dbName})');
      buffer.writeln('  ${col.dartType} get ${col.propertyName} {');
      buffer.writeln("    return getAttribute('${col.dbName}');");
      buffer.writeln('  }');
      buffer.writeln('  set ${col.propertyName}(${col.dartType} value) => setAttribute(\'${col.dbName}\', value);');
    }

    buffer.writeln('}');
    return buffer.toString();
  }
}

class _ColumnInfo {
  final String propertyName;
  final String dbName;
  final String dartType;
  final String castType;
  final bool isGuarded;

  _ColumnInfo({
    required this.propertyName,
    required this.dbName,
    required this.dartType,
    required this.castType,
    required this.isGuarded,
  });
}