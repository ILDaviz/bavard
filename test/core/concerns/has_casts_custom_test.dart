import 'dart:convert';
import 'package:test/test.dart';
import 'package:bavard/bavard.dart';
import 'package:bavard/testing.dart';

class Address {
  final String street;
  final String city;

  Address(this.street, this.city);

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(json['street'], json['city']);
  }

  Map<String, dynamic> toJson() => {'street': street, 'city': city};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          city == other.city;

  @override
  int get hashCode => street.hashCode ^ city.hashCode;
}

class AddressCast implements AttributeCast<Address?, String?> {
  @override
  Address? get(String? rawValue, Map<String, dynamic> attributes) {
    if (rawValue == null) return null;
    return Address.fromJson(jsonDecode(rawValue));
  }

  @override
  String? set(Address? value, Map<String, dynamic> attributes) {
    if (value == null) return null;
    return jsonEncode(value.toJson());
  }
}

class CustomCastModel extends Model {
  @override
  String get table => 'custom_cast_models';

  CustomCastModel([super.attributes]);

  @override
  CustomCastModel fromMap(Map<String, dynamic> map) => CustomCastModel(map);

  @override
  Map<String, dynamic> get casts => {
    'address': AddressCast(),
  };

  Address? get address => getAttribute<Address>('address');
  set address(Address? value) => setAttribute('address', value);
}

void main() {
  setUp(() {
    DatabaseManager().setDatabase(MockDatabaseSpy());
  });

  group('Custom Attribute Casts', () {
    test('getAttribute returns transformed value', () {
      final model = CustomCastModel({
        'address': '{"street":"123 Main St","city":"New York"}'
      });

      expect(model.address, isA<Address>());
      expect(model.address?.street, '123 Main St');
      expect(model.address?.city, 'New York');
    });

    test('setAttribute stores transformed value', () {
      final model = CustomCastModel();
      final address = Address('456 Market St', 'San Francisco');
      
      model.address = address;

      expect(model.attributes['address'], isA<String>());
      expect(model.attributes['address'], contains('456 Market St'));
      expect(model.attributes['address'], contains('San Francisco'));
      
      // Verify we can get it back
      expect(model.address, equals(address));
    });

    test('Works with null values', () {
       final model = CustomCastModel({'address': null});
       expect(model.address, isNull);

       model.address = null;
       expect(model.attributes['address'], isNull);
    });

    test('Works with dehydrate', () {
       final model = CustomCastModel();
       final address = Address('789 Broad St', 'Chicago');
       model.address = address;
       
       final dehydrated = model.dehydrateAttributes();
       expect(dehydrated['address'], isA<String>());
       expect(dehydrated['address'], contains('Chicago'));
    });
  });
}
