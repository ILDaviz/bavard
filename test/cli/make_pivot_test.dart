import 'dart:io';
import 'package:bavard/src/cli/commands/make_pivot_command.dart';
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

      final content = file.readAsStringSync();
      expect(content, contains('class UserRole extends Pivot'));
      
      // Accessors
      expect(content, contains("bool? get isActive => getAttribute<bool>('is_active');"));
      expect(content, contains("DateTime? get createdAt => getAttribute<DateTime>('created_at');"));

      // Columns List
      expect(content, contains("static const columns = ["));
      expect(content, contains("'is_active',"));
      expect(content, contains("'created_at',"));
    });

    test('creates an empty pivot if no columns provided', () async {
      final exitCode = await command.run([
        'TagPost',
        '--path=${tempDir.path}',
      ]);

      expect(exitCode, 0);

      final file = File('${tempDir.path}/tag_post.dart');
      final content = file.readAsStringSync();
      expect(content, contains('static const columns = <String>[];'));
    });
  });
}
