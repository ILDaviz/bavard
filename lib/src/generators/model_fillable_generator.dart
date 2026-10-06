import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:bavard/src/generators/utility.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

import 'annotations.dart';

/// Entry point for the builder. Generates a `.g.dart` file containing
/// the mixin implementation for models annotated with `@Fillable`.
Builder fillableGenerator(BuilderOptions options) =>
    SharedPartBuilder(<Generator>[FillableGenerator()], 'fillable');

/// Describes a relation member (method or getter) discovered on the model class.
class _RelationMemberInfo {
  final String name;
  final String returnTypeDisplay;
  final bool isGetter;

  const _RelationMemberInfo({
    required this.name,
    required this.returnTypeDisplay,
    required this.isGetter,
  });
}

class FillableGenerator extends GeneratorForAnnotation<Fillable> {
  /// Analyzes the `schema` static field to generate strongly-typed accessors,
  /// fillable/guarded lists, and cast maps.
  ///
  /// Also scans the class for relation methods (any instance member returning a
  /// [Relation] subtype) and generates a `getRelation` override so eager loading
  /// works without handwritten dispatch.
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

    final relationMembers = _collectRelationMembers(element, columnsData);

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
              col.columnType == 'UpdatedAtColumn')) {
        continue;
      }
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

    _writeRelationDispatch(buffer, className, relationMembers);

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Collects the instance members of [element] that define relationships:
  /// non-static methods or getters whose return type is a subtype of [Relation].
  ///
  /// The model class must implement each discovered member (they are declared
  /// abstract in the generated mixin so it can invoke them at dispatch time).
  List<_RelationMemberInfo> _collectRelationMembers(
    ClassElement element,
    List<ColumnInfo> columnsData,
  ) {
    final relationChecker = TypeChecker.fromUrl(
      'package:bavard/src/relations/relation.dart#Relation',
    );

    final generatedAccessorNames = columnsData
        .map((c) => c.propertyName)
        .toSet();

    void assertNoAccessorCollision(String name) {
      if (generatedAccessorNames.contains(name)) {
        throw InvalidGenerationSourceError(
          'Relation member "$name" collides with a schema column accessor '
          'generated for the same name. Rename the relation member.',
          element: element,
        );
      }
    }

    final members = <_RelationMemberInfo>[];

    for (final method in element.methods) {
      // `getRelation` itself returns `Relation?`: it is the manual dispatch
      // hook, not a relation definition.
      if (method.isStatic || method.name == 'getRelation') continue;
      if (!relationChecker.isSuperTypeOf(method.returnType)) continue;

      final name = method.name;
      if (name == null) continue;
      assertNoAccessorCollision(name);

      if (method.formalParameters.any(
        (p) => p.isRequiredPositional || p.isRequiredNamed,
      )) {
        throw InvalidGenerationSourceError(
          'Relation method "$name" has required parameters, so it cannot be '
          'dispatched by getRelation. Remove the required parameters, rename '
          'the method, or drop @fillable from this class.',
          element: method,
        );
      }

      members.add(
        _RelationMemberInfo(
          name: name,
          returnTypeDisplay: method.returnType.getDisplayString(),
          isGetter: false,
        ),
      );
    }

    for (final getter in element.getters) {
      if (getter.isSynthetic || getter.isStatic) continue;
      if (!relationChecker.isSuperTypeOf(getter.returnType)) continue;

      final name = getter.name;
      if (name == null) continue;
      assertNoAccessorCollision(name);

      members.add(
        _RelationMemberInfo(
          name: name,
          returnTypeDisplay: getter.returnType.getDisplayString(),
          isGetter: true,
        ),
      );
    }

    return members;
  }

  /// Emits the abstract relation declarations and the generated `getRelation`
  /// override used by eager loading and lazy relation resolution.
  void _writeRelationDispatch(
    StringBuffer buffer,
    String? className,
    List<_RelationMemberInfo> members,
  ) {
    if (members.isEmpty) return;

    buffer.writeln();
    buffer.writeln('  /// RELATIONS');
    buffer.writeln(
      '  /// Implemented by $className; dispatched by the generated getRelation.',
    );

    for (final member in members) {
      buffer.writeln();
      if (member.isGetter) {
        buffer.writeln('  ${member.returnTypeDisplay} get ${member.name};');
      } else {
        buffer.writeln('  ${member.returnTypeDisplay} ${member.name}();');
      }
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Relation? getRelation(String name) {');
    buffer.writeln('    switch (name) {');
    for (final member in members) {
      final invocation = member.isGetter ? member.name : '${member.name}()';
      buffer.writeln("      case '${member.name}':");
      buffer.writeln('        return $invocation;');
    }
    buffer.writeln('      default:');
    buffer.writeln('        return super.getRelation(name);');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }
}
