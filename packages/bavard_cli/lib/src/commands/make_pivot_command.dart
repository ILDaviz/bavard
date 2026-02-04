import 'dart:io';
import '../utils.dart';
import 'base_command.dart';

class MakePivotCommand extends BaseCommand {
  @override
  String get name => 'make:pivot';

  @override
  String get description => 'Create a new Bavard Pivot class for Many-to-Many relationships (Single File).';

  @override
  Future<int> run(List<String> args) async {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      printUsage();
      return 0;
    }

    final className = args[0];
    if (className.startsWith('-')) {
      printError('Pivot class name must be the first argument.');
      printUsage();
      return 1;
    }

    Map<String, String> columns = {};
    bool force = false;
    String? customPath;

    for (var i = 1; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--columns=')) {
        final colsRaw = arg.split('=')[1];
        for (final part in colsRaw.split(',')) {
          final pair = part.split(':');
          if (pair.length == 2) {
            columns[pair[0].trim()] = pair[1].trim().toLowerCase();
          }
        }
      } else if (arg.startsWith('--path=')) {
        customPath = arg.split('=')[1];
      } else if (arg == '--force') {
        force = true;
      }
    }

    final fileName = '${toSnakeCase(className)}.dart';
    
    String outputDir;
    if (customPath != null) {
      outputDir = customPath;
    } else {
      if (Directory('lib/models').existsSync()) {
        outputDir = 'lib/models';
      } else if (Directory('lib/src/models').existsSync()) {
        outputDir = 'lib/src/models';
      } else {
        outputDir = 'lib';
      }
    }

    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      printInfo("Creating directory: $outputDir");
      dir.createSync(recursive: true);
    }
    
    final filePath = '${dir.path}/$fileName';

    if (File(filePath).existsSync() && !force) {
      printError('File "$filePath" already exists. Use --force to overwrite.');
      return 1;
    }

    final content = _generateContent(className, columns);
    File(filePath).writeAsStringSync(content);
    printSuccess('✅ Pivot file created successfully: $filePath');

    return 0;
  }

  @override
  void printUsage() {
    print('${colorized('Description:', bold)}');
    print('  $description\n');
    print('${colorized('Usage:', bold)}');
    print('  dart run bavard $name <Name> [options]\n');
    print('${colorized('Options:', bold)}');
    print('  ${colorized('--columns=<list>', green)}    Comma-separated list of pivot columns (name:type).');
    print('                      Types: string, int, double, bool, datetime, json.');
    print('  ${colorized('--path=<path>', green)}       Specify the output directory.');
    print('  ${colorized('--force', green)}             Overwrite existing file.');
    print('  ${colorized('-h, --help', green)}          Show this help message.\n');
    print('${colorized('Examples:', bold)}');
    print('  1. Basic Pivot:');
    print('     dart run bavard $name UserRole --columns=is_active:bool,created_at:datetime');
  }

  String _generateContent(String className, Map<String, String> columns) {
    final buffer = StringBuffer();

    buffer.writeln("import 'package:bavard/bavard.dart';");
    buffer.writeln("import 'package:bavard/schema.dart';");
    buffer.writeln();
    buffer.writeln('class $className extends Pivot {');
    buffer.writeln('  $className(super.attributes);');
    buffer.writeln();
    buffer.writeln('  static const schema = (');

    if (columns.isNotEmpty) {
      columns.forEach((name, type) {
        final colClass = _mapTypeToColumnClass(type);
        final colName = toSnakeCase(name);
        final schemaKey = toCamelCase(name);
        buffer.writeln("    $schemaKey: $colClass('$colName'),");
      });
    }

    buffer.writeln('  );');
    buffer.writeln();

    columns.forEach((name, type) {
      final dartType = _mapTypeToDartType(type);
      final dbName = toSnakeCase(name);
      final schemaKey = toCamelCase(name);
      final propertyName = toCamelCase(name);

      buffer.writeln("  /// Accessor for [$propertyName] (DB: $dbName)");
      buffer.writeln("  $dartType get $propertyName => get($className.schema.$schemaKey);");
      buffer.writeln("  set $propertyName($dartType value) => set($className.schema.$schemaKey, value);");
      buffer.writeln();
    });

    buffer.writeln('  static List<Column> get columns => [');
    columns.forEach((name, _) {
       final schemaKey = toCamelCase(name);
       buffer.writeln('    $className.schema.$schemaKey,');
    });
    buffer.writeln('  ];');

    buffer.writeln('}');
    return buffer.toString();
  }

  String _mapTypeToColumnClass(String type) {
    switch (type) {
      case 'int': return 'IntColumn';
      case 'double': return 'DoubleColumn';
      case 'bool': return 'BoolColumn';
      case 'datetime': return 'DateTimeColumn';
      case 'json': return 'JsonColumn';
      case 'string':
      default: return 'TextColumn';
    }
  }

  String _mapTypeToDartType(String type) {
    switch (type) {
      case 'int': return 'int';
      case 'double': return 'double';
      case 'bool': return 'bool';
      case 'datetime': return 'DateTime';
      case 'json': return 'dynamic';
      case 'string':
      default: return 'String';
    }
  }
}