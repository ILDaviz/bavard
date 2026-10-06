import 'package:bavard/src/grammars/postgres_grammar.dart';
import 'package:bavard/src/schema/blueprint.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresGrammar DDL', () {
    late PostgresGrammar grammar;

    setUp(() {
      grammar = PostgresGrammar();
    });

    test('compileCreateTable with all types', () {
      final blueprint = Blueprint('all_types');
      blueprint.id();
      blueprint.string('name');
      blueprint.text('description');
      blueprint.integer('age');
      blueprint.float('score');
      blueprint.boolean('is_active');
      blueprint.timestamp('created_at');
      blueprint.date('birthday');
      blueprint.json('meta');
      blueprint.uuid('uid');
      blueprint.ipAddress('ip');
      blueprint.enumCol('status', ['draft', 'published']);

      final sql = grammar.compileCreateTable(blueprint);

      expect(sql, startsWith('CREATE TABLE "all_types"'));
      expect(
        sql,
        contains('"id" BIGSERIAL PRIMARY KEY'),
      ); // id() uses bigIncrements -> BIGSERIAL
      expect(sql, contains('"name" VARCHAR(255) NOT NULL'));
      expect(sql, contains('"description" TEXT NOT NULL'));
      expect(sql, contains('"age" INTEGER NOT NULL'));
      expect(sql, contains('"score" DOUBLE PRECISION NOT NULL'));
      expect(sql, contains('"is_active" BOOLEAN NOT NULL'));
      expect(sql, contains('"created_at" TIMESTAMP NOT NULL'));
      expect(sql, contains('"birthday" DATE NOT NULL'));
      expect(sql, contains('"meta" JSON NOT NULL'));
      expect(sql, contains('"uid" UUID NOT NULL'));
      expect(sql, contains('"ip" INET NOT NULL'));
      expect(sql, contains('"status" VARCHAR(255) NOT NULL'));
      expect(sql, contains('CHECK ("status" IN (\'draft\', \'published\'))'));
    });

    test('compileCreateTable with constraints', () {
      final blueprint = Blueprint('users');
      blueprint.id();
      blueprint.string('email').unique();
      blueprint.string('username').defaultTo('guest');

      final sql = grammar.compileCreateTable(blueprint);

      expect(sql, contains('"email" VARCHAR(255) UNIQUE NOT NULL'));
      expect(sql, contains('"username" VARCHAR(255) NOT NULL DEFAULT ?'));
    });
  });
}
