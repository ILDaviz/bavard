import 'package:active_sync/src/core/concerns/has_guards_attributes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:active_sync/bavard.dart';
import '../../mocks/moke_database.dart';

class FillableUser extends Model {
  @override
  String get table => 'users';

  @override
  List<String> get fillable => ['name', 'email', 'bio'];

  FillableUser([super.attributes]);

  @override
  FillableUser fromMap(Map<String, dynamic> map) => FillableUser(map);
}

class GuardedUser extends Model {
  @override
  String get table => 'users';

  @override
  List<String> get guarded => ['id', 'is_admin', 'api_key'];

  GuardedUser([super.attributes]);

  @override
  GuardedUser fromMap(Map<String, dynamic> map) => GuardedUser(map);
}

class TotallyGuardedUser extends Model {
  @override
  String get table => 'users';

  // Default: guarded => ['*']

  TotallyGuardedUser([super.attributes]);

  @override
  TotallyGuardedUser fromMap(Map<String, dynamic> map) =>
      TotallyGuardedUser(map);
}

class MixedUser extends Model {
  @override
  String get table => 'users';

  @override
  List<String> get fillable => ['name', 'email'];

  @override
  List<String> get guarded => ['is_admin']; // Should be ignored when fillable is set

  MixedUser([super.attributes]);

  @override
  MixedUser fromMap(Map<String, dynamic> map) => MixedUser(map);
}

void main() {
  setUp(() {
    HasGuardsAttributes.reguard();
    DatabaseManager().setDatabase(MockDatabaseSpy());
  });

  tearDown(() {
    HasGuardsAttributes.reguard();
  });

  group('HasGuardsAttributes Extended', () {
    test('fill() ignores keys not in fillable', () {
      final user = FillableUser();

      user.fill({
        'name': 'David',
        'email': 'david@test.com',
        'is_admin': true,
        'password': 'secret',
      });

      expect(user.attributes['name'], 'David');
      expect(user.attributes['email'], 'david@test.com');
      expect(user.attributes.containsKey('is_admin'), isFalse);
      expect(user.attributes.containsKey('password'), isFalse);
    });

    test('fill() with empty fillable blocks all (default behavior)', () {
      final user = TotallyGuardedUser();

      user.fill({
        'name': 'David',
        'email': 'david@test.com',
      });

      expect(user.attributes, isEmpty);
    });

    test('fill() with guarded * blocks all', () {
      final user = TotallyGuardedUser();

      user.fill({'anything': 'value'});

      expect(user.attributes, isEmpty);
    });

    test('fill() with specific guarded keys', () {
      final user = GuardedUser();

      user.fill({
        'name': 'David',
        'email': 'david@test.com',
        'id': 999,
        'is_admin': true,
        'api_key': 'secret',
      });

      expect(user.attributes['name'], 'David');
      expect(user.attributes['email'], 'david@test.com');
      expect(user.attributes.containsKey('id'), isFalse);
      expect(user.attributes.containsKey('is_admin'), isFalse);
      expect(user.attributes.containsKey('api_key'), isFalse);
    });

    test('fillable takes precedence over guarded', () {
      final user = MixedUser();

      user.fill({
        'name': 'David',
        'email': 'david@test.com',
        'is_admin': true, // In guarded, but fillable takes precedence
        'other': 'value', // Not in fillable
      });

      expect(user.attributes['name'], 'David');
      expect(user.attributes['email'], 'david@test.com');
      // fillable whitelist means only those keys are allowed
      expect(user.attributes.containsKey('is_admin'), isFalse);
      expect(user.attributes.containsKey('other'), isFalse);
    });

    test('forceFill() sets guarded attributes', () {
      final user = TotallyGuardedUser();

      user.forceFill({
        'name': 'David',
        'is_admin': true,
        'api_key': 'secret',
      });

      expect(user.attributes['name'], 'David');
      expect(user.attributes['is_admin'], true);
      expect(user.attributes['api_key'], 'secret');
    });

    test('isFillable() returns correct boolean', () {
      final user = FillableUser();

      expect(user.isFillable('name'), isTrue);
      expect(user.isFillable('email'), isTrue);
      expect(user.isFillable('is_admin'), isFalse);
      expect(user.isFillable('anything'), isFalse);
    });

    test('isFillable() with guarded model', () {
      final user = GuardedUser();

      expect(user.isFillable('name'), isTrue);
      expect(user.isFillable('id'), isFalse);
      expect(user.isFillable('is_admin'), isFalse);
    });

    test('unguard() affects all model instances', () {
      HasGuardsAttributes.unguard();

      final user1 = TotallyGuardedUser();
      final user2 = FillableUser();

      user1.fill({'anything': 'value1'});
      user2.fill({'is_admin': true});

      expect(user1.attributes['anything'], 'value1');
      expect(user2.attributes['is_admin'], true);
    });

    test('reguard() restores protection', () {
      HasGuardsAttributes.unguard();

      final user1 = TotallyGuardedUser();
      user1.fill({'test': 'value'});
      expect(user1.attributes['test'], 'value');

      HasGuardsAttributes.reguard();

      final user2 = TotallyGuardedUser();
      user2.fill({'test': 'value'});
      expect(user2.attributes.containsKey('test'), isFalse);
    });

    test('fill() with nested objects', () {
      final user = FillableUser();

      user.fill({
        'name': 'David',
        'bio': 'Developer',
        'nested': {'key': 'value'}, // Not in fillable
      });

      expect(user.attributes['name'], 'David');
      expect(user.attributes['bio'], 'Developer');
      expect(user.attributes.containsKey('nested'), isFalse);
    });
  });
}