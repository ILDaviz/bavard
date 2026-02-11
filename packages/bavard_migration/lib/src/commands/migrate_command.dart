import 'dart:io';
import 'package:bavard_cli/src/commands/base_command.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class MigrateCommand extends BaseCommand {
  @override
  String get name => 'migrate';

  @override
  String get description => 'Run the database migrations.';

  @override
  void printUsage() {
    print('Usage: dart run bavard migrate [--path=<dir>]');
    print('Requires lib/config/database.dart exporting "Future<DatabaseAdapter> getDatabaseAdapter()".');
  }

  @override
  Future<int> run(List<String> args) async {
    String? pathArg;
    for (final arg in args) {
      if (arg.startsWith('--path=')) {
        pathArg = arg.substring(7);
      }
    }
    final migrationsPath = pathArg ?? 'database/migrations';

    final migrationsDir = Directory(migrationsPath);
    if (!migrationsDir.existsSync()) {
      print('No migrations found in $migrationsPath.');
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

    if (migrationFiles.isEmpty) {
      print('No migration files found.');
      return 0;
    }

    final runnerDir = Directory('.dart_tool/bavard');
    if (!runnerDir.existsSync()) {
      runnerDir.createSync(recursive: true);
    }
    final runnerFile = File(p.join(runnerDir.path, 'migrate_runner.dart'));

    final imports = StringBuffer();
    final registry = StringBuffer();

    imports.writeln("import 'package:bavard/bavard.dart';");
    imports.writeln("import 'package:bavard_migration/bavard_migration.dart';");
    imports.writeln("import 'package:$packageName/config/database.dart' as db_config;");

    for (var i = 0; i < migrationFiles.length; i++) {
      final file = migrationFiles[i];
      final filename = p.basename(file.path);
      final importAlias = 'm$i';
      
      final relativePath = migrationsPath.replaceAll(r'\', '/');
      imports.writeln("import '../../$relativePath/$filename' as $importAlias;");
      
      final content = file.readAsStringSync();
      final classMatch = RegExp(r'class\s+(\w+)\s+extends\s+Migration').firstMatch(content);
      if (classMatch == null) {
        print('Warning: Could not find Migration class in $filename. Skipping.');
        continue;
      }
      final className = classMatch.group(1);

      registry.writeln("    MigrationRegistryEntry($importAlias.$className(), '$filename'),");
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

    print('Running migrations...');
    await migrator.runUp(migrations);
    print('Done.');
    
  } catch (e, s) {
    print('Error during migration: \$e');
    print(s);
    exit(1);
  }
}
''';

    runnerFile.writeAsStringSync(script);

    print('Generated migration runner at ${runnerFile.path}');
    print('Executing...');

    final result = await Process.run('dart', ['run', runnerFile.path]);
    
    if (result.stdout.toString().isNotEmpty) print(result.stdout);
    if (result.stderr.toString().isNotEmpty) print(result.stderr);

    if (result.exitCode != 0) {
        print('Migration failed.');
        if (result.stderr.toString().contains("URI doesn't exist")) {
            print('\nHint: Ensure "lib/config/database.dart" exists and exports "Future<DatabaseAdapter> getDatabaseAdapter()".');
        }
        return result.exitCode;
    }

    return 0;
  }
}
