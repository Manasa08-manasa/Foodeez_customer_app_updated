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

  test('menu maps website vegetarian flags for both filters', () {
    final items = RemoteMappers.menu({
      'categories': [
        {
          'name': 'Main Course',
          'items': [
            {'id': 'veg-1', 'name': 'Rice', 'is_vegetarian': true},
            {'id': 'nonveg-1', 'name': 'Chicken', 'isVegetarian': false},
          ],
        },
      ],
    });

    expect(items.where((item) => item.veg).map((item) => item.id), ['veg-1']);
    expect(items.where((item) => !item.veg).map((item) => item.id), [
      'nonveg-1',
    ]);
  });

  test('menu infers vegetarian items from live category names', () {
    final items = RemoteMappers.menu({
      'branchId': '9e5c4857-9293-4b23-9cd5-0c6db93788ba',
      'categories': [
        {
          'name': 'non-veg-noodles',
          'displayName': 'NON - VEG NOODLES',
          'items': [
            {'id': 'egg-noodles', 'name': 'Egg Noodles'},
          ],
        },
        {
          'name': 'fresh-juices',
          'displayName': 'Fresh Juices',
          'items': [
            {'id': 'mosambi', 'name': 'Mosambi Juice'},
          ],
        },
      ],
    });

    expect(items.first.veg, isFalse);
    expect(items.last.veg, isTrue);
  });

  test('menu keeps spaced non-veg labels out of the veg filter', () {
    final items = RemoteMappers.menu({
      'categories': [
        {
          'displayName': 'NON - VEG STARTERS',
          'items': [
            {'id': 'chicken', 'name': 'Chicken Majestic'},
          ],
        },
        {
          'displayName': 'LUNCH BOX',
          'items': [
            {'id': 'non-veg-box', 'name': 'NON - VEG'},
            {'id': 'veg-box', 'name': 'VEG'},
          ],
        },
      ],
    });

    expect(items.where((item) => item.veg).map((item) => item.id), ['veg-box']);
    expect(items.where((item) => !item.veg).map((item) => item.id), [
      'chicken',
      'non-veg-box',
    ]);
  });

  test('category labels take priority over item names', () {
    final items = RemoteMappers.menu({
      'categories': [
        {
          'displayName': 'VEG CURRIES',
          'items': [
            {'id': 'veg-category', 'name': 'Chicken Styled Veg Curry'},
          ],
        },
        {
          'displayName': 'NON - VEG CURRIES',
          'items': [
            {'id': 'nonveg-category', 'name': 'Veg Curry With Chicken'},
          ],
        },
        {
          'displayName': 'PASTAS',
          'items': [
            {'id': 'plain-pasta', 'name': 'Alfredo Pasta'},
          ],
        },
      ],
    });

    expect(items.where((item) => item.veg).map((item) => item.id), [
      'veg-category',
      'plain-pasta',
    ]);
    expect(items.where((item) => !item.veg).map((item) => item.id), [
      'nonveg-category',
    ]);
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
