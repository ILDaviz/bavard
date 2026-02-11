import 'dart:io';
import 'package:bavard_cli/src/commands/make_pivot_command.dart';
import 'package:test/test.dart';

void main() {
  group('MakePivotCommand', () {
    late Directory tempDir;
    late MakePivotCommand command;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('bavard_cli_pivot_test');
      command = MakePivotCommand();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('creates a pivot file with columns', () async {
      final exitCode = await command.run([
        'UserRole',
        '--columns=is_active:bool,created_at:datetime',
        '--path=${tempDir.path}',
      ]);

      expect(exitCode, 0);

      final file = File('${tempDir.path}/user_role.dart');
      expect(file.existsSync(), isTrue);

      // Check file content
      final content = file.readAsStringSync();
      expect(content, contains('class UserRole extends Pivot'));
      expect(content, contains('static const schema = ('));
      expect(content, contains('isActive: BoolColumn(\'is_active\'),'));
      expect(content, contains('bool get isActive => get(UserRole.schema.isActive);'));
      expect(content, contains('set isActive(bool value) => set(UserRole.schema.isActive, value);'));
      expect(content, contains("DateTime get createdAt => get(UserRole.schema.createdAt);"));

      // Columns List
      expect(content, contains("static List<Column> get columns => ["));
      expect(content, contains("UserRole.schema.isActive,"));
      expect(content, contains("UserRole.schema.createdAt,"));
    });

    test('creates an empty pivot if no columns provided', () async {
      final exitCode = await command.run([
        'TagPost',
        '--path=${tempDir.path}',
      ]);

      expect(exitCode, 0);

      final file = File('${tempDir.path}/tag_post.dart');
      final content = file.readAsStringSync();
      
      expect(content, contains('class TagPost extends Pivot'));
      expect(content, contains('static List<Column> get columns => ['));
      expect(content, contains('];'));
    });
  });
}