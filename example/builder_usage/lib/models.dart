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
}

@bavardPivot
class OrderProduct extends Pivot with $OrderProduct {
  OrderProduct([Map<String, dynamic> attributes = const {}]) : super(Map.from(attributes));

  static const schema = (
    quantity: IntColumn('quantity'),
    discount: DoubleColumn('discount'),
  );
}

class Order extends Model {
  Order([super.attributes]);

  @override
  String get table => 'orders';

  @override
  Order fromMap(Map<String, dynamic> map) => Order(map);
}