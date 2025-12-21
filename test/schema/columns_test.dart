import 'package:test/test.dart';
import 'package:bavard/schema.dart';

enum UserRole { admin, editor, guest }

void main() {
  group('Column Base Methods', () {
    const col = TextColumn('status');

    test('equals', () {
      final condition = col.equals('active');
      expect(condition.column, 'status');
      expect(condition.operator, '=');
      expect(condition.value, 'active');
    });

    test('notEquals', () {
      final condition = col.notEquals('inactive');
      expect(condition.column, 'status');
      expect(condition.operator, '!=');
      expect(condition.value, 'inactive');
    });

    test('isNull', () {
      final condition = col.isNull();
      expect(condition.column, 'status');
      expect(condition.operator, 'IS');
      expect(condition.value, null);
    });

    test('isNotNull', () {
      final condition = col.isNotNull();
      expect(condition.column, 'status');
      expect(condition.operator, 'IS NOT');
      expect(condition.value, null);
    });

    test('inList', () {
      final values = ['active', 'pending'];
      final condition = col.inList(values);
      expect(condition.column, 'status');
      expect(condition.operator, 'IN');
      expect(condition.value, values);
    });

    test('notInList', () {
      final values = ['banned', 'deleted'];
      final condition = col.notInList(values);
      expect(condition.column, 'status');
      expect(condition.operator, 'NOT IN');
      expect(condition.value, values);
    });
  });

  group('TextColumn', () {
    const col = TextColumn('username');

    test('contains', () {
      final condition = col.contains('dav');
      expect(condition.column, 'username');
      expect(condition.operator, 'LIKE');
      expect(condition.value, '%dav%');
    });

    test('startsWith', () {
      final condition = col.startsWith('admin');
      expect(condition.column, 'username');
      expect(condition.operator, 'LIKE');
      expect(condition.value, 'admin%');
    });

    test('endsWith', () {
      final condition = col.endsWith('_test');
      expect(condition.column, 'username');
      expect(condition.operator, 'LIKE');
      expect(condition.value, '%_test');
    });
  });

  group('IntColumn', () {
    const col = IntColumn('age');

    test('greaterThan', () {
      final condition = col.greaterThan(18);
      expect(condition.column, 'age');
      expect(condition.operator, '>');
      expect(condition.value, 18);
    });

    test('between', () {
      final condition = col.between(20, 30);
      expect(condition.column, 'age');
      expect(condition.operator, 'BETWEEN');
      expect(condition.value, [20, 30]);
    });
  });

  group('BoolColumn', () {
    const col = BoolColumn('is_active');

    test('isTrue', () {
      final condition = col.isTrue();
      expect(condition.column, 'is_active');
      expect(condition.operator, '=');
      expect(condition.value, 1);
    });

    test('isFalse', () {
      final condition = col.isFalse();
      expect(condition.column, 'is_active');
      expect(condition.operator, '=');
      expect(condition.value, 0);
    });
  });

  group('DateTimeColumn', () {
    const col = DateTimeColumn('created_at');
    final date = DateTime(2025, 12, 25, 10, 0, 0);

    test('after', () {
      final condition = col.after(date);
      expect(condition.column, 'created_at');
      expect(condition.operator, '>');
      expect(condition.value, date.toIso8601String());
    });

    test('between', () {
      final end = date.add(Duration(days: 1));
      final condition = col.between(date, end);
      expect(condition.operator, 'BETWEEN');
      expect(condition.value, [date, end]);
    });
  });

  group('EnumColumn', () {
    const col = EnumColumn<UserRole>('role');

    test('equals (uses name)', () {
      final condition = col.equals(UserRole.admin);
      expect(condition.operator, '=');
      expect(condition.value, 'admin');
    });

    test('inList (uses names)', () {
      final condition = col.inList([UserRole.editor, UserRole.guest]);
      expect(condition.operator, 'IN');
      expect(condition.value, ['editor', 'guest']);
    });
  });

  group('JsonColumn & JsonPathColumn', () {
    const col = JsonColumn('metadata');

    test('creates JsonPathColumn via key()', () {
      final pathCol = col.key<String>('settings');
      expect(pathCol.toString(), "json_extract(metadata, '\$.settings')");
    });

    test('nested path chaining', () {
      final pathCol = col.key<dynamic>('settings').key<String>('theme');
      expect(pathCol.toString(), "json_extract(metadata, '\$.settings.theme')");
    });

    test('array index chaining', () {
      final pathCol = col.key<dynamic>('tags').index<String>(0);
      expect(pathCol.toString(), "json_extract(metadata, '\$.tags[0]')");
    });

    test('operators on JsonPathColumn', () {
      final pathCol = col.key<int>('login_count');
      final condition = pathCol.greaterThan(5);

      expect(condition.column, "json_extract(metadata, '\$.login_count')");
      expect(condition.operator, '>');
      expect(condition.value, 5);
    });
  });
}