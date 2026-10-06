import 'package:test/test.dart';
import '../lib/models.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

void main() {
  group('Product (Fillable Generator)', () {
    test('Fillable and Guarded lists are correct', () {
      final product = Product();

      expect(product.fillable, containsAll(['name', 'price']));
      expect(product.fillable, isNot(contains('stock')));
      expect(product.fillable, isNot(contains('id')));

      expect(product.guarded, containsAll(['id', 'stock']));
    });

    test('Casts map is correct', () {
      final product = Product();
      expect(product.casts['name'], equals('string'));
      expect(product.casts['price'], equals('double'));
      expect(product.casts['stock'], equals('int'));
    });

    test('Type-safe accessors work', () {
      final product = Product();

      product.name = 'MacBook Pro';
      product.price = 1999.99;
      product.stock = 10;

      expect(product.getAttribute('name'), equals('MacBook Pro'));
      expect(product.getAttribute('price'), equals(1999.99));
      expect(product.getAttribute('stock'), equals(10));

      expect(product.name, equals('MacBook Pro'));
      expect(product.price, equals(1999.99));
      expect(product.stock, equals(10));
    });
  });

  group('OrderProduct (Pivot Generator)', () {
    test('Schema columns are generated', () {
      expect($OrderProduct.columns, hasLength(2));

      expect($OrderProduct.columns.first, isA<SchemaColumn>());
    });

    test('Type-safe accessors work', () {
      final pivot = OrderProduct();

      pivot.quantity = 5;
      pivot.discount = 0.1;

      expect(pivot.attributes['quantity'], equals(5));
      expect(pivot.attributes['discount'], equals(0.1));

      expect(pivot.quantity, equals(5));
      expect(pivot.discount, equals(0.1));
    });
  });

  group('Generated getRelation dispatch', () {
    setUp(() {
      DatabaseManager().setDatabase(MockDatabaseSpy());
    });

    test('eager loads belongsToMany without handwritten getRelation',
        () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "products"': [
          {'id': 1, 'name': 'MacBook Pro', 'price': 1999.99, 'stock': 10},
        ],
        'FROM "order_product"': [
          {'product_id': 1, 'order_id': 7, 'quantity': 2, 'discount': 0.1},
        ],
        'FROM "orders"': [
          {'id': 7, 'total': 3599.98},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final products = await Product()
          .query()
          .withRelations(['orders'])
          .get();

      final product = products.first;
      final orders = product.getRelationList<Order>('orders');

      expect(orders, hasLength(1));
      expect(orders.first.id, equals(7));
      expect(orders.first.total, equals(3599.98));

      // Typed pivot hydration flows through the generated dispatch too.
      final pivot = orders.first.getPivot<OrderProduct>()!;
      expect(pivot.quantity, equals(2));
      expect(pivot.discount, equals(0.1));
    });

    test('eager loads the inverse direction (Order -> products)', () async {
      final mockDb = MockDatabaseSpy([], {
        'FROM "orders"': [
          {'id': 7, 'total': 3599.98},
        ],
        'FROM "order_product"': [
          {'order_id': 7, 'product_id': 1, 'quantity': 2, 'discount': 0.1},
        ],
        'FROM "products"': [
          {'id': 1, 'name': 'MacBook Pro', 'price': 1999.99, 'stock': 10},
        ],
      });
      DatabaseManager().setDatabase(mockDb);

      final orders = await Order().query().withRelations(['products']).get();

      final order = orders.first;
      final products = order.getRelationList<Product>('products');

      expect(products, hasLength(1));
      expect(products.first.name, equals('MacBook Pro'));
    });

    test('unknown relation names still fall back to the default (null)',
        () async {
      final product = Product();
      expect(product.getRelation('nonexistent'), isNull);
    });
  });
}
