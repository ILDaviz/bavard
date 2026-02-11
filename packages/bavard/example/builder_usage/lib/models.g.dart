// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// FillableGenerator
// **************************************************************************

mixin $ProductFillable on Model {
  /// FILLABLE
  @override
  List<String> get fillable => const ['name', 'price'];

  /// GUARDED
  @override
  List<String> get guarded => const ['id', 'stock'];

  /// CASTS
  @override
  Map<String, dynamic> get casts => {
        'id': 'id',
        'name': 'string',
        'price': 'double',
        'stock': 'int',
      };

  /// Accessor for [name] (DB: name)
  String get name {
    return getAttribute('name');
  }

  set name(String value) => setAttribute('name', value);

  /// Accessor for [price] (DB: price)
  double get price {
    return getAttribute('price');
  }

  set price(double value) => setAttribute('price', value);

  /// Accessor for [stock] (DB: stock)
  int get stock {
    return getAttribute('stock');
  }

  set stock(int value) => setAttribute('stock', value);
}

// **************************************************************************
// PivotGenerator
// **************************************************************************

mixin $OrderProduct on Pivot {
  /// Accessor for [quantity] (DB: quantity)
  int get quantity => get(OrderProduct.schema.quantity);
  set quantity(int value) => set(OrderProduct.schema.quantity, value);

  /// Accessor for [discount] (DB: discount)
  double get discount => get(OrderProduct.schema.discount);
  set discount(double value) => set(OrderProduct.schema.discount, value);

  static List<SchemaColumn> get columns =>
      [OrderProduct.schema.quantity, OrderProduct.schema.discount];
}
