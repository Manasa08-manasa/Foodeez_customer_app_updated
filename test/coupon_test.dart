import 'package:flutter_test/flutter_test.dart';

import 'package:foodeez/models/models.dart';
import 'package:foodeez/controllers/app_controller.dart';

void main() {
  group('Coupon.isApplicableTo', () {
    test('restaurant-scoped coupon only applies to its own restaurant', () {
      const c = Coupon(
        code: 'R1',
        title: 't',
        subtitle: 's',
        scope: CouponScope.restaurant,
        discountType: CouponDiscountType.flat,
        discountValue: 50,
        restaurantIds: ['paradise'],
        issuedBy: 'Paradise Biryani',
        gradient: [],
      );
      expect(c.isApplicableTo('paradise'), isTrue);
      expect(c.isApplicableTo('truffles'), isFalse);
    });

    test('global coupon with no restaurant whitelist applies everywhere', () {
      const c = Coupon(
        code: 'G1',
        title: 't',
        subtitle: 's',
        scope: CouponScope.global,
        discountType: CouponDiscountType.flat,
        discountValue: 20,
        issuedBy: 'Foodeez',
        gradient: [],
      );
      expect(c.isApplicableTo('paradise'), isTrue);
      expect(c.isApplicableTo('truffles'), isTrue);
    });

    test('global coupon scoped by admin to a subset only applies there', () {
      const c = Coupon(
        code: 'G2',
        title: 't',
        subtitle: 's',
        scope: CouponScope.global,
        discountType: CouponDiscountType.flat,
        discountValue: 20,
        restaurantIds: ['paradise', 'barbeque'],
        issuedBy: 'Foodeez',
        gradient: [],
      );
      expect(c.isApplicableTo('paradise'), isTrue);
      expect(c.isApplicableTo('barbeque'), isTrue);
      expect(c.isApplicableTo('truffles'), isFalse);
    });

    test('discountFor respects minOrderValue and percent cap', () {
      const c = Coupon(
        code: 'P1',
        title: 't',
        subtitle: 's',
        scope: CouponScope.global,
        discountType: CouponDiscountType.percent,
        discountValue: 50,
        maxDiscount: 100,
        minOrderValue: 200,
        issuedBy: 'Foodeez',
        gradient: [],
      );
      expect(c.discountFor(199), 0); // below minimum order
      expect(c.discountFor(300), 100); // 50% of 300 = 150, capped at 100
      expect(c.discountFor(220), 100); // 50% of 220 = 110, capped at 100
    });
  });

  group('AppController coupon scoping at checkout', () {
    test('only shows coupons valid for the current restaurant', () {
      final app = AppController();
      app.rid = 'paradise';
      final codes = app.couponsForCurrentRestaurant.map((c) => c.code).toSet();
      expect(codes.contains('PARADISE20'), isTrue, reason: 'restaurant-issued coupon should show for its own restaurant');
      expect(codes.contains('TRUFFLE15'), isFalse, reason: "another restaurant's coupon must not show here");
      expect(codes.contains('WELCOME50'), isTrue, reason: 'unscoped global coupon should show everywhere');

      app.rid = 'truffles';
      final codesAtTruffles = app.couponsForCurrentRestaurant.map((c) => c.code).toSet();
      expect(codesAtTruffles.contains('PARADISE20'), isFalse);
      expect(codesAtTruffles.contains('TRUFFLE15'), isTrue);
    });

    test('applying a coupon then switching to an ineligible restaurant clears it', () {
      final app = AppController();
      app.rid = 'paradise';
      app.applyCoupon('PARADISE20');
      expect(app.appliedCoupon?.code, 'PARADISE20');

      app.openRest('truffles');
      expect(app.appliedCouponCode, isNull, reason: "a restaurant-only coupon must not survive switching to a different restaurant's order");
    });

    test('discount is zero once the applied coupon no longer applies here', () {
      final app = AppController();
      app.rid = 'paradise';
      app.applyCoupon('TRUFFLE15'); // not valid for paradise, simulating stale/tampered state
      expect(app.appliedCoupon, isNull);
      expect(app.discount, 0);
    });
  });
}
