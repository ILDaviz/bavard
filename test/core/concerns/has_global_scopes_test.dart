import 'package:bavard/src/core/concerns/has_global_scopes.dart';
import 'package:bavard/src/core/scope.dart';
import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

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
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Global Scopes', () {
    test('It applies registered scopes automatically', () async {
      await ScopedUser().query().get();

      expect(dbSpy.lastSql, contains('age >= ?'));
      expect(dbSpy.lastSql, contains('is_active = ?'));
      expect(dbSpy.lastArgs, contains(18));
      expect(dbSpy.lastArgs, contains(1));
    });

    test('withoutGlobalScopes() ignores all scopes', () async {
      await ScopedUser().withoutGlobalScopes().get();

      expect(dbSpy.lastSql, isNot(contains('age >=')));
      expect(dbSpy.lastSql, isNot(contains('is_active =')));
    });

    test('withoutGlobalScope<T>() ignores only specific scope', () async {
      await ScopedUser().withoutGlobalScope<AgeScope>().get();

      expect(dbSpy.lastSql, isNot(contains('age >=')));
      expect(dbSpy.lastSql, contains('is_active = ?'));
    });
  });
}
