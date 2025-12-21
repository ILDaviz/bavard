import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class TenantScope implements Scope {
  final int tenantId;
  TenantScope(this.tenantId);

  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('tenant_id', tenantId);
  }
}

class ActiveScope implements Scope {
  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('is_active', 1);
  }
}

class AgeScope implements Scope {
  @override
  void apply(QueryBuilder builder, Model model) {
    builder.where('age', 18, '>=');
  }
}

class MultiScopeUser extends Model with HasGlobalScopes {
  @override
  String get table => 'users';

  @override
  List<Scope> get globalScopes => [TenantScope(42), ActiveScope(), AgeScope()];

  MultiScopeUser([super.attributes]);

  @override
  MultiScopeUser fromMap(Map<String, dynamic> map) => MultiScopeUser(map);
}

class NoScopeUser extends Model with HasGlobalScopes {
  @override
  String get table => 'users';

  @override
  List<Scope> get globalScopes => [];

  NoScopeUser([super.attributes]);

  @override
  NoScopeUser fromMap(Map<String, dynamic> map) => NoScopeUser(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('HasGlobalScopes Extended', () {
    test('multiple scopes applied in order', () async {
      await MultiScopeUser().query().get();

      // All three scopes should be applied
      expect(dbSpy.lastSql, contains('"tenant_id" = ?'));
      expect(dbSpy.lastSql, contains('"is_active" = ?'));
      expect(dbSpy.lastSql, contains('"age" >= ?'));

      // Bindings should be in order
      expect(dbSpy.lastArgs, equals([42, 1, 18]));
    });

    test('scope with dynamic parameters (TenantScope)', () async {
      await MultiScopeUser().query().get();

      expect(dbSpy.lastArgs, contains(42));
    });

    test('withoutGlobalScopes() with no scopes defined', () async {
      await NoScopeUser().withoutGlobalScopes().get();

      // Should work without error, no scopes applied
      expect(dbSpy.lastSql, isNot(contains('tenant_id')));
      expect(dbSpy.lastSql, isNot(contains('is_active')));
    });

    test('withoutGlobalScope<T>() with non-existent scope type', () async {
      // Trying to exclude a scope that doesn't exist
      await NoScopeUser().withoutGlobalScope<TenantScope>().get();

      // Should work without error
      expect(dbSpy.history, isNotEmpty);
    });

    test('withoutGlobalScope<T>() excludes only specific scope', () async {
      await MultiScopeUser().withoutGlobalScope<TenantScope>().get();

      // TenantScope should be excluded
      expect(dbSpy.lastSql, isNot(contains('tenant_id')));

      // Other scopes should still be applied
      expect(dbSpy.lastSql, contains('"is_active" = ?'));
      expect(dbSpy.lastSql, contains('"age" >= ?'));
    });

    test('withoutGlobalScopes() ignores all scopes', () async {
      await MultiScopeUser().withoutGlobalScopes().get();

      expect(dbSpy.lastSql, isNot(contains('tenant_id')));
      expect(dbSpy.lastSql, isNot(contains('is_active')));
      expect(dbSpy.lastSql, isNot(contains('age >=')));
    });

    test('scopes combined with additional where clauses', () async {
      await MultiScopeUser().query().where('name', 'David').get();

      // Scopes + manual where
      expect(dbSpy.lastSql, contains('"tenant_id" = ?'));
      expect(dbSpy.lastSql, contains('"name" = ?'));
    });
  });
}
