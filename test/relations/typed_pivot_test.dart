import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/testing.dart';

class UserRole extends Pivot {
  UserRole(super.attributes);

  static const createdAtCol = DateTimeColumn('created_at');
  static const isActiveCol = BoolColumn('is_active');

  DateTime? get createdAt => get(createdAtCol);
  bool? get isActive => get(isActiveCol);

  static List<Column> get schema => [createdAtCol, isActiveCol];
}

class TypedRole extends Model {
  @override
  String get table => 'roles';
  
  TypedRole([super.attributes]);
  @override
  TypedRole fromMap(Map<String, dynamic> map) => TypedRole(map);
}

class TypedUserWithPivot extends Model {
  @override
  String get table => 'users';

  TypedUserWithPivot([super.attributes]);
  @override
  TypedUserWithPivot fromMap(Map<String, dynamic> map) => TypedUserWithPivot(map);

  BelongsToMany<TypedRole> roles() {
    return belongsToMany(
      TypedRole.new,
      'user_roles',
      foreignPivotKey: 'user_id',
      relatedPivotKey: 'role_id',
    ).using(UserRole.new, UserRole.schema);
  }
  
  @override
  Relation? getRelation(String name) {
    if (name == 'roles') return roles();
    return super.getRelation(name);
  }
  
  List<TypedRole> get rolesList => getRelationList<TypedRole>('roles');
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('Typed Pivot Support', () {
    test('It eagerly loads pivot data and hydrates strongly typed Pivot object', () async {
      final now = DateTime.now();
      
      final mockDb = MockDatabaseSpy([], {
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
        'FROM "user_roles"': [
          {
            'user_id': 1, 
            'role_id': 100, 
            'created_at': now.toIso8601String(),
            'is_active': 1 // sqlite bool
          },
        ],
        'FROM "roles"': [
          {'id': 100, 'name': 'Admin'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = await TypedUserWithPivot()
          .query()
          .withRelations(['roles'])
          .get();

      final user = users.first;
      expect(user.rolesList, isNotEmpty);
      
      final role = user.rolesList.first;
      expect(role.id, 100);
      
      expect(role.pivot, isNotNull);
      expect(role.pivot, isA<UserRole>());
      
      final pivot = role.getPivot<UserRole>()!;
      expect(pivot.createdAt, isNotNull);
      expect(pivot.createdAt!.toIso8601String(), now.toIso8601String());
      expect(pivot.isActive, isTrue);
    });

    test('It constructs correct SELECT clause for Lazy Loading (get)', () async {
       final dbSpy = MockDatabaseSpy();
       DatabaseManager().setDatabase(dbSpy);
       
       await TypedUserWithPivot().roles().where('roles.id', 1).get();
       
       expect(dbSpy.lastSql, contains('AS "pivot_created_at"'));
       expect(dbSpy.lastSql, contains('AS "pivot_is_active"'));
    });

    test('It adds wherePivot clauses correctly', () async {
       final dbSpy = MockDatabaseSpy();
       DatabaseManager().setDatabase(dbSpy);

       await TypedUserWithPivot().roles()
         .wherePivot('is_active', true)
         .wherePivotCondition(UserRole.createdAtCol.after(DateTime(2023)))
         .get();

       final sql = dbSpy.lastSql;
       expect(sql, contains('"user_roles"."is_active" = ?'));
       expect(sql, contains('"user_roles"."created_at" > ?'));
    });
  });
}
