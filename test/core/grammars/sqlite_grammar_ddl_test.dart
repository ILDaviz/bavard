import 'package:bavard/src/grammars/sqlite_grammar.dart';
import 'package:bavard/src/schema/blueprint.dart';
import 'package:test/test.dart';

void main() {
  group('SQLiteGrammar DDL', () {
    late SQLiteGrammar grammar;

    setUp(() {
      grammar = SQLiteGrammar();
    });

    test('compileCreateTable with all types', () {
      final blueprint = Blueprint('all_types');
      blueprint.id();
      blueprint.string('name');
      blueprint.boolean('is_active');
      blueprint.timestamp('created_at');
      blueprint.json('meta');
      blueprint.enumCol('status', ['draft', 'published']);

      final sql = grammar.compileCreateTable(blueprint);

      expect(sql, startsWith('CREATE TABLE "all_types"'));
      expect(
        sql,
        contains('"id" INTEGER PRIMARY KEY AUTOINCREMENT'),
      ); // SQLite uses INTEGER for auto-inc
      expect(sql, contains('"name" TEXT NOT NULL'));
      expect(sql, contains('"is_active" INTEGER NOT NULL'));
      expect(sql, contains('"created_at" TEXT NOT NULL'));
      expect(sql, contains('"meta" TEXT NOT NULL'));
      expect(sql, contains('"status" TEXT NOT NULL'));
      expect(sql, contains('CHECK ("status" IN (\'draft\', \'published\'))'));
    });
  });
}
