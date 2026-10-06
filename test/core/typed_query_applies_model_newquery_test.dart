import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class SoftUser extends Model with HasSoftDeletes {
  @override
  String get table => 'users';

  SoftUser([super.attributes]);

  @override
  SoftUser fromMap(Map<String, dynamic> map) => SoftUser(map);

  @override
  Map<String, String> get casts => {'deleted_at': 'datetime'};
}

class AgeScope implements Scope {
  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('age', 18, '>=');
  }
}

class ActiveScope implements Scope {
  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('is_active', 1);
  }
}

class ScopedUser extends Model with HasGlobalScopes {
  @override
  String get table => 'users';

  @override
  List<Scope> get globalScopes => [AgeScope(), ActiveScope()];

  ScopedUser([super.attributes]);

  @override
  ScopedUser fromMap(Map<String, dynamic> map) => ScopedUser(map);
}

void main() {
  group('TypedQuery.query() respects Model.query() overrides', () {
    test('SoftDeletes is applied also via typed query()', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      await SoftUser().query().get();

      expect(dbSpy.lastSql, contains('WHERE "users"."deleted_at" IS NULL'));
    });

    test('HasGlobalScopes are applied also via typed query()', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      await ScopedUser().query().get();

      expect(dbSpy.lastSql, contains('"age" >= ?'));
      expect(dbSpy.lastSql, contains('"is_active" = ?'));

      expect(dbSpy.lastArgs, isNotNull);
      expect(dbSpy.lastArgs, contains(18));
      expect(dbSpy.lastArgs, contains(1));
    });
  });
}
