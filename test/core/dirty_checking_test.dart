import 'package:test/test.dart';
import 'package:bavard/bavard.dart';

class User extends Model {
  @override
  String get table => 'users';
  User([super.attributes]);
  @override
  User fromMap(Map<String, dynamic> map) => User(map);
}

void main() {
  group('Dirty Checking', () {
    test('newly instantiated model is clean by default', () {
      final user = User({'name': 'David'});
      // In the constructor, original = Map.from(rawAttributes), so it starts clean.
      expect(user.isDirty(), isFalse);
      expect(user.getDirty(), isEmpty);
    });

    test('model is clean after syncOriginal', () {
      final user = User({'name': 'David'});
      user.syncOriginal();
      
      expect(user.isDirty(), isFalse);
      expect(user.getDirty(), isEmpty);
    });

    test('model becomes dirty after attribute change', () {
      final user = User({'name': 'David'});
      user.syncOriginal();
      
      user.attributes['name'] = 'Updated';
      
      expect(user.isDirty(), isTrue);
      expect(user.isDirty('name'), isTrue);
      expect(user.getDirty(), containsPair('name', 'Updated'));
    });

    test('isDirty accurately detects specific field changes', () {
      final user = User({'name': 'David', 'email': 'test@test.com'});
      user.syncOriginal();
      
      user.attributes['name'] = 'Updated';
      
      expect(user.isDirty('name'), isTrue);
      expect(user.isDirty('email'), isFalse);
    });

    test('getDirty only returns modified fields', () {
      final user = User({'name': 'David', 'email': 'test@test.com'});
      user.syncOriginal();
      
      user.attributes['name'] = 'Updated';
      
      final dirty = user.getDirty();
      expect(dirty.length, 1);
      expect(dirty, hasLength(1));
      expect(dirty.containsKey('name'), isTrue);
      expect(dirty.containsKey('email'), isFalse);
    });

    test('model becomes clean again after reverting changes manually', () {
      final user = User({'name': 'David'});
      user.syncOriginal();
      
      user.attributes['name'] = 'Updated';
      expect(user.isDirty(), isTrue);
      
      user.attributes['name'] = 'David';
      expect(user.isDirty(), isFalse);
    });
  });
}
