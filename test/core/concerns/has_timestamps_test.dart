import 'package:flutter_test/flutter_test.dart';
import 'package:bavard/bavard.dart';
import '../../mocks/moke_database.dart';
import 'package:bavard/src/core/concerns/has_timestamps.dart';

class TimestampUser extends Model with HasTimestamps {
  @override
  String get table => 'users';

  TimestampUser([super.attributes]);

  @override
  TimestampUser fromMap(Map<String, dynamic> map) => TimestampUser(map);

  @override
  Map<String, String> get casts => {
    'created_at': 'datetime',
    'updated_at': 'datetime',
  };
}

class CustomTimestampUser extends Model with HasTimestamps {
  @override
  String get table => 'users';

  @override
  String get createdAtColumn => 'date_created';

  @override
  String get updatedAtColumn => 'date_modified';

  CustomTimestampUser([super.attributes]);

  @override
  CustomTimestampUser fromMap(Map<String, dynamic> map) =>
      CustomTimestampUser(map);
}

class NoTimestampUser extends Model with HasTimestamps {
  @override
  String get table => 'users';

  @override
  bool get timestamps => false;

  NoTimestampUser([super.attributes]);

  @override
  NoTimestampUser fromMap(Map<String, dynamic> map) => NoTimestampUser(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {
      'last_insert_rowid': [
        {'id': 1},
      ],
      'FROM users': [
        {
          'id': 1,
          'name': 'David',
          'created_at': '2024-01-01T10:00:00.000',
          'updated_at': '2024-01-01T10:00:00.000',
        },
      ],
    });

    DatabaseManager().setDatabase(dbSpy);
  });

  group('HasTimestamps Mixin', () {
    test('INSERT sets created_at and updated_at automatically', () async {
      final user = TimestampUser({'name': 'David'});
      await user.save();

      final insertSql = dbSpy.history.firstWhere((sql) => sql.contains('INSERT INTO users'));

      expect(insertSql, contains('created_at'));
      expect(insertSql, contains('updated_at'));
    });

    test('UPDATE updates only updated_at', () async {
      final user = TimestampUser({
        'id': 1,
        'name': 'David',
        'created_at': DateTime(2024, 1, 1),
        'updated_at': DateTime(2024, 1, 1),
      });
      user.exists = true;
      user.syncOriginal();

      user.attributes['name'] = 'Romolo';

      await user.save();

      final updateSql =
      dbSpy.history.firstWhere((sql) => sql.contains('UPDATE users'));

      expect(updateSql, contains('updated_at = ?'));
      expect(updateSql, isNot(contains('created_at = ?')));
    });

    test('updated_at changes on every save', () async {
      final user = TimestampUser({
        'id': 1,
        'name': 'David',
        'created_at': DateTime(2024, 1, 1),
        'updated_at': DateTime(2024, 1, 1),
      });

      user.syncOriginal();

      await Future.delayed(const Duration(milliseconds: 10));
      await user.save();

      final updatedAt = user.date('updated_at');

      expect(updatedAt, isNotNull);
      expect(updatedAt!.isAfter(DateTime(2024, 1, 1)), isTrue);
    });

    test('timestamps can be disabled per model', () async {
      final user = NoTimestampUser({'name': 'No TS'});

      await user.save();

      final insertArgs = dbSpy.lastArgs!;

      final hasDateTime =
      insertArgs.any((v) => v is DateTime);

      expect(hasDateTime, isFalse);
    });

    test('created_at is not included in UPDATE statement', () async {
      final user = TimestampUser({
        'id': 1,
        'name': 'David',
        'created_at': DateTime(2024, 1, 1),
        'updated_at': DateTime(2024, 1, 1),
      });
      user.exists = true;
      user.syncOriginal();

      user.attributes['name'] = 'Updated';
      await user.save();

      final updateSql =
      dbSpy.history.firstWhere((sql) => sql.contains('UPDATE users'));

      expect(updateSql, isNot(contains('created_at')));
      expect(updateSql, contains('updated_at'));
    });
  });

  group('HasTimestamps Extended', () {
    test('created_at not overwritten if already set', () async {
      final existingDate = DateTime(2020, 5, 15);
      final user = TimestampUser({
        'name': 'David',
        'created_at': existingDate.toIso8601String(),
      });

      // Verifica che created_at sia preservato dopo onSaving
      await user.onSaving();

      // created_at dovrebbe essere quello originale, non uno nuovo
      final createdAtValue = user.attributes['created_at'];
      expect(createdAtValue, existingDate.toIso8601String());
    });

    test('updated_at always refreshed on save (even insert)', () async {
      final user = TimestampUser({'name': 'David'});

      await user.onSaving();

      // updated_at should be set to current time
      expect(user.attributes.containsKey('updated_at'), isTrue);
      expect(user.attributes['updated_at'], isNotNull);
    });

    test('timestamps disabled skips both columns', () async {
      final user = NoTimestampUser({'name': 'David'});

      await user.onSaving();

      // Con timestamps disabilitato, non dovrebbero essere aggiunti
      expect(user.attributes.containsKey('created_at'), isFalse);
      expect(user.attributes.containsKey('updated_at'), isFalse);
    });

    test('custom column names (createdAtColumn, updatedAtColumn)', () async {
      final user = CustomTimestampUser({'name': 'David'});

      await user.onSaving();

      // Dovrebbe usare i nomi custom
      expect(user.attributes.containsKey('date_created'), isTrue);
      expect(user.attributes.containsKey('date_modified'), isTrue);
      expect(user.attributes.containsKey('created_at'), isFalse);
      expect(user.attributes.containsKey('updated_at'), isFalse);
    });

    test('updated_at changes on every update', () async {
      final originalDate = DateTime(2024, 1, 1, 10, 0, 0);
      final user = TimestampUser({
        'id': 1,
        'name': 'David',
        'created_at': originalDate.toIso8601String(),
        'updated_at': originalDate.toIso8601String(),
      });
      user.exists = true;
      user.syncOriginal();

      await Future.delayed(const Duration(milliseconds: 10));

      user.attributes['name'] = 'Updated';
      await user.onSaving();

      // updated_at dovrebbe essere più recente
      final updatedAt = user.attributes['updated_at'];
      expect(updatedAt, isNot(equals(originalDate.toIso8601String())));
    });
  });
}