import 'dart:io';
import 'package:bavard/src/cli/commands/make_model_command.dart';
import 'package:test/test.dart';

void main() {
  group('MakeModelCommand', () {
    late Directory tempDir;
    late MakeModelCommand command;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('bavard_cli_test');
      command = MakeModelCommand();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('creates a basic model file', () async {
      final exitCode = await command.run([
        'Product',
        '--path=${tempDir.path}',
      ]);

      expect(exitCode, 0);

      final file = File('${tempDir.path}/product.dart');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('class Product extends Model'));
      expect(content, contains("String get table => 'products';"));
    });

    test('creates a model with custom table name', () async {
      final exitCode = await command.run([
        'Category',
        '--table=my_categories',
        '--path=${tempDir.path}',
      ]);

      expect(exitCode, 0);

      final file = File('${tempDir.path}/category.dart');
      final content = file.readAsStringSync();
      expect(content, contains("String get table => 'my_categories';"));
    });

    test('creates a model with columns, schema, and casts', () async {
      final exitCode = await command.run([
        'User',
        '--columns=name:string,age:int,isActive:bool',
        '--path=${tempDir.path}',
      ]);

      expect(exitCode, 0);

      final file = File('${tempDir.path}/user.dart');
      final content = file.readAsStringSync();

      // Schema
      expect(content, contains('TextColumn(\'name\')'));
      expect(content, contains('IntColumn(\'age\')'));
      expect(content, contains('BoolColumn(\'is_active\')'));

      // Accessors
      expect(content, contains("String? get name => getAttribute<String>('name');"));
      expect(content, contains("int? get age => getAttribute<int>('age');"));
      expect(content, contains("bool? get isActive => getAttribute<bool>('is_active');"));

      // Casts
      expect(content, contains("Map<String, String> get casts => {"));
      expect(content, contains("'age': 'int'"));
      expect(content, contains("'is_active': 'bool'"));
      // String does not need casting
      expect(content, isNot(contains("'name': 'string'")));
    });

    test('fails if file exists and force is not used', () async {
      final filePath = '${tempDir.path}/product.dart';
      File(filePath).createSync();

      final exitCode = await command.run([
        'Product',
        '--path=${tempDir.path}',
      ]);

      expect(exitCode, 1);
    });

    test('overwrites if force is used', () async {
      final filePath = '${tempDir.path}/product.dart';
      File(filePath).writeAsStringSync('// Old Content');

      final exitCode = await command.run([
        'Product',
        '--path=${tempDir.path}',
        '--force',
      ]);

      expect(exitCode, 0);
      final content = File(filePath).readAsStringSync();
      expect(content, contains('class Product extends Model'));
    });
  });
}
