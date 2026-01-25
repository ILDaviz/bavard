import 'dart:io';
import 'package:bavard_cli/src/commands/base_command.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class RollbackCommand extends BaseCommand {
  @override
  String get name => 'migrate:rollback';

  @override
  String get description => 'Rollback the last database migration batch.';

  @override
  void printUsage() {
    print('Usage: dart run bavard migrate:rollback');
    print('Requires lib/config/database.dart exporting "Future<DatabaseAdapter> getDatabaseAdapter()".');
  }

  @override
  Future<int> run(List<String> args) async {
    final migrationsDir = Directory('database/migrations');
    if (!migrationsDir.existsSync()) {
      print('No migrations found in database/migrations.');
      return 0;
    }

    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('Error: pubspec.yaml not found.');
      return 1;
    }

    final pubspec = loadYaml(pubspecFile.readAsStringSync());
    final packageName = pubspec['name'];

    if (packageName == null) {
      print('Error: Could not determine package name from pubspec.yaml.');
      return 1;
    }

    final migrationFiles = migrationsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

    // Generate runner script
    final runnerDir = Directory('.dart_tool/bavard');
    if (!runnerDir.existsSync()) {
      runnerDir.createSync(recursive: true);
    }
    final runnerFile = File(p.join(runnerDir.path, 'rollback_runner.dart'));

    final imports = StringBuffer();
    final registry = StringBuffer();

    imports.writeln("import 'package:bavard/bavard.dart';");
    imports.writeln("import 'package:bavard_migration/bavard_migration.dart';");
    imports.writeln("import 'package:$packageName/config/database.dart' as db_config;");

    for (var i = 0; i < migrationFiles.length; i++) {
      final file = migrationFiles[i];
      final filename = p.basename(file.path);
      final importAlias = 'm$i';
      imports.writeln("import '../../database/migrations/$filename' as $importAlias;");
      
      final content = file.readAsStringSync();
      final classMatch = RegExp(r'class\s+(\w+)\s+extends\s+Migration').firstMatch(content);
      if (classMatch == null) {
        continue;
      }
      final className = classMatch.group(1);

      registry.writeln("    MigrationRegistryEntry('$filename', $importAlias.$className()),");
    }

    final script = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
$imports

void main() async {
  try {
    print('Initializing database connection...');
    final adapter = await db_config.getDatabaseAdapter();
    DatabaseManager().setDatabase(adapter);
    
    final repo = MigrationRepository(adapter);
    final migrator = Migrator(adapter, repo);

    final migrations = [
$registry
    ];

    print('Rolling back migrations...');
    await migrator.runDown(migrations);
    print('Done.');
    
  } catch (e, s) {
    print('Error during rollback: \$e');
    print(s);
    exit(1);
  }
}
''';

    runnerFile.writeAsStringSync(script);

    print('Generated rollback runner at ${runnerFile.path}');
    print('Executing...');

    final result = await Process.run('dart', ['run', runnerFile.path]);
    
    if (result.stdout.toString().isNotEmpty) print(result.stdout);
    if (result.stderr.toString().isNotEmpty) print(result.stderr);

    if (result.exitCode != 0) {
        print('Rollback failed.');
        return result.exitCode;
    }

    return 0;
  }
}
