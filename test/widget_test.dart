import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodeez/main.dart';
import 'package:foodeez/controllers/app_controller.dart';
import 'package:foodeez/controllers/providers.dart';

void main() {
  testWidgets('App launches to onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FoodeezApp()));
    await tester.pump();

    expect(find.text('TAP · EAT · REPEAT'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Continue navigates to Home', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FoodeezApp()));
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Every screen renders without layout exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FoodeezApp()));
    await tester.pump();

    final app = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(appControllerProvider);

    const screens = [
      'home',
      'search',
      'list',
      'menu',
      'cart',
      'payment',
      'tracking',
      'orders',
      'dining',
      'booking',
      'booking-done',
      'account',
      'help',
      'chat',
      'profile',
      'coupons',
    ];

    for (final screen in screens) {
      app.push(screen);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'Exception while rendering "$screen"');
    }
  });

  testWidgets('Back buttons over hero images hug the top, not the middle', (WidgetTester tester) async {
    // Regression test: Row/Column inside a Stack(fit: StackFit.expand) hero
    // defaults to centering its children vertically unless explicitly
    // wrapped in Align(topCenter) or given crossAxisAlignment.start — this
    // once pushed back buttons into the middle of tall hero images.
    await tester.pumpWidget(const ProviderScope(child: FoodeezApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final app = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(appControllerProvider);

    const screensWithHeroBackButton = ['menu', 'profile', 'tracking', 'booking'];

    for (final screen in screensWithHeroBackButton) {
      app.push(screen);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final rect = tester.getRect(find.byIcon(Icons.arrow_back_ios_new).first);
      expect(rect.top, lessThan(80), reason: 'Back button on "$screen" is too far from the top (top=${rect.top})');
    }
  });

  testWidgets('Short-content screens fill the viewport instead of centering', (WidgetTester tester) async {
    // Regression test: AnimatedSwitcher's default layoutBuilder wraps the
    // active screen in a Stack without StackFit.expand, giving it loose
    // constraints. A screen whose content is shorter than the viewport (e.g.
    // the Orders "Dining Out" tab with a single booking card) would then
    // shrink to its natural height and get vertically centered by the Stack,
    // pushing all of its content down and reading as blank space above it.
    await tester.pumpWidget(const ProviderScope(child: FoodeezApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final app = ProviderScope.containerOf(tester.element(find.byType(MaterialApp))).read(appControllerProvider);

    app.push('orders');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Dining Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final titleRect = tester.getRect(find.text('Your orders'));
    expect(titleRect.top, lessThan(20), reason: 'Orders title should hug the top, not be centered (top=${titleRect.top})');
  });
}
