import 'package:flutter_test/flutter_test.dart';
import 'package:bavard/bavard.dart';
import '../mocks/moke_database.dart';

class HelperUser extends Model {
  @override
  String get table => 'users';

  HelperUser([super.attributes]);

  @override
  HelperUser fromMap(Map<String, dynamic> map) => HelperUser(map);

  @override
  Map<String, String> get casts => {
    'settings': 'json',
    'is_active': 'bool',
    'age': 'int',
    'score': 'double',
    'created_at': 'datetime',
  };
}

void main() {
  setUp(() {
    DatabaseManager().setDatabase(MockDatabaseSpy());
  });

  group('HasAttributeHelpers Mixin', () {
    test('Semantic helpers return correct types respecting casts', () {
      final user = HelperUser({
        'age': '25',
        'is_active': 1,
        'score': '99.5',
        'created_at': '2023-01-01T10:00:00.000',
        'name': 'David',
      });

      expect(user.integer('age'), isA<int>());
      expect(user.integer('age'), 25);

      expect(user.boolean('is_active'), isTrue);

      expect(user.doubleNum('score'), 99.5);

      expect(user.date('created_at'), isA<DateTime>());
      expect(user.date('created_at')?.year, 2023);

      expect(user.string('name'), 'David');
    });

    test('json() helper correctly decodes Map/List', () {
      final user = HelperUser({'settings': '{"theme":"dark"}'});

      final Map<String, dynamic>? settings = user.json('settings');

      expect(settings, isNotNull);
      expect(settings!['theme'], 'dark');
    });

    test('Operators [] and []= still work via mixin', () {
      final user = HelperUser();
      user['age'] = 30;
      expect(user.integer('age'), 30);
      expect(user['age'], 30);
    });
  });
}
