import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodeez/controllers/app_controller.dart';
import 'package:foodeez/controllers/providers.dart';
import 'package:foodeez/data/mock_data.dart' as mock_data;
import 'package:foodeez/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cart count starts empty until items are added', () {
    final app = AppController();

    expect(app.cartCount, 0);
    expect(app.hasCart, isFalse);
  });

  testWidgets('home screen shows the real nearby restaurant count', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FoodeezApp()));
    await tester.pump();

    final app = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(appControllerProvider);
    app.setTab('home');
    await tester.pump();

    final countText = tester.widget<Text>(find.textContaining('restaurants around you')).data;
    expect(countText, '${mock_data.restaurants.length} restaurants around you');
  });
}
