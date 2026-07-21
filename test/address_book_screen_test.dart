import 'package:flutter_test/flutter_test.dart';
import 'package:foodeez/views/screens/address_book_screen.dart';

void main() {
  group('Address book helpers', () {
    test('formats address details into a readable summary', () {
      final result = formatAddressSummary({
        'label': 'Home',
        'addressLine1': '202 Sri Nilayam',
        'addressLine2': 'Banjara Hills',
        'city': 'Hyderabad',
        'state': 'Telangana',
        'pincode': '500034',
      });

      expect(result, 'Home • 202 Sri Nilayam, Banjara Hills, Hyderabad, Telangana - 500034');
    });
  });
}
