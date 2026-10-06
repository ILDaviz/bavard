import 'package:bavard/bavard.dart';
import 'package:bavard/schema.dart';
import 'package:bavard/src/generators/annotations.dart';

part 'models.g.dart';

@fillable
class Product extends Model with $ProductFillable {
  static const schema = (
    id: IdColumn(),
    name: TextColumn('name'),
    price: DoubleColumn('price'),
    stock: IntColumn('stock', isGuarded: true),
  );

  Product([super.attributes]);

  @override
  String get table => 'products';

  @override
  Product fromMap(Map<String, dynamic> map) => Product(map);

  /// Relationship defined WITHOUT a handwritten `getRelation` override:
  /// the `@fillable` generator dispatches it automatically.
  BelongsToMany<Order> orders() {
    return belongsToMany(
      Order.new,
      'order_product',
      foreignPivotKey: 'product_id',
      relatedPivotKey: 'order_id',
    ).using(OrderProduct.new, $OrderProduct.columns);
  }
}

@bavardPivot
class OrderProduct extends Pivot with $OrderProduct {
  OrderProduct([Map<String, dynamic> attributes = const {}])
      : super(Map.from(attributes));

  static const schema = (
    quantity: IntColumn('quantity'),
    discount: DoubleColumn('discount'),
  );
}

@fillable
class Order extends Model with $OrderFillable {
  static const schema = (
    id: IdColumn(),
    total: DoubleColumn('total'),
  );

  Order([super.attributes]);

  @override
  String get table => 'orders';

  @override
  Order fromMap(Map<String, dynamic> map) => Order(map);

  /// Relationship defined WITHOUT a handwritten `getRelation` override:
  /// the `@fillable` generator dispatches it automatically.
  BelongsToMany<Product> products() {
    return belongsToMany(
      Product.new,
      'order_product',
      foreignPivotKey: 'order_id',
      relatedPivotKey: 'product_id',
    ).using(OrderProduct.new, $OrderProduct.columns);
  }
}
