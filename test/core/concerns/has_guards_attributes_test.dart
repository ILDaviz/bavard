import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class WhiteListUser extends Model {
  @override
  String get table => 'users';

  @override
  List<String> get fillable => ['name', 'email', 'settings'];

  @override
  Map<String, String> get casts => {'settings': 'json'};

  WhiteListUser([super.attributes]);
  @override
  WhiteListUser fromMap(Map<String, dynamic> map) => WhiteListUser(map);
}

class BlackListUser extends Model {
  @override
  String get table => 'users';

  @override
  List<String> get guarded => ['is_admin', 'secret_key', 'id'];

  BlackListUser([super.attributes]);
  @override
  BlackListUser fromMap(Map<String, dynamic> map) => BlackListUser(map);
}

class DefaultSecureUser extends Model {
  @override
  String get table => 'users';

  DefaultSecureUser([super.attributes]);
  @override
  DefaultSecureUser fromMap(Map<String, dynamic> map) => DefaultSecureUser(map);
}

void main() {
  setUp(() {
    HasGuardsAttributes.reguard();
    DatabaseManager().setDatabase(MockDatabaseSpy());
  });

  group('GuardsAttributes (Mass Assignment)', () {
    test('fill() only allows attributes in fillable array', () {
      final user = WhiteListUser();

      final input = {
        'name': 'David',
        'email': 'david@test.com',
        'is_admin': true,
        'role': 'editor',
      };

      user.fill(input);

      expect(user.attributes['name'], 'David');
      expect(user.attributes['email'], 'david@test.com');

      expect(user.attributes.containsKey('is_admin'), isFalse);
      expect(user.attributes.containsKey('role'), isFalse);
    });

    test('fill() blocks attributes in guarded array', () {
      final user = BlackListUser();

      final input = {
        'name': 'Romolo',
        'is_admin': true,
        'secret_key': '12345',
        'id': 99,
      };

      user.fill(input);

      expect(user.attributes['name'], 'Romolo');
      expect(user.attributes.containsKey('is_admin'), isFalse);
      expect(user.attributes.containsKey('secret_key'), isFalse);
      expect(user.attributes.containsKey('id'), isFalse);
    });

    test('Models are totally guarded by default if nothing is configured', () {
      final user = DefaultSecureUser();

      user.fill({'name': 'Hacker', 'admin': true});

      expect(user.attributes, isEmpty);
    });

    test('fill() uses setAttribute internally respecting Casts', () {
      final user = WhiteListUser();

      final input = {
        'settings': {'theme': 'dark', 'notifications': true},
      };

      user.fill(input);

      expect(user.attributes['settings'], isA<String>());
      expect(user.attributes['settings'], contains('"theme":"dark"'));
    });

    test('forceFill() bypasses protection', () {
      final user = WhiteListUser();

      final input = {'name': 'David', 'is_admin': true};

      user.forceFill(input);

      expect(user.attributes['name'], 'David');
      expect(user.attributes['is_admin'], true);
    });

    test('unguard() disables protection globally', () {
      HasGuardsAttributes.unguard();

      final user = WhiteListUser();

      user.fill({'is_admin': true});

      expect(user.attributes['is_admin'], true);

      HasGuardsAttributes.reguard();

      final user2 = WhiteListUser();
      user2.fill({'is_admin': true});

      expect(user2.attributes.containsKey('is_admin'), isFalse);
    });
  });
}
