import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'annotations.dart';

Builder pivotGenerator(BuilderOptions options) =>
    LibraryBuilder(PivotGenerator(), generatedExtension: '.pivot.g.dart');

class PivotGenerator extends GeneratorForAnnotation<BavardPivot> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError('@BavardPivot works only on classes.');
    }

    final className = element.name;
    final buffer = StringBuffer();
    final columns = <String>[];

    buffer.writeln('mixin _\$${className} on Pivot {');

    for (final field in element.fields) {
      if (field.isStatic) {
        final dartType = _getColumnGenericType(field.type);
        if (dartType != null) {
          final colName = field.name;
          final propName = _derivePropName(colName);
          
          // Getter
          buffer.writeln('  $dartType? get $propName => get($className.$colName);');

          // Setter
          buffer.writeln(
              '  set $propName($dartType? value) => set($className.$colName, value);');

          columns.add(colName);
        }
      }
    }

    // Static Schema
    buffer.writeln(
        '  static List<Column> get schema => [${columns.join(', ')}];');

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Returns the generic type T of Column<T> string representation if the type is a Column, else null.
  String? _getColumnGenericType(DartType type) {
    if (type is InterfaceType) {
       // Check if this type or any supertype is 'Column'
       // We iterate supertypes to find Column<T>
       
       // First check if the type itself is Column (unlikely for usage like IntColumn, but possible if Column<int> used directly)
       if (type.element.name == 'Column' && type.typeArguments.isNotEmpty) {
         return type.typeArguments.first.getDisplayString(withNullability: false);
       }
       
       for (final supertype in type.allSupertypes) {
         if (supertype.element.name == 'Column' && supertype.typeArguments.isNotEmpty) {
           return supertype.typeArguments.first.getDisplayString(withNullability: false);
         }
       }
    }
    return null;
  }

  String _derivePropName(String fieldName) {
    if (fieldName.endsWith('Col')) {
      return fieldName.substring(0, fieldName.length - 3);
    }
    if (fieldName.endsWith('Column')) {
      return fieldName.substring(0, fieldName.length - 6);
    }
    if (fieldName.endsWith('Field')) {
      return fieldName.substring(0, fieldName.length - 5);
    }
    return fieldName;
  }
}