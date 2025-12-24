import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/testing.dart';

class TestUser extends Model {
  @override
  String get table => 'users';
  TestUser([super.attributes]);
  @override
  TestUser fromMap(Map<String, dynamic> map) => TestUser(map);
  
  static final schema = TestUserSchema();
}

class TestUserSchema {
  final votes = IntColumn('votes');
}

void main() {
  setUp(() {
    DatabaseManager().setDatabase(MockDatabaseSpy());
  });

  test('groupBy throws ArgumentError when passed a WhereCondition', () {
    expect(
      () => TestUser().query().groupBy([TestUser.schema.votes.greaterThanOrEqual(100)]),
      throwsA(isA<ArgumentError>().having(
        (e) => e.message, 
        'message', 
        contains('You passed a WhereCondition'),
      )),
    );
  });

  test('whereNull throws ArgumentError when passed a WhereCondition', () {
    expect(
      () => TestUser().query().whereNull(TestUser.schema.votes.greaterThanOrEqual(100)),
      throwsA(isA<ArgumentError>().having(
        (e) => e.message, 
        'message', 
        contains('You passed a WhereCondition'),
      )),
    );
  });
}
