import 'package:test/test.dart';
import '../lib/models.dart';
import 'package:bavard/schema.dart';

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
}
