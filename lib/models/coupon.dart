import 'dart:math';
import 'package:flutter/material.dart';

/// Who is allowed to create/approve a coupon and where it is valid.
/// - `restaurant`: created and approved by a single restaurant — only valid
///   when ordering from that restaurant (`restaurantIds` holds its id).
/// - `global`: created by Foodeez's admin/technical team. Valid everywhere
///   if `restaurantIds` is empty, or only at the listed restaurants if the
///   admin scoped it to a subset.
enum CouponScope { restaurant, global }

enum CouponDiscountType { flat, percent }

class Coupon {
  final String code;
  final String title;
  final String subtitle;
  final CouponScope scope;
  final CouponDiscountType discountType;
  final int discountValue; // rupees for flat, percentage points for percent
  final int maxDiscount; // cap for percent-based coupons, 0 = uncapped
  final int minOrderValue;
  final List<String> restaurantIds; // restaurant scope: exactly who issued it; global scope: whitelist subset, empty = all restaurants
  final String issuedBy; // display label, e.g. "Paradise Biryani" or "Foodeez"
  final List<Color> gradient;

  const Coupon({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.scope,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount = 0,
    this.minOrderValue = 0,
    this.restaurantIds = const [],
    required this.issuedBy,
    required this.gradient,
  });

  /// A restaurant-issued coupon only ever applies to its own restaurant(s).
  /// A global coupon applies everywhere unless the admin scoped it to a
  /// specific subset of restaurants.
  bool isApplicableTo(String restaurantId) {
    if (scope == CouponScope.restaurant) return restaurantIds.contains(restaurantId);
    return restaurantIds.isEmpty || restaurantIds.contains(restaurantId);
  }

  bool meetsMinOrder(int itemsTotal) => itemsTotal >= minOrderValue;

  int discountFor(int itemsTotal) {
    if (!meetsMinOrder(itemsTotal)) return 0;
    if (discountType == CouponDiscountType.flat) return discountValue;
    final pct = (itemsTotal * discountValue / 100).round();
    return maxDiscount > 0 ? min(pct, maxDiscount) : pct;
  }
}
