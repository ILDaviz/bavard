import 'package:test/test.dart';
import 'package:bavard/bavard.dart';

import 'mocks/moke_database.dart';

class TestUser extends Model {
  @override
  String get table => 'users';
  TestUser([super.attributes]);
  @override
  TestUser fromMap(Map<String, dynamic> map) => TestUser(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  test(
    'first() uses a clone and does not mutate original query builder state',
    () async {
      final query = TestUser().query().where('active', 1);

      // Esegue first(). Questo dovrebbe usare internamente una copia con LIMIT 1
      await query.first();

      expect(dbSpy.lastSql, contains('LIMIT 1'));
      expect(dbSpy.lastSql, contains('WHERE active = ?'));

      // Esegue get() sullo stesso builder originale.
      // Se il cloning funziona, qui NON deve esserci LIMIT 1.
      await query.get();

      expect(dbSpy.lastSql, isNot(contains('LIMIT 1')));
      expect(dbSpy.lastSql, contains('WHERE active = ?'));
    },
  );
}
