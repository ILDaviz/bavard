import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';

Future<void> getColumnFromSchema(
  FieldElement? schemaField,
  BuildStep buildStep,
  List<ColumnInfo> columnsData,
) async {
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
              final args = expression.argumentList.arguments;

              String? dbName;
              if (args.isNotEmpty && args.first is SimpleStringLiteral) {
                dbName = (args.first as SimpleStringLiteral).value;
              }

              bool isNullable = false;
              bool isGuarded = false;

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

                columnsData.add(
                  ColumnInfo(
                    propertyName: propertyName,
                    dbName: dbName,
                    dartType: dartType,
                    castType: castType!,
                    isGuarded: isGuarded,
                  ),
                );
              }
            }
          }
        }
      }
    }
  }
}

class ColumnInfo {
  final String propertyName;
  final String dbName;
  final String dartType;
  final String castType;
  final bool isGuarded;

  ColumnInfo({
    required this.propertyName,
    required this.dbName,
    required this.dartType,
    required this.castType,
    required this.isGuarded,
  });
}
