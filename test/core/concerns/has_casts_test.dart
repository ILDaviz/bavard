import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

enum UserStatus { active, inactive, pending }

enum Priority { low, medium, high }

class CastUser extends Model {
  @override
  String get table => 'users';

  CastUser([super.attributes]);

  @override
  CastUser fromMap(Map<String, dynamic> map) => CastUser(map);

  @override
  Map<String, String> get casts => {
    'age': 'int',
    'score': 'double',
    'is_active': 'bool',
    'created_at': 'datetime',
    'settings': 'json',
    'tags': 'array',
    'metadata': 'object',
    'nullable_int': 'int?',
    'required_int': 'int!',
  };
}

class JsonModel {
  final String name;
  final int value;

  JsonModel(this.name, this.value);

  Map<String, dynamic> toJson() => {'name': name, 'value': value};
}

void main() {
  setUp(() {
    DatabaseManager().setDatabase(MockDatabaseSpy());
  });

  // ===========================================================================
  // TYPE CASTING - READ
  // ===========================================================================
  group('getAttribute - Integer', () {
    test('getAttribute int from string', () {
      final user = CastUser({'age': '25'});
      expect(user.getAttribute<int>('age'), 25);
    });

    test('getAttribute int from int (passthrough)', () {
      final user = CastUser({'age': 30});
      expect(user.getAttribute<int>('age'), 30);
    });

    test('getAttribute int from invalid string returns null', () {
      final user = CastUser({'age': 'not-a-number'});
      expect(user.getAttribute<int>('age'), isNull);
    });

    test(
      'getAttribute int from double string returns null (int.tryParse limitation)',
      () {
        final user = CastUser({'age': '25.9'});
        final result = user.getAttribute<int>('age');

        // int.tryParse('25.9') returns null because it cannot parse decimal strings
        // This is the expected behavior of the current implementation
        // Return null
        // TODO: Change?
        expect(result, isNull);
      },
    );
  });

  group('getAttribute - Double', () {
    test('getAttribute double from string', () {
      final user = CastUser({'score': '99.5'});
      expect(user.getAttribute<double>('score'), 99.5);
    });

    test('getAttribute double from int', () {
      final user = CastUser({'score': 100});
      expect(user.getAttribute<double>('score'), 100.0);
    });

    test('getAttribute double from double (passthrough)', () {
      final user = CastUser({'score': 88.8});
      expect(user.getAttribute<double>('score'), 88.8);
    });

    test('getAttribute double from invalid string returns null', () {
      final user = CastUser({'score': 'invalid'});
      expect(user.getAttribute<double>('score'), isNull);
    });
  });

  group('getAttribute - Boolean', () {
    test('getAttribute bool from int 1', () {
      final user = CastUser({'is_active': 1});
      expect(user.getAttribute<bool>('is_active'), isTrue);
    });

    test('getAttribute bool from int 0', () {
      final user = CastUser({'is_active': 0});
      expect(user.getAttribute<bool>('is_active'), isFalse);
    });

    test('getAttribute bool from string "true"', () {
      final user = CastUser({'is_active': 'true'});
      expect(user.getAttribute<bool>('is_active'), isTrue);
    });

    test('getAttribute bool from string "false"', () {
      final user = CastUser({'is_active': 'false'});
      expect(user.getAttribute<bool>('is_active'), isFalse);
    });

    test('getAttribute bool from string "1"', () {
      final user = CastUser({'is_active': '1'});
      expect(user.getAttribute<bool>('is_active'), isTrue);
    });

    test('getAttribute bool from string "0"', () {
      final user = CastUser({'is_active': '0'});
      expect(user.getAttribute<bool>('is_active'), isFalse);
    });

    test('getAttribute bool from bool (passthrough)', () {
      final user = CastUser({'is_active': true});
      expect(user.getAttribute<bool>('is_active'), isTrue);
    });

    test('getAttribute bool from string "TRUE" (case insensitive)', () {
      final user = CastUser({'is_active': 'TRUE'});
      expect(user.getAttribute<bool>('is_active'), isTrue);
    });
  });

  group('getAttribute - DateTime', () {
    test('getAttribute datetime from ISO string', () {
      final user = CastUser({'created_at': '2024-06-15T10:30:00.000'});
      final dt = user.getAttribute<DateTime>('created_at');

      expect(dt, isA<DateTime>());
      expect(dt?.year, 2024);
      expect(dt?.month, 6);
      expect(dt?.day, 15);
    });

    test('getAttribute datetime from DateTime (passthrough)', () {
      final now = DateTime.now();
      final user = CastUser({'created_at': now});

      expect(user.getAttribute<DateTime>('created_at'), now);
    });

    test('getAttribute datetime from invalid string returns null', () {
      final user = CastUser({'created_at': 'not-a-date'});
      expect(user.getAttribute<DateTime>('created_at'), isNull);
    });

    test('getAttribute datetime from date-only string', () {
      final user = CastUser({'created_at': '2024-01-15'});
      final dt = user.getAttribute<DateTime>('created_at');

      expect(dt?.year, 2024);
      expect(dt?.month, 1);
      expect(dt?.day, 15);
    });
  });

  group('getAttribute - JSON/Array/Object', () {
    test('getAttribute json from valid JSON string', () {
      final user = CastUser({'settings': '{"theme":"dark","lang":"en"}'});
      final settings = user.getAttribute<Map<String, dynamic>>('settings');

      expect(settings, isA<Map<String, dynamic>>());
      expect(settings?['theme'], 'dark');
    });

    test('getAttribute json from invalid JSON returns null', () {
      final user = CastUser({'settings': 'not valid json {'});
      expect(user.getAttribute('settings'), isNull);
    });

    test('getAttribute json from Map (passthrough)', () {
      final user = CastUser({
        'settings': {'theme': 'light'},
      });
      final settings = user.getAttribute<Map<String, dynamic>>('settings');

      expect(settings?['theme'], 'light');
    });

    test('getAttribute array from JSON array string', () {
      final user = CastUser({'tags': '["flutter","dart","orm"]'});
      final tags = user.getAttribute<List<dynamic>>('tags');

      expect(tags, isA<List>());
      expect(tags, contains('flutter'));
      expect(tags?.length, 3);
    });

    test('getAttribute array from List (passthrough)', () {
      final user = CastUser({
        'tags': ['a', 'b', 'c'],
      });
      final tags = user.getAttribute<List>('tags');

      expect(tags?.length, 3);
    });

    test('getAttribute object from JSON object string', () {
      final user = CastUser({'metadata': '{"version":1,"flag":true}'});
      final meta = user.getAttribute<Map<String, dynamic>>('metadata');

      expect(meta?['version'], 1);
      expect(meta?['flag'], true);
    });
  });

  group('getAttribute - Edge Cases', () {
    test('getAttribute with unknown cast type returns raw value', () {
      final user = CastUser({'unknown': 'raw_value'});
      expect(user.getAttribute('unknown'), 'raw_value');
    });

    test('getAttribute returns null for missing key', () {
      final user = CastUser({});
      expect(user.getAttribute('nonexistent'), isNull);
    });

    test('getAttribute returns null for null value', () {
      final user = CastUser({'age': null});
      expect(user.getAttribute<int>('age'), isNull);
    });
  });

  // ===========================================================================
  // TYPE CASTING - WRITE
  // ===========================================================================
  group('setAttribute - JSON Encoding', () {
    test('setAttribute encodes Map to JSON string', () {
      final user = CastUser();
      user.setAttribute('settings', {'theme': 'dark'});

      expect(user.attributes['settings'], isA<String>());
      expect(user.attributes['settings'], contains('"theme":"dark"'));
    });

    test('setAttribute encodes List to JSON string', () {
      final user = CastUser();
      user.setAttribute('tags', ['a', 'b', 'c']);

      expect(user.attributes['tags'], isA<String>());
      expect(user.attributes['tags'], '["a","b","c"]');
    });

    test('setAttribute encodes nested objects to JSON', () {
      final user = CastUser();
      user.setAttribute('settings', {
        'nested': {'deep': true},
      });

      expect(user.attributes['settings'], contains('"nested"'));
      expect(user.attributes['settings'], contains('"deep":true'));
    });

    test('setAttribute calls toJson() on custom objects', () {
      final user = CastUser();
      final obj = JsonModel('test', 42);
      user.setAttribute('settings', obj);

      expect(user.attributes['settings'], '{"name":"test","value":42}');
    });

    test('setAttribute preserves JSON string as-is', () {
      final user = CastUser();
      user.setAttribute('settings', '{"already":"json"}');

      expect(user.attributes['settings'], '{"already":"json"}');
    });
  });

  group('setAttribute - Primitives', () {
    test('setAttribute encodes bool true to 1', () {
      final user = CastUser();
      user.setAttribute('is_active', true);

      expect(user.attributes['is_active'], 1);
    });

    test('setAttribute encodes bool false to 0', () {
      final user = CastUser();
      user.setAttribute('is_active', false);

      expect(user.attributes['is_active'], 0);
    });

    test('setAttribute encodes DateTime to ISO string', () {
      final user = CastUser();
      final dt = DateTime(2024, 6, 15, 10, 30, 0);
      user.setAttribute('created_at', dt);

      expect(user.attributes['created_at'], '2024-06-15T10:30:00.000');
    });

    test('setAttribute with null value', () {
      final user = CastUser({'age': 25});
      user.setAttribute('age', null);

      expect(user.attributes['age'], isNull);
    });

    test('setAttribute preserves int as int', () {
      final user = CastUser();
      user.setAttribute('age', 30);

      expect(user.attributes['age'], 30);
      expect(user.attributes['age'], isA<int>());
    });

    test('setAttribute preserves string as string', () {
      final user = CastUser();
      user.setAttribute('name', 'David');

      expect(user.attributes['name'], 'David');
    });
  });

  group('setAttribute - Enum', () {
    test('setAttribute encodes Enum to name string', () {
      final user = CastUser();
      user.setAttribute('status', UserStatus.active);

      expect(user.attributes['status'], 'active');
    });

    test('setAttribute encodes different enum values', () {
      final user = CastUser();

      user.setAttribute('status', Priority.high);
      expect(user.attributes['status'], 'high');

      user.setAttribute('status', Priority.low);
      expect(user.attributes['status'], 'low');
    });
  });

  // ===========================================================================
  // ENUM HANDLING (getEnum)
  // ===========================================================================
  group('getEnum', () {
    test('getEnum with valid int index', () {
      final user = CastUser({'status': 0});
      final status = user.getEnum('status', UserStatus.values);

      expect(status, UserStatus.active);
    });

    test('getEnum with out-of-bounds index returns null', () {
      final user = CastUser({'status': 99});
      final status = user.getEnum('status', UserStatus.values);

      expect(status, isNull);
    });

    test('getEnum with negative index returns null', () {
      final user = CastUser({'status': -1});
      final status = user.getEnum('status', UserStatus.values);

      expect(status, isNull);
    });

    test('getEnum with valid string name', () {
      final user = CastUser({'status': 'pending'});
      final status = user.getEnum('status', UserStatus.values);

      expect(status, UserStatus.pending);
    });

    test('getEnum with invalid string name returns null', () {
      final user = CastUser({'status': 'unknown'});
      final status = user.getEnum('status', UserStatus.values);

      expect(status, isNull);
    });

    test('getEnum with null value returns null', () {
      final user = CastUser({'status': null});
      final status = user.getEnum('status', UserStatus.values);

      expect(status, isNull);
    });

    test('getEnum with missing key returns null', () {
      final user = CastUser({});
      final status = user.getEnum('status', UserStatus.values);

      expect(status, isNull);
    });
  });
}
