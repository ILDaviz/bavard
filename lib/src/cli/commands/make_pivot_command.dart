import 'dart:io';
import '../utils.dart';
import 'base_command.dart';

class MakePivotCommand extends BaseCommand {
  @override
  String get name => 'make:pivot';

  @override
  String get description => 'Create a new Bavard Pivot class for Many-to-Many relationships.';

  @override
  Future<int> run(List<String> args) async {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      printUsage();
      return 0;
    }

    final className = args[0];
    if (className.startsWith('-')) {
      print('Error: Pivot class name must be the first argument.');
      printUsage();
      return 1;
    }

    Map<String, String> columns = {};
    bool force = false;
    String? customPath;

    // Parse arguments
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
    
    // Determine output path
    String outputDir;
    if (customPath != null) {
      outputDir = customPath;
    } else {
      // Auto-discovery priority
      if (Directory('lib/models').existsSync()) {
        outputDir = 'lib/models';
      } else if (Directory('lib/src/models').existsSync()) {
        outputDir = 'lib/src/models';
      } else {
        outputDir = 'lib';
      }
    }

    // Ensure directory exists
    final dir = Directory(outputDir);
    if (!dir.existsSync()) {
      print("Creating directory: $outputDir");
      dir.createSync(recursive: true);
    }
    
    final filePath = '${dir.path}/$fileName';

    if (File(filePath).existsSync() && !force) {
      print('Error: File "$filePath" already exists. Use --force to overwrite.');
      return 1;
    }

    final content = _generatePivotContent(className, columns);

    File(filePath).writeAsStringSync(content);
    print('✅ Pivot class created successfully: $filePath');
    return 0;
  }

  @override
  void printUsage() {
    print('''
Description:
  $description

Usage:
  dart run bavard $name <Name> [options]

Options:
  --columns=<list>    Comma-separated list of pivot columns (name:type).
                      Types: string, int, double, bool, datetime, json.
  --path=<path>       Specify the output directory.
  --force             Overwrite existing file.
  -h, --help          Show this help message.

Examples:
  1. Basic Pivot:
     dart run bavard $name UserRole --columns=is_active:bool,created_at:datetime
''');
  }

  String _generatePivotContent(String className, Map<String, String> columns) {
    final buffer = StringBuffer();

    buffer.writeln("import 'package:bavard/bavard.dart';");
    buffer.writeln();
    buffer.writeln('class $className extends Pivot {');
    buffer.writeln('  $className(super.attributes);');

    // Getters/Setters
    if (columns.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  // ---------------------------------------------------------------------------');
      buffer.writeln('  // ACCESSORS');
      buffer.writeln('  // ---------------------------------------------------------------------------');
      columns.forEach((name, type) {
        final dartType = _mapTypeToDartType(type);
        final dbName = toSnakeCase(name);
        final dartName = toCamelCase(name);
        buffer.writeln("  $dartType? get $dartName => getAttribute<$dartType>('$dbName');");
        buffer.writeln("  set $dartName($dartType? value) => setAttribute('$dbName', value);");
      });
    }

    // Static Columns List
    if (columns.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('  // ---------------------------------------------------------------------------');
      buffer.writeln('  // COLUMNS');
      buffer.writeln('  // ---------------------------------------------------------------------------');
      buffer.writeln('  static const columns = [');
      columns.forEach((name, _) {
         buffer.writeln("    '${toSnakeCase(name)}',");
      });
      buffer.writeln('  ];');
    } else {
       buffer.writeln();
       buffer.writeln('  static const columns = <String>[];');
    }

    buffer.writeln('}');
    return buffer.toString();
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