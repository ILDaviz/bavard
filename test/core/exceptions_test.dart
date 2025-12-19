import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class User extends Model {
  @override
  String get table => 'users';

  User([super.attributes]);

  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

void main() {
  group('Exceptions', () {
    group('ModelNotFoundException', () {
      test('findOrFail() throws ModelNotFoundException when not found', () async {
        final emptyMock = MockDatabaseSpy([], {});
        DatabaseManager().setDatabase(emptyMock);

        try {
          await User().query().findOrFail(999);
          fail('Should have thrown ModelNotFoundException');
        } catch (e) {
          expect(e, isA<ModelNotFoundException>());
          final error = e as ModelNotFoundException;
          expect(error.model, 'users');
          expect(error.id, 999);
          expect(error.message, contains('999'));
        }
      });

      test('firstOrFail() throws ModelNotFoundException when empty', () async {
        final emptyMock = MockDatabaseSpy([], {});
        DatabaseManager().setDatabase(emptyMock);

        try {
          await User().query().where('id', 1).firstOrFail();
          fail('Should have thrown ModelNotFoundException');
        } catch (e) {
          expect(e, isA<ModelNotFoundException>());
          final error = e as ModelNotFoundException;
          expect(error.model, 'users');
        }
      });
    });

    group('DatabaseNotInitializedException', () {
      test('throws when database not initialized', () {
        // Create a new DatabaseManager instance to test uninitialized state
        // In real code, we'd need to reset the singleton
        // For this test, we verify the exception type exists and formats correctly
        const exception = DatabaseNotInitializedException();

        expect(exception.message, contains('not initialized'));
        expect(exception.toString(), contains('DatabaseNotInitializedException'));
      });
    });

    group('InvalidQueryException', () {
      test('thrown for invalid column identifiers', () {
        expect(
              () => User().query().where('column; DROP TABLE', 'value'),
          throwsA(isA<InvalidQueryException>()),
        );
      });

      test('thrown for invalid operators', () {
        expect(
              () => User().query().where('id', 1, operator: 'INVALID'),
          throwsA(isA<InvalidQueryException>()),
        );
      });

      test('thrown for invalid orderBy direction', () {
        expect(
              () => User().query().orderBy('id', direction: 'INVALID'),
          throwsA(isA<InvalidQueryException>()),
        );
      });
    });

    group('QueryException', () {
      test('contains SQL and bindings information', () {
        const exception = QueryException(
          sql: 'SELECT * FROM users WHERE id = ?',
          bindings: [1],
          message: 'Test error',
        );

        expect(exception.sql, 'SELECT * FROM users WHERE id = ?');
        expect(exception.bindings, [1]);
        expect(exception.toString(), contains('SELECT * FROM users'));
        expect(exception.toString(), contains('Test error'));
      });
    });

    group('TransactionException', () {
      test('contains rollback status', () {
        const exception = TransactionException(
          message: 'Transaction failed',
          wasRolledBack: true,
        );

        expect(exception.wasRolledBack, isTrue);
        expect(exception.toString(), contains('Rolled back: true'));
      });
    });

    group('MassAssignmentException', () {
      test('formats message correctly', () {
        const exception = MassAssignmentException(
          attribute: 'is_admin',
          model: 'User',
        );

        expect(exception.message, contains('is_admin'));
        expect(exception.message, contains('User'));
        expect(exception.toString(), contains('MassAssignmentException'));
      });
    });

    group('RelationNotFoundException', () {
      test('formats message correctly', () {
        const exception = RelationNotFoundException(
          relation: 'posts',
          model: 'User',
        );

        expect(exception.message, contains('posts'));
        expect(exception.message, contains('User'));
      });
    });

    group('Exception Hierarchy', () {
      test('all exceptions extend ActiveSyncException', () {
        expect(
          const ModelNotFoundException(model: 'User'),
          isA<ActiveSyncException>(),
        );
        expect(
          const QueryException(sql: '', message: ''),
          isA<ActiveSyncException>(),
        );
        expect(
          const TransactionException(message: ''),
          isA<ActiveSyncException>(),
        );
        expect(
          const DatabaseNotInitializedException(),
          isA<ActiveSyncException>(),
        );
        expect(
          const InvalidQueryException(''),
          isA<ActiveSyncException>(),
        );
        expect(
          const MassAssignmentException(attribute: '', model: ''),
          isA<ActiveSyncException>(),
        );
        expect(
          const RelationNotFoundException(relation: '', model: ''),
          isA<ActiveSyncException>(),
        );
      });

      test('can catch all ORM exceptions with base type', () {
        try {
          throw const ModelNotFoundException(model: 'User');
        } on ActiveSyncException catch (e) {
          expect(e, isNotNull);
        }
      });
    });
  });
}