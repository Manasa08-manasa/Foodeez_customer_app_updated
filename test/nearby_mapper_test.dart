import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodeez/data/remote_mappers.dart';

void main() {
  test('discoveryRestaurants maps nearby API payload', () {
    const raw = '''
{
  "data": [
    {
      "id": "89052db6-e17e-428b-9c1e-8bea861a9edd",
      "branchId": "89052db6-e17e-428b-9c1e-8bea861a9edd",
      "name": "dummi restaurant",
      "isOnline": true,
      "estimatedDeliveryTime": 30,
      "deliveryFee": 30,
      "restaurant": {
        "id": "8514ff3a-8cd7-4bbe-9689-3066f7847410",
        "name": "dummi restaurant",
        "cuisineTags": []
      }
    },
    {
      "id": "6170c9a7-0f1c-41ff-aaf4-3cf621f4a83a",
      "branchId": "6170c9a7-0f1c-41ff-aaf4-3cf621f4a83a",
      "name": "Lucky FastFood Express Main Branch",
      "isOnline": false,
      "estimatedDeliveryTime": 30,
      "deliveryFee": 30,
      "restaurant": {
        "id": "2b424dfc-bb85-4807-8694-62dec7e41485",
        "name": "Lucky FastFood Express",
        "cuisineTags": ["Chines"]
      }
    }
  ],
  "meta": {"total": 2}
}
''';
    final list = RemoteMappers.discoveryRestaurants(jsonDecode(raw));
    expect(list.length, 2);
    expect(list[0].name, 'dummi restaurant');
    expect(list[0].id, '89052db6-e17e-428b-9c1e-8bea861a9edd');
    expect(list[0].isOpen, isTrue);
    expect(list[1].name, 'Lucky FastFood Express Main Branch');
    expect(list[1].isOpen, isFalse);
  });
}
