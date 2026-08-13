import 'package:flutter_test/flutter_test.dart';
import 'package:foodeez/core/utils/order_status_utils.dart';
import 'package:foodeez/data/remote_mappers.dart';

void main() {
  test('pastOrder maps orderNumber, createdAt and status like website', () {
    final order = RemoteMappers.pastOrder({
      'id': '89052db6-e17e-428b-9c1e-8bea861a9edd',
      'orderNumber': 'FDZ-2026-00042',
      'status': 'ON_THE_WAY',
      'grandTotal': 420,
      'createdAt': '2026-08-13T11:28:00.000Z',
      'restaurantName': 'dummi restaurant',
      'items': [
        {'name': 'Chicken Biryani', 'quantity': 1},
        {'name': 'Coke', 'quantity': 2},
      ],
    });

    expect(order.orderId, '89052db6-e17e-428b-9c1e-8bea861a9edd');
    expect(order.orderNumber, 'FDZ-2026-00042');
    expect(order.status, 'ON_THE_WAY');
    expect(order.restaurantName, 'dummi restaurant');
    expect(order.total, 420);
    expect(order.items, contains('Chicken Biryani'));
    expect(order.when, contains('2026'));
    expect(OrderStatusUtils.isActive(order.status), isTrue);
    expect(OrderStatusUtils.label(order.status), 'On the Way');
  });

  test('READY aliases to READY_FOR_PICKUP', () {
    expect(OrderStatusUtils.normalize('READY'), 'READY_FOR_PICKUP');
    expect(OrderStatusUtils.normalize('REJECTED'), 'CANCELLED');
  });
}
