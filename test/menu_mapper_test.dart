import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodeez/data/remote_mappers.dart';

void main() {
  test('menu maps categories payload and infers veg from item names', () {
    const raw = '''
{
  "branchId": "89052db6-e17e-428b-9c1e-8bea861a9edd",
  "categories": [
    {
      "name": "chicken-dishes",
      "displayName": "Chicken Dishes",
      "items": [
        {
          "id": "bd0e8335-5f06-477c-b04a-5402f801ae43",
          "name": "Schezwan Chicken",
          "description": null,
          "price": "280.00",
          "isVisible": true,
          "isInStock": true
        }
      ]
    },
    {
      "name": "veg",
      "displayName": "Veg Starters",
      "items": [
        {
          "id": "paneer-1",
          "name": "Paneer Tikka",
          "description": "Grilled cottage cheese",
          "price": 220,
          "isVisible": true,
          "isInStock": true
        }
      ]
    }
  ]
}
''';
    final items = RemoteMappers.menu(jsonDecode(raw));
    expect(items.length, 2);
    expect(items[0].section, 'Chicken Dishes');
    expect(items[0].name, 'Schezwan Chicken');
    expect(items[0].price, 280);
    expect(items[0].veg, isFalse);
    expect(items[1].section, 'Veg Starters');
    expect(items[1].veg, isTrue);
    expect(items[1].desc, 'Grilled cottage cheese');
  });

  test('restaurant maps brandDescription and address', () {
    final r = RemoteMappers.restaurant({
      'id': '89052db6-e17e-428b-9c1e-8bea861a9edd',
      'name': 'dummi restaurant',
      'address': 'hyderabad',
      'city': 'hyd',
      'brandDescription': 'Best dummi food nearby',
      'isOnline': true,
      'estimatedDeliveryTime': 30,
    });
    expect(r.description, 'Best dummi food nearby');
    expect(r.address, contains('hyderabad'));
  });
}
