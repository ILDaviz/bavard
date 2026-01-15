import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class User extends Model with HasSoftDeletes {
  @override
  String get table => 'users';

  @override
  User fromMap(Map<String, dynamic> map) => User();
}

void main() {
  setUp(() {
    DatabaseManager().setDatabase(MockDatabaseSpy());
  });

  group('QueryBuilder Print Methods', () {
    test('toSql() should include global scopes (like SoftDeletes)', () {
      final user = User();
      final sql = user.newQuery().toSql();

      expect(sql, contains('WHERE "users"."deleted_at" IS NULL'));
    });

    test('toRawSql() should include global scopes', () {
      final user = User();
      final sql = user.newQuery().toRawSql();

      expect(sql, contains('WHERE "users"."deleted_at" IS NULL'));
    });

    test('toRawSql() interpolates bindings correctly', () {
      final user = User();
      final sql = user
          .newQuery()
          .where('name', 'David')
          .where('age', 25, '>')
          .toRawSql();

      expect(sql, contains('"name" = \'David\''));
      expect(sql, contains('"age" > 25'));
    });

    test('toRawSql() should not replace ? inside string literals', () {
      final user = User();
      // We use whereRaw to simulate a ? inside a string literal that is NOT a placeholder!
      final sql = user
          .newQuery()
          .whereRaw("name = 'Is it true?'")
          .where('id', 1)
          .toRawSql();

      expect(sql, contains("name = 'Is it true?'"));
      expect(sql, contains('"id" = 1'));
    });

    test('toRawSql() handles UNION bindings correctly', () {
      final q1 = User().newQuery().where('id', 1);
      final q2 = User().newQuery().where('id', 2);

      final sql = q1.union(q2).toRawSql();

      expect(sql, contains('"id" = 1'));
      expect(sql, contains('"id" = 2'));
      expect(sql, contains('UNION'));
    });

    test('toRawSql() handles boolean based on grammar (Postgres)', () {
      DatabaseManager().setDatabase(MockDatabaseSpy([], {}, PostgresGrammar()));

      final sql = User().newQuery().where('active', true).toRawSql();

      expect(sql, contains('"active" = TRUE'));
    });
  });
}
