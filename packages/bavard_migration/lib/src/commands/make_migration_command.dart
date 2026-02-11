import 'dart:io';
import 'package:bavard_cli/src/commands/base_command.dart'; // Direct import from src as dependent package
import 'package:path/path.dart' as p;

class MakeMigrationCommand extends BaseCommand {
  @override
  String get name => 'make:migration';

  @override
  String get description => 'Create a new migration file.';

  @override
  void printUsage() {
    print('Usage: dart run bavard make:migration <name> [--path=<dir>]');
  }

  @override
  Future<int> run(List<String> args) async {
    String? pathArg;
    final otherArgs = <String>[];
    
    for (final arg in args) {
      if (arg.startsWith('--path=')) {
        pathArg = arg.substring(7);
      } else {
        otherArgs.add(arg);
      }
    }

    if (otherArgs.isEmpty) {
      print('Error: Migration name is required.');
      printUsage();
      return 1;
    }

    final name = otherArgs[0];
    final migrationsPath = pathArg ?? 'database/migrations';
    
    final now = DateTime.now();
    final timestamp = "${now.year}_"
        "${now.month.toString().padLeft(2, '0')}_"
        "${now.day.toString().padLeft(2, '0')}_"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}"
        "${now.second.toString().padLeft(2, '0')}";
        
    final filename = '${timestamp}_$name.dart';
    
    final dir = Directory(migrationsPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final filePath = p.join(dir.path, filename);
    final className = _toPascalCase(name);

    final content = '''
import 'package:bavard_migration/bavard_migration.dart';

class $className extends Migration {
  @override
  Future<void> up(Schema schema) async {
    // await schema.create('table_name', (table) {
    //   table.id();
    //   table.timestamps();
    // });
  }

  @override
  Future<void> down(Schema schema) async {
    // await schema.dropIfExists('table_name');
  }
}
''';

    File(filePath).writeAsStringSync(content);
    print('Created migration: $filePath');
    return 0;
  }

  String _toPascalCase(String input) {
    return input.split('_').map((s) {
      if (s.isEmpty) return '';
      return s[0].toUpperCase() + s.substring(1);
    }).join('');
  }
}
