import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';
import '../../mocks/moke_database.dart';
import 'package:active_sync/src/core/concerns/has_uuids.dart';

class UuidUser extends Model with HasUuids {
  @override
  String get table => 'users';

  UuidUser([super.attributes]);

  @override
  UuidUser fromMap(Map<String, dynamic> map) => UuidUser(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy([], {
      'FROM users': [
        {'id': 'will-be-replaced', 'name': 'David'}
      ],
    });
    DatabaseManager().setDatabase(dbSpy);
  });

  group('HasUuids Mixin', () {
    test('UUID generated on first save', () async {
      final user = UuidUser({'name': 'David'});

      expect(user.id, isNull);

      await user.save();

      expect(user.id, isNotNull);
      expect(user.id, isA<String>());
      expect((user.id as String).length, greaterThan(0));
    });

    test('UUID not overwritten if already set', () async {
      final customUuid = 'my-custom-uuid-123';

      final mockDb = MockDatabaseSpy([], {
        'FROM users': [
          {'id': customUuid, 'name': 'David'}
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final user = UuidUser({'id': customUuid, 'name': 'David'});

      await user.save();

      final insertSql =
      mockDb.history.firstWhere((s) => s.contains('INSERT'), orElse: () => '');
      expect(insertSql, contains('id'));

      expect(user.id, customUuid);
    });

    test('UUID format is valid v4 pattern', () async {
      final user = UuidUser({'name': 'David'});

      await user.onSaving();

      final generatedId = user.id as String?;

      // UUID v4 deve avere 36 caratteri (8-4-4-4-12)
      expect(generatedId, isNotNull);
      expect(generatedId!.length, 36);
      expect(generatedId.contains('-'), isTrue);

      // Verifica pattern UUID v4: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(generatedId), isTrue);
    });

    test('incrementing returns false', () {
      final user = UuidUser();
      expect(user.incrementing, isFalse);
    });

    test('multiple saves keep same UUID', () async {
      final user = UuidUser({'name': 'David'});

      await user.onSaving();
      final firstId = user.id;

      expect(firstId, isNotNull);

      user.exists = true;
      user.syncOriginal();

      await user.onSaving();

      expect(user.id, firstId);
    });

    test('each new model generates different UUID', () async {
      final user1 = UuidUser({'name': 'User 1'});
      final user2 = UuidUser({'name': 'User 2'});

      await user1.onSaving();
      await user2.onSaving();

      expect(user1.id, isNotNull);
      expect(user2.id, isNotNull);
      expect(user1.id, isNot(equals(user2.id)));
    });
  });
}