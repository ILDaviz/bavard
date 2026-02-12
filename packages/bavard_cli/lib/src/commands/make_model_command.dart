import 'dart:io';
import '../utils.dart';
import 'base_command.dart';

class MakeModelCommand extends BaseCommand {
  @override
  String get name => 'make:model';

  @override
  String get description => 'Create a new Bavard model class.';

  @override
  Future<int> run(List<String> args) async {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      printUsage();
      return 0;
    }

    final className = args[0];
    if (className.startsWith('-')) {
      printError('Model name must be the first argument.');
      printUsage();
      return 1;
    }

    String? tableName;
    Map<String, String> columns = {};
    bool force = false;
    String? customPath;

    for (var i = 1; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--table=')) {
        tableName = arg.split('=')[1];
      } else if (arg.startsWith('--columns=')) {
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

    tableName ??= pluralize(toSnakeCase(className));
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

    final content = _generateModelContent(className, tableName, columns);

    File(filePath).writeAsStringSync(content);
    printSuccess('✅ Model created successfully: $filePath');
    return 0;
  }

  @override
  void printUsage() {
    print('${colorized('Description:', bold)}');
    print('  $description\n');
    print('${colorized('Usage:', bold)}');
    print('  dart run bavard $name <Name> [options]\n');
    print('${colorized('Options:', bold)}');
    print(
      '  ${colorized('--table=<name>', green)}      Specify the database table name.',
    );
    print(
      '  ${colorized('--columns=<list>', green)}    Comma-separated list of columns (name:type).',
    );
    print(
      '                      Types: string, int, double, bool, datetime, json.',
    );
    print(
      '  ${colorized('--path=<path>', green)}       Specify the output directory (e.g., --path=lib/data/models).',
    );
    print(
      '  ${colorized('--force', green)}             Overwrite existing file.',
    );
    print(
      '  ${colorized('-h, --help', green)}          Show this help message.\n',
    );
    print('${colorized('Examples:', bold)}');
    print('  1. Basic Model:');
    print('     dart run bavard $name Product\n');
    print('  2. Model with Schema:');
    print(
      '     dart run bavard $name User --columns=name:string,age:int,active:bool\n',
    );
    print('  3. Custom Table & Path:');
    print(
      '     dart run bavard $name Category --table=product_categories --path=lib/features/shop/models',
    );
  }

  String _generateModelContent(
    String className,
    String tableName,
    Map<String, String> columns,
  ) {
    final buffer = StringBuffer();

    buffer.writeln("import 'package:bavard/bavard.dart';");
    buffer.writeln("import 'package:bavard/schema.dart';");
    buffer.writeln();
    buffer.writeln('class $className extends Model {');
    buffer.writeln("  @override");
    buffer.writeln("  String get table => '$tableName';");
    buffer.writeln();
    buffer.writeln('  $className([super.attributes]);');
    buffer.writeln();
    buffer.writeln("  @override");
    buffer.writeln(
      "  $className fromMap(Map<String, dynamic> map) => $className(map);",
    );

    if (columns.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        '  // ---------------------------------------------------------------------------',
      );
      buffer.writeln('  // SCHEMA');
      buffer.writeln(
        '  // ---------------------------------------------------------------------------',
      );
      buffer.writeln();
      buffer.writeln('  static const schema = (');
      columns.forEach((name, type) {
        final colClass = _mapTypeToColumnClass(type);
        final colName = toSnakeCase(name);
        final schemaKey = toCamelCase(name);
        buffer.writeln("    $schemaKey: $colClass('$colName'),");
      });
      buffer.writeln('  );');
    }

    if (columns.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        '  // ---------------------------------------------------------------------------',
      );
      buffer.writeln('  // ACCESSORS');
      buffer.writeln(
        '  // ---------------------------------------------------------------------------',
      );
      columns.forEach((name, type) {
        final dartType = _mapTypeToDartType(type);
        final dbName = toSnakeCase(name);
        final dartName = toCamelCase(name);
        buffer.writeln(
          "  $dartType? get $dartName => getAttribute<$dartType>('$dbName');",
        );
        buffer.writeln(
          "  set $dartName($dartType? value) => setAttribute('$dbName', value);",
        );
      });
    }

    final castColumns = columns.entries
        .where((e) => _needsCast(e.value))
        .toList();

    if (castColumns.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        '  // ---------------------------------------------------------------------------',
      );
      buffer.writeln('  // CASTS');
      buffer.writeln(
        '  // ---------------------------------------------------------------------------',
      );
      buffer.writeln();
      buffer.writeln("  @override");
      buffer.writeln("  Map<String, String> get casts => {");
      for (var entry in castColumns) {
        final dbName = toSnakeCase(entry.key);
        buffer.writeln("    '$dbName': '${entry.value}',");
      }
      buffer.writeln("  };");
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _mapTypeToColumnClass(String type) {
    switch (type) {
      case 'int':
        return 'IntColumn';
      case 'double':
        return 'DoubleColumn';
      case 'bool':
        return 'BoolColumn';
      case 'datetime':
        return 'DateTimeColumn';
      case 'json':
        return 'JsonColumn';
      case 'string':
      default:
        return 'TextColumn';
    }
  }

  String _mapTypeToDartType(String type) {
    switch (type) {
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      case 'datetime':
        return 'DateTime';
      case 'json':
        return 'dynamic';
      case 'string':
      default:
        return 'String';
    }
  }

  bool _needsCast(String type) {
    return ['int', 'double', 'bool', 'datetime', 'json'].contains(type);
  }
}
