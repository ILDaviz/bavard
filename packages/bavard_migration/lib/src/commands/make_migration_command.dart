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
    print('Usage: dart run bavard make:migration <name>');
  }

  @override
  Future<int> run(List<String> args) async {
    if (args.isEmpty) {
      print('Error: Migration name is required.');
      printUsage();
      return 1;
    }

    final name = args[0];
    final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14); // YYYYMMDDHHMMSS
    final filename = '${timestamp}_$name.dart';
    
    final dir = Directory('database/migrations');
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
