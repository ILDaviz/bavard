import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/src/schema/columns.dart';

class SchemaUser extends Model {
  @override
  String get table => 'schema_users';

  SchemaUser([super.attributes]);

  @override
  SchemaUser fromMap(Map<String, dynamic> map) => SchemaUser(map);

  @override
  List<SchemaColumn> get columns => [
    IntColumn('age'),
    DoubleColumn('score'),
    BoolColumn('is_active'),
    DateTimeColumn('created_at'),
    JsonColumn('settings'),
    TextColumn('name'),
  ];
}

class HybridUser extends Model {
  @override
  String get table => 'hybrid';

  HybridUser([super.attributes]);
  @override
  HybridUser fromMap(Map<String, dynamic> map) => HybridUser(map);

  @override
  List<SchemaColumn> get columns => [IntColumn('age')];

  @override
  Map<String, String> get casts => {'age': 'double'};
}

void main() {
  group('HasCasts with Schema Columns', () {
    test('It derives casts from IntColumn', () {
      final user = SchemaUser({'age': '25'});
      expect(user.getAttribute<int>('age'), 25);
    });

    test('It derives casts from DoubleColumn', () {
      final user = SchemaUser({'score': '99.5'});
      expect(user.getAttribute<double>('score'), 99.5);
    });

    test('It derives casts from BoolColumn', () {
      final user = SchemaUser({'is_active': 1});
      expect(user.getAttribute<bool>('is_active'), isTrue);
    });

    test('It derives casts from DateTimeColumn', () {
      final user = SchemaUser({'created_at': '2024-06-15T10:30:00.000'});
      final dt = user.getAttribute<DateTime>('created_at');
      expect(dt?.year, 2024);
    });

    test('It derives casts from JsonColumn', () {
      final user = SchemaUser({'settings': '{"theme":"dark"}'});
      final settings = user.getAttribute<Map<String, dynamic>>('settings');
      expect(settings?['theme'], 'dark');
    });

    test('It handles String column (default)', () {
      final user = SchemaUser({'name': 'David'});
      expect(user.getAttribute<String>('name'), 'David');
    });

    test('setAttribute uses schema types', () {
      final user = SchemaUser();
      user.setAttribute('is_active', true);
      // BoolColumn -> boolean -> bool cast -> stored as 1/0
      expect(user.attributes['is_active'], 1);
    });
    
    test('Mixed usage: casts overrides schema', () {
      // Define a model that has both but overrides one
      final hybrid = HybridUser({'age': '25'});
      // Schema says Int, Casts says String (hypothetically, though illogical)
      // Or Schema says Int, Casts says Double
      expect(hybrid.getAttribute<double>('age'), 25.0);
    });
  });
}
