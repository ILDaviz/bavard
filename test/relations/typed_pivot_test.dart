import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/testing.dart';

class UserRole extends Pivot {
  UserRole(super.attributes);

  static const schema = (
    createdAt: DateTimeColumn('created_at', isNullable: true),
    isActive: BoolColumn('is_active', isNullable: true),
  );

  DateTime? get createdAt => get(UserRole.schema.createdAt);
  set createdAt(DateTime? value) => set(UserRole.schema.createdAt, value);
  bool? get isActive => get(UserRole.schema.isActive);
  set isActive(bool? value) => set(UserRole.schema.isActive, value);

  static List<Column> get columns => [
    UserRole.schema.createdAt,
    UserRole.schema.isActive,
  ];
}

// A dummy pivot class for testing type mismatches
class AnotherPivot extends Pivot {
  AnotherPivot(super.attributes);
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
  TypedUserWithPivot fromMap(Map<String, dynamic> map) =>
      TypedUserWithPivot(map);

  BelongsToMany<TypedRole> roles() {
    return belongsToMany(
      TypedRole.new,
      'user_roles',
      foreignPivotKey: 'user_id',
      relatedPivotKey: 'role_id',
    ).using(UserRole.new, UserRole.columns);
  }

  @override
  Relation? getRelation(String name) {
    if (name == 'roles') return roles();
    return super.getRelation(name);
  }

  List<TypedRole> get rolesList => getRelationList<TypedRole>('roles');
}

class StrictUserRole extends Pivot {
  StrictUserRole(super.attributes);

  static const schema = (
    createdAt: DateTimeColumn('created_at'),
    isActive: BoolColumn('is_active'),
  );

  DateTime get createdAt => get(StrictUserRole.schema.createdAt);
  bool get isActive => get(StrictUserRole.schema.isActive);

  static List<SchemaColumn> get columns => [
    StrictUserRole.schema.createdAt,
    StrictUserRole.schema.isActive,
  ];
}

class StrictUserWithPivot extends Model {
  @override
  String get table => 'users';

  StrictUserWithPivot([super.attributes]);
  @override
  StrictUserWithPivot fromMap(Map<String, dynamic> map) =>
      StrictUserWithPivot(map);

  BelongsToMany<TypedRole> roles() {
    return belongsToMany(
      TypedRole.new,
      'user_roles',
      foreignPivotKey: 'user_id',
      relatedPivotKey: 'role_id',
    ).using(StrictUserRole.new, StrictUserRole.columns);
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
    test(
      'It eagerly loads pivot data and hydrates strongly typed Pivot object',
      () async {
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
              'is_active': 1, // sqlite bool
            },
          ],
          'FROM "roles"': [
            {'id': 100, 'name': 'Admin'},
          ],
        });
        DatabaseManager().setDatabase(mockDb);

        final users = await TypedUserWithPivot().query().withRelations([
          'roles',
        ]).get();

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
      },
    );

    test('It handles NULL values in pivot columns gracefully', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
        'FROM "user_roles"': [
          {'user_id': 1, 'role_id': 100, 'created_at': null, 'is_active': null},
        ],
        'FROM "roles"': [
          {'id': 100, 'name': 'Admin'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = await TypedUserWithPivot().query().withRelations([
        'roles',
      ]).get();
      final pivot = users.first.rolesList.first.getPivot<UserRole>()!;

      expect(pivot.createdAt, isNull);
      expect(pivot.isActive, isNull);
    });

    test(
      'It throws TypeError if non-nullable columns receive NULL from DB',
      () async {
        final mockDb = MockDatabaseSpy([], {
          'FROM "users"': [
            {'id': 1, 'name': 'David'},
          ],
          'FROM "user_roles"': [
            {
              'user_id': 1,
              'role_id': 100,
              'created_at': null,
              'is_active': null,
            },
          ],
          'FROM "roles"': [
            {'id': 100, 'name': 'Admin'},
          ],
        });
        DatabaseManager().setDatabase(mockDb);

        final users = await StrictUserWithPivot().query().withRelations([
          'roles',
        ]).get();
        final pivot = users.first.rolesList.first.getPivot<StrictUserRole>()!;

        // Trying to access non-nullable getters when data is null should throw TypeError
        expect(() => pivot.createdAt, throwsA(isA<TypeError>()));
        expect(() => pivot.isActive, throwsA(isA<TypeError>()));
      },
    );

    test('It throws FormatException if DateTime data is malformed', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "users"': [
          {'id': 1, 'name': 'David'},
        ],
        'FROM "user_roles"': [
          {
            'user_id': 1,
            'role_id': 100,
            'created_at': 'not-a-valid-date',
            'is_active': 1,
          },
        ],
        'FROM "roles"': [
          {'id': 100, 'name': 'Admin'},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final users = await TypedUserWithPivot().query().withRelations([
        'roles',
      ]).get();
      final pivot = users.first.rolesList.first.getPivot<UserRole>()!;

      expect(() => pivot.createdAt, throwsFormatException);
    });

    test('It updates underlying attributes when using setters', () {
      final pivot = UserRole({});

      expect(pivot.isActive, isNull);

      pivot.isActive = true;

      expect(pivot.attributes['is_active'], true);
      expect(pivot.isActive, isTrue);

      final now = DateTime.now();
      pivot.createdAt = now;
      expect(pivot.attributes['created_at'], now);
    });

    test(
      'getPivot returns null if requested type does not match actual pivot type',
      () async {
        final mockDb = MockDatabaseSpy([], {
          'FROM "users"': [
            {'id': 1, 'name': 'David'},
          ],
          'FROM "user_roles"': [
            {'user_id': 1, 'role_id': 100},
          ],
          'FROM "roles"': [
            {'id': 100, 'name': 'Admin'},
          ],
        });
        DatabaseManager().setDatabase(mockDb);

        final users = await TypedUserWithPivot().query().withRelations([
          'roles',
        ]).get();
        final role = users.first.rolesList.first;

        expect(role.getPivot<UserRole>(), isNotNull);

        expect(role.getPivot<AnotherPivot>(), isNull);
      },
    );

    test(
      'It constructs correct SELECT clause for Lazy Loading (get)',
      () async {
        final dbSpy = MockDatabaseSpy();
        DatabaseManager().setDatabase(dbSpy);

        await TypedUserWithPivot().roles().where('roles.id', 1).get();

        expect(dbSpy.lastSql, contains('AS "pivot_created_at"'));
        expect(dbSpy.lastSql, contains('AS "pivot_is_active"'));
      },
    );

    test('It adds wherePivot clauses correctly', () async {
      final dbSpy = MockDatabaseSpy();
      DatabaseManager().setDatabase(dbSpy);

      await TypedUserWithPivot()
          .roles()
          .wherePivot('is_active', true)
          .wherePivotCondition(UserRole.schema.createdAt.after(DateTime(2023)))
          .get();

      final sql = dbSpy.lastSql;
      expect(sql, contains('"user_roles"."is_active" = ?'));
      expect(sql, contains('"user_roles"."created_at" > ?'));
    });
  });
}
