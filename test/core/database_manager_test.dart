import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

void main() {
  group('DatabaseManager', () {
    test('singleton returns same instance', () {
      final instance1 = DatabaseManager();
      final instance2 = DatabaseManager();

      expect(identical(instance1, instance2), isTrue);
    });

    test('setDatabase replaces existing adapter', () async {
      final firstAdapter = MockDatabaseSpy([], {
        'FROM test': [
          {'id': 1}
        ],
      });
      final secondAdapter = MockDatabaseSpy([], {
        'FROM test': [
          {'id': 2}
        ],
      });

      DatabaseManager().setDatabase(firstAdapter);
      expect(DatabaseManager().db, firstAdapter);

      DatabaseManager().setDatabase(secondAdapter);
      expect(DatabaseManager().db, secondAdapter);
    });

    test('db getter returns set adapter', () {
      final adapter = MockDatabaseSpy();
      DatabaseManager().setDatabase(adapter);

      expect(DatabaseManager().db, adapter);
    });

    test('inTransaction returns false by default', () {
      DatabaseManager().setDatabase(MockDatabaseSpy());

      expect(DatabaseManager().inTransaction, isFalse);
    });

    test('activeTransaction returns null by default', () {
      DatabaseManager().setDatabase(MockDatabaseSpy());

      expect(DatabaseManager().activeTransaction, isNull);
    });
  });
}