import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class Order extends Model {
  @override
  String get table => 'orders';

  Order([super.attributes]);

  @override
  Order fromMap(Map<String, dynamic> map) => Order(map);
}

class Product extends Model {
  @override
  String get table => 'products';

  Product([super.attributes]);

  @override
  Product fromMap(Map<String, dynamic> map) => Product(map);
}

void main() {
  late MockDatabaseSpy dbSpy;

  setUp(() {
    dbSpy = MockDatabaseSpy();
    DatabaseManager().setDatabase(dbSpy);
  });

  group('GROUP BY Clause', () {
    test('groupBy() generates correct SQL', () async {
      await Order()
          .query()
          .select(['customer_id', 'COUNT(*) as order_count'])
          .groupBy(['customer_id'])
          .get();

      expect(dbSpy.lastSql, contains('GROUP BY "customer_id"'));
    });

    test('groupBy() accepts multiple columns', () async {
      await Order()
          .query()
          .select(['customer_id', 'status', 'COUNT(*) as count'])
          .groupBy(['customer_id', 'status'])
          .get();

      expect(dbSpy.lastSql, contains('GROUP BY "customer_id", "status"'));
    });

    test('groupByColumn() is convenience for single column', () async {
      await Order()
          .query()
          .select(['status', 'COUNT(*) as count'])
          .groupByColumn('status')
          .get();

      expect(dbSpy.lastSql, contains('GROUP BY "status"'));
    });

    test('groupBy() validates column identifiers', () async {
      expect(
        () => Order().query().groupBy(['status; DROP TABLE orders']),
        throwsA(isA<InvalidQueryException>()),
      );
    });

    test('groupBy() works with dotted identifiers', () async {
      await Order()
          .query()
          .select(['orders.customer_id', 'COUNT(*) as count'])
          .groupBy(['orders.customer_id'])
          .get();

      expect(dbSpy.lastSql, contains('GROUP BY "orders"."customer_id"'));
    });
  });

  group('HAVING Clause', () {
    test('having() generates correct SQL', () async {
      await Order()
          .query()
          .select(['customer_id', 'SUM(total) as total_spent'])
          .groupBy(['customer_id'])
          .having('SUM(total)', 1000, operator: '>')
          .get();

      expect(dbSpy.lastSql, contains('GROUP BY "customer_id"'));
      expect(dbSpy.lastSql, contains('HAVING SUM(total) > ?'));
      expect(dbSpy.lastArgs, contains(1000));
    });

    test('having() supports multiple conditions with AND', () async {
      await Order()
          .query()
          .select(['customer_id', 'COUNT(*) as order_count'])
          .groupBy(['customer_id'])
          .having('COUNT(*)', 5, operator: '>=')
          .having('SUM(total)', 100, operator: '>')
          .get();

      expect(
        dbSpy.lastSql,
        contains('HAVING COUNT(*) >= ? AND SUM(total) > ?'),
      );
      expect(dbSpy.lastArgs, equals([5, 100]));
    });

    test('orHaving() generates OR condition', () async {
      await Order()
          .query()
          .select(['customer_id', 'COUNT(*) as order_count'])
          .groupBy(['customer_id'])
          .having('COUNT(*)', 10, operator: '>=')
          .orHaving('SUM(total)', 5000, operator: '>')
          .get();

      expect(dbSpy.lastSql, contains('HAVING COUNT(*) >= ? OR SUM(total) > ?'));
    });

    test('havingRaw() allows complex expressions', () async {
      await Product()
          .query()
          .select(['category', 'AVG(price) as avg_price'])
          .groupBy(['category'])
          .havingRaw('AVG(price) > ? AND COUNT(*) >= ?', bindings: [50.0, 10])
          .get();

      expect(
        dbSpy.lastSql,
        contains('HAVING AVG(price) > ? AND COUNT(*) >= ?'),
      );
      expect(dbSpy.lastArgs, equals([50.0, 10]));
    });

    test('havingBetween() generates BETWEEN clause', () async {
      await Order()
          .query()
          .select(['customer_id', 'COUNT(*) as order_count'])
          .groupBy(['customer_id'])
          .havingBetween('COUNT(*)', 5, 20)
          .get();

      expect(dbSpy.lastSql, contains('HAVING COUNT(*) BETWEEN ? AND ?'));
      expect(dbSpy.lastArgs, equals([5, 20]));
    });

    test('havingNull() and havingNotNull() work correctly', () async {
      await Order()
          .query()
          .select(['customer_id', 'MAX(discount) as max_discount'])
          .groupBy(['customer_id'])
          .havingNotNull('MAX(discount)')
          .get();

      expect(dbSpy.lastSql, contains('HAVING MAX(discount) IS NOT NULL'));
    });

    test('having() validates operators', () async {
      expect(
        () => Order()
            .query()
            .groupBy(['customer_id'])
            .having('COUNT(*)', 5, operator: 'INVALID'),
        throwsA(isA<InvalidQueryException>()),
      );
    });
  });

  group('GROUP BY + HAVING Integration', () {
    test('full query with WHERE, GROUP BY, HAVING, ORDER BY', () async {
      await Order()
          .query()
          .select([
            'customer_id',
            'COUNT(*) as order_count',
            'SUM(total) as total_spent',
          ])
          .where('status', 'completed')
          .groupBy(['customer_id'])
          .having('COUNT(*)', 3, operator: '>=')
          .orderBy('total_spent', direction: 'DESC')
          .limit(10)
          .get();

      final sql = dbSpy.lastSql;

      expect(sql, contains('WHERE "status" = ?'));
      expect(sql, contains('GROUP BY "customer_id"'));
      expect(sql, contains('HAVING COUNT(*) >= ?'));
      expect(sql, contains('ORDER BY "total_spent" DESC'));
      expect(sql, contains('LIMIT 10'));

      expect(sql.indexOf('WHERE'), lessThan(sql.indexOf('GROUP BY')));
      expect(sql.indexOf('GROUP BY'), lessThan(sql.indexOf('HAVING')));
      expect(sql.indexOf('HAVING'), lessThan(sql.indexOf('ORDER BY')));
    });

    test(
      'bindings are in correct order (WHERE bindings then HAVING bindings)',
      () async {
        await Order()
            .query()
            .select(['customer_id', 'COUNT(*) as count'])
            .where('status', 'active')
            .where('created_at', '2024-01-01', '>')
            .groupBy(['customer_id'])
            .having('COUNT(*)', 5, operator: '>=')
            .having('SUM(total)', 1000, operator: '>')
            .get();

        expect(dbSpy.lastArgs, equals(['active', '2024-01-01', 5, 1000]));
      },
    );

    test('cast() preserves GROUP BY and HAVING state', () async {
      final original = Order()
          .query()
          .select(['customer_id', 'COUNT(*) as count'])
          .groupBy(['customer_id'])
          .having('COUNT(*)', 5, operator: '>=');

      final casted = original.cast<Order>(Order.new);
      await casted.get();

      expect(dbSpy.lastSql, contains('GROUP BY "customer_id"'));
      expect(dbSpy.lastSql, contains('HAVING COUNT(*) >= ?'));
    });
  });

  group('Aggregates with GROUP BY', () {
    test('count() calculates total groups using subquery wrapper', () async {
      final countMock = MockDatabaseSpy([], {
        'SELECT COUNT(*) as aggregate': [
          {'aggregate': 5},
        ],
      });
      DatabaseManager().setDatabase(countMock);

      final count = await Order().query().groupBy(['status']).count();

      expect(count, 5);

      final sql = countMock.lastSql;
      expect(sql, startsWith('SELECT COUNT(*) as aggregate FROM ('));
      expect(sql, contains('SELECT "orders".* FROM "orders"'));
      expect(sql, contains('GROUP BY "status"'));
      expect(sql, endsWith(') as temp_table'));
    });

    test('sum() throws QueryException when used with groupBy', () async {
      expect(
        () => Order().query().groupBy(['customer_id']).sum('total'),
        throwsA(isA<QueryException>()),
      );
    });

    test('avg() throws QueryException when used with groupBy', () async {
      expect(
        () => Order().query().groupBy(['customer_id']).avg('score'),
        throwsA(isA<QueryException>()),
      );
    });

    test('min() throws QueryException when used with groupBy', () async {
      expect(
        () => Order().query().groupBy(['customer_id']).min('total'),
        throwsA(isA<QueryException>()),
      );
    });

    test('max() throws QueryException when used with groupBy', () async {
      expect(
        () => Order().query().groupBy(['customer_id']).max('total'),
        throwsA(isA<QueryException>()),
      );
    });
  });
}
