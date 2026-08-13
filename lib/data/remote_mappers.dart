import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/utils/order_status_utils.dart';
import '../models/models.dart';
import '../services/api_config.dart';
import '../theme.dart';

/// JSON → model mappers for customer API responses.
///
/// Backend payloads are typically wrapped ({ success, data: … }) and field
/// names can vary slightly between endpoints, so every mapper here is
/// deliberately tolerant: it probes a list of likely keys and falls back to
/// sensible defaults instead of throwing.
class RemoteMappers {
  RemoteMappers._();

  // ── envelope helpers ─────────────────────────────────────────────────────

  /// Unwraps `{data: …}` envelopes (possibly nested) down to the payload.
  static dynamic unwrap(dynamic res) {
    var v = res;
    for (var i = 0; i < 3 && v is Map && v.containsKey('data'); i++) {
      v = v['data'];
    }
    return v;
  }

  /// Digs a List out of a response: the payload itself, or the first of
  /// [keys] holding a List inside it.
  static List<Map<String, dynamic>> unwrapList(dynamic res, List<String> keys) {
    final v = unwrap(res);
    dynamic list;
    if (v is List) {
      list = v;
    } else if (v is Map) {
      for (final k in keys) {
        if (v[k] is List) {
          list = v[k];
          break;
        }
      }
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static String _str(Map m, List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  static double _num(Map m, List<String> keys, [double fallback = 0]) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toDouble();
      final parsed = double.tryParse(v?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool _bool(Map m, List<String> keys, [bool fallback = false]) {
    for (final k in keys) {
      final v = m[k];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
    }
    return fallback;
  }

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthKm * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static String? _firstPhotoUrl(dynamic photos) {
    if (photos is! List || photos.isEmpty) return null;
    final first = photos.first;
    if (first is String && first.isNotEmpty) return first;
    if (first is Map) {
      final url = _str(first, [
        'url',
        'imageUrl',
        'image_url',
        'src',
        'path',
        'key',
      ]);
      return url.isEmpty ? null : url;
    }
    return null;
  }

  /// Website-compatible list extract for discovery nearby/search/trending.
  /// Mirrors `getRawResultArray(res?.data)` + normalize(branchId).
  static List<Restaurant> discoveryRestaurants(dynamic res) {
    // Axios uses res.data; our client already returns the JSON body.
    // Try body, then body.data (same keys the web client probes).
    var candidates = <dynamic>[res, unwrap(res)];
    if (res is Map && res['data'] != null) candidates.add(res['data']);

    List<Map<String, dynamic>> raw = const [];
    for (final c in candidates) {
      if (c is List) {
        raw = c
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (raw.isNotEmpty) break;
      }
      if (c is Map) {
        for (final k in [
          'restaurants',
          'branches',
          'results',
          'items',
          'data',
        ]) {
          final v = c[k];
          if (v is List && v.isNotEmpty) {
            raw = v
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            break;
          }
        }
        if (raw.isNotEmpty) break;
      }
    }

    final out = <Restaurant>[];
    final seen = <String>{};
    for (final j in raw) {
      final branchId = _str(j, ['branchId', 'id', '_id', 'restaurantId']);
      if (branchId.isEmpty || branchId == 'undefined') continue;
      // Prefer branchId as the app restaurant id (menu/details routes use it).
      final normalized = Map<String, dynamic>.from(j);
      normalized['id'] = branchId;
      normalized['branchId'] = branchId;
      // Live nearby payload nests brand fields under `restaurant`.
      final nested = j['restaurant'];
      if (nested is Map) {
        final n = Map<String, dynamic>.from(nested);
        normalized['name'] ??= n['name'];
        normalized['cuisineTags'] ??= n['cuisineTags'];
        normalized['cuisines'] ??= n['cuisines'] ?? n['cuisine'];
        normalized['storePhotos'] ??= n['storePhotos'];
        normalized['brandDescription'] ??= n['brandDescription'];
        normalized['description'] ??= n['brandDescription'] ?? n['description'];
        normalized['restaurantId'] ??= n['id'];
        normalized['coverPhoto'] ??= n['coverPhoto'];
        normalized['logoUrl'] ??= n['logoUrl'];
        normalized['avgCostForTwo'] ??= n['avgCostForTwo'];
        normalized['averageCostMin'] ??= n['averageCostMin'];
        normalized['offersAvailable'] ??= n['offersAvailable'];
        normalized['maxGuestsPerReservation'] ??= n['maxGuestsPerReservation'];
      }
      normalized['imageUrl'] =
          j['imageUrl'] ??
          j['image_url'] ??
          j['coverPhotoUrl'] ??
          normalized['coverPhoto'] ??
          j['coverPhoto'] ??
          j['thumbnail'] ??
          j['photo'] ??
          j['image'] ??
          normalized['logoUrl'] ??
          _firstPhotoUrl(normalized['storePhotos']);
      final r = restaurant(normalized);
      if (seen.add(r.id)) out.add(r);
    }
    return out;
  }

  // ── Restaurant (discovery/nearby · search · trending · details) ─────────

  static Restaurant restaurant(Map<String, dynamic> j) {
    final cuisinesRaw =
        j['cuisines'] ?? j['cuisine'] ?? j['cuisineTypes'] ?? j['cuisineTags'];
    String cuisines;
    if (cuisinesRaw is List) {
      cuisines = cuisinesRaw
          .map((e) {
            if (e is Map) {
              return (e['name'] ?? e['label'] ?? e['tag'] ?? e['title'] ?? '')
                  .toString();
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .join(' · ');
      if (cuisines.isEmpty) cuisines = 'Multi-cuisine';
    } else {
      cuisines = cuisinesRaw?.toString() ?? 'Multi-cuisine';
    }

    final mins = _num(j, [
      'deliveryTime',
      'estimatedDeliveryTime',
      'avgDeliveryTime',
      'etaMinutes',
    ], 0);
    final time = mins > 0
        ? '${mins.round()}-${mins.round() + 5} min'
        : _str(j, ['deliveryTimeText', 'eta'], '30-35 min');

    final priceForTwo = _num(j, [
      'priceForTwo',
      'costForTwo',
      'avgCostForTwo',
      'averageCostMin',
    ], 0);
    var distKm = _num(j, ['distance', 'distanceKm', 'distanceInKm'], 0);
    if (distKm <= 0) {
      final rLat = _num(j, ['latitude', 'lat'], 0);
      final rLng = _num(j, ['longitude', 'lng', 'lon'], 0);
      if (rLat != 0 && rLng != 0) {
        distKm = _haversineKm(ApiConfig.lat, ApiConfig.lng, rLat, rLng);
      }
    }
    final deliveryFee = _num(j, ['deliveryFee', 'delivery_fee'], -1);

    final gallery = (j['gallery'] ?? j['images'] ?? j['galleryImages']);
    final galleryKeys = gallery is List
        ? gallery.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    return Restaurant(
      id: _str(j, ['id', '_id', 'branchId', 'restaurantId'], 'unknown'),
      name: _str(j, ['name', 'branchName', 'restaurantName'], 'Restaurant'),
      cuisines: cuisines,
      description: _str(j, [
        'brandDescription',
        'description',
        'about',
        'bio',
      ], ''),
      address: () {
        final line = _str(j, ['address', 'addressLine1', 'fullAddress'], '');
        final city = _str(j, ['city'], '');
        if (line.isEmpty) return city;
        if (city.isEmpty || line.toLowerCase().contains(city.toLowerCase())) {
          return line;
        }
        return '$line, $city';
      }(),
      rating: _num(j, ['rating', 'avgRating', 'averageRating'], 4.0),
      time: time,
      price: priceForTwo > 0
          ? '₹${priceForTwo.round()} for two'
          : '₹300 for two',
      dist: distKm > 0 ? '${distKm.toStringAsFixed(1)} km' : '—',
      offer: _str(
        j,
        ['offer', 'offerText', 'promoText'],
        _bool(j, ['offersAvailable'])
            ? 'Offers available'
            : (deliveryFee >= 0
                  ? (deliveryFee == 0
                        ? 'Free delivery'
                        : 'Delivery ₹${deliveryFee.round()}')
                  : ''),
      ),
      veg: _bool(j, ['isVeg', 'veg', 'isPureVeg']),
      photoKey:
          resolveMediaUrl(
            _str(j, [
              'imageUrl',
              'image_url',
              'coverPhotoUrl',
              'coverImage',
              'image',
              'photo',
              'banner',
              'thumbnail',
            ], ''),
          ) ??
          _firstPhotoUrl(j['storePhotos']) ??
          _firstPhotoUrl(j['gallery']) ??
          'biryani',
      isOpen: _bool(j, ['isOnline', 'isOpen', 'isActive', 'open'], true),
      galleryPhotoKeys: galleryKeys,
      maxGuests: _num(j, [
        'maxGuestsPerReservation',
        'maxGuests',
      ], 20).round().clamp(1, 100),
    );
  }

  // ── MenuItem (discovery/restaurants/{id}/menu) ───────────────────────────

  /// Infer veg when API omits `isVeg` (common on INT) — mirrors website.
  static bool _inferIsVeg({
    required Map m,
    required String name,
    required String section,
  }) {
    final raw = m['isVeg'] ??
        m['is_veg'] ??
        m['veg'] ??
        m['vegetarian'] ??
        m['foodType'] ??
        m['type'];
    if (raw is bool) return raw;
    if (raw != null) {
      final s = raw.toString().toLowerCase().trim();
      if (s.contains('non') || s == 'n' || s == '0' || s == 'false') {
        return false;
      }
      if (s.contains('veg') || s == 'y' || s == '1' || s == 'true') {
        return true;
      }
    }

    final hay = '$name $section'.toLowerCase();
    const nonVeg = [
      'non-veg',
      'non veg',
      'nonveg',
      'chicken',
      'mutton',
      'goat',
      'lamb',
      'pork',
      'beef',
      'fish',
      'prawn',
      'shrimp',
      'lobster',
      'egg',
      'meat',
      'keema',
      'kebab',
      'haleem',
      'butter chicken',
    ];
    for (final k in nonVeg) {
      if (hay.contains(k)) return false;
    }
    const veg = [
      'paneer',
      'veg ',
      ' vegetable',
      'dal',
      'dosa',
      'idli',
      'samosa',
      'gulab',
      'lassi',
      'roti',
      'naan',
      'paratha',
      'salad',
      'mushroom',
      'aloo',
      'gobi',
      'palak',
    ];
    for (final k in veg) {
      if (hay.contains(k)) return true;
    }
    // Default non-veg when unknown so "Non Veg" filter still has content;
    // pure-veg restaurants usually set isVeg on items.
    return false;
  }

  /// A menu response is either a flat list of items or a list of
  /// category/section groups each holding `items`. Handles both.
  static List<MenuItem> menu(dynamic res) {
    // Live API: { branchId, categories: [...] } (no data envelope).
    final payload = unwrap(res);
    final out = <MenuItem>[];

    void addItem(Map item, String section) {
      final m = Map<String, dynamic>.from(item);
      final isVisible = _bool(m, ['isVisible', 'visible'], true);
      if (!isVisible) return;

      final isInStock = _bool(m, ['isInStock', 'inStock', 'available'], true);
      final autoOutOfStock = _bool(m, ['autoOutOfStock'], false);
      final name = _str(m, ['name', 'itemName'], 'Item');
      final desc = _str(m, [
        'description',
        'desc',
        'itemDescription',
        'shortDescription',
      ], '');

      out.add(
        MenuItem(
          id: _str(m, ['id', '_id', 'menuItemId'], 'item-${out.length}'),
          section: section,
          name: name,
          desc: desc,
          price: _num(m, ['price', 'sellingPrice', 'amount'], 0).round(),
          veg: _inferIsVeg(m: m, name: name, section: section),
          rating: _num(m, ['rating', 'avgRating'], 4.2),
          ratingsCount: _str(m, [
            'ratingsCount',
            'ratingCount',
            'totalRatings',
          ], ''),
          bestseller: _bool(m, ['isBestseller', 'bestseller', 'isRecommended']),
          photoKey:
              resolveMediaUrl(
                _str(m, [
                  'imageUrl',
                  'image_url',
                  'image',
                  'photo',
                  'thumbnail',
                ], ''),
              ) ??
              'biryani',
          isInStock: isInStock,
          autoOutOfStock: autoOutOfStock,
          isVisible: isVisible,
        ),
      );
    }

    dynamic groups = payload;
    if (payload is Map) {
      groups =
          payload['categories'] ??
          payload['menu'] ??
          payload['sections'] ??
          payload['items'] ??
          payload['data'];
    }
    if (groups is! List) return out;

    for (final g in groups.whereType<Map>()) {
      final items = g['items'] ?? g['menuItems'];
      if (items is List) {
        final section = _str(g, [
          'displayName',
          'name',
          'category',
          'categoryName',
          'section',
          'title',
        ], 'Recommended');
        for (final it in items.whereType<Map>()) {
          addItem(it, section);
        }
      } else {
        addItem(
          g,
          _str(g, [
            'displayName',
            'category',
            'categoryName',
            'section',
          ], 'Recommended'),
        );
      }
    }
    return out;
  }

  // ── Coupon (coupons/catalog · coupons/restaurant/{id}) ──────────────────

  static const List<List<Color>> _couponGradients = [
    [AppColors.accent, AppColors.accentLight],
    [AppColors.gold, Color(0xFF9C7614)],
    [AppColors.accentDeep, Color(0xFF7A2E56)],
    [AppColors.accent, AppColors.accentDeep],
  ];

  static Coupon coupon(Map<String, dynamic> j, int index) {
    // Backend types: FLAT | PERCENTAGE | FREE_DELIVERY | CASHBACK
    final type = _str(j, ['type', 'discountType'], 'FLAT').toUpperCase();
    final isPercent = type == 'PERCENTAGE';
    final value = _num(j, ['discountValue', 'value'], 0).round();

    final ridsRaw = j['restaurantIds'] ?? j['restaurants'];
    final rids = ridsRaw is List
        ? ridsRaw.map((e) => e.toString()).toList()
        : <String>[];
    final singleRid = _str(j, ['restaurantId'], '');
    if (singleRid.isNotEmpty && !rids.contains(singleRid)) rids.add(singleRid);

    final isRestaurantScoped =
        _str(j, ['scope'], '').toUpperCase() == 'RESTAURANT' ||
        (singleRid.isNotEmpty && _str(j, ['scope'], '').isEmpty);

    final title = _str(
      j,
      ['title'],
      isPercent
          ? '$value% OFF'
          : (type == 'FREE_DELIVERY' ? 'Free Delivery' : '₹$value OFF'),
    );

    return Coupon(
      code: _str(j, ['code', 'couponCode'], 'COUPON'),
      title: title,
      subtitle: _str(j, ['description', 'subtitle'], ''),
      scope: isRestaurantScoped ? CouponScope.restaurant : CouponScope.global,
      discountType: isPercent
          ? CouponDiscountType.percent
          : CouponDiscountType.flat,
      discountValue: value,
      maxDiscount: _num(j, ['maxDiscountCap', 'maxDiscount'], 0).round(),
      minOrderValue: _num(j, ['minOrderValue', 'minOrder'], 0).round(),
      restaurantIds: rids,
      issuedBy: _str(j, ['issuedBy', 'restaurantName'], 'Foodeez'),
      gradient: _couponGradients[index % _couponGradients.length],
    );
  }

  // ── PastOrder (customer/orders history) ──────────────────────────────────

  static PastOrder pastOrder(Map<String, dynamic> j) {
    final itemsRaw = j['items'] ?? j['orderItems'];
    var itemCount = _num(j, ['itemCount', 'itemsCount'], 0).round();
    String items;
    if (itemsRaw is List) {
      var qtySum = 0;
      items = itemsRaw
          .whereType<Map>()
          .map((it) {
            final name = _str(it, ['name', 'itemName', 'menuItemName'], 'Item');
            final qty = _num(it, ['quantity', 'qty'], 1).round();
            qtySum += qty;
            return qty > 1 ? '$name x$qty' : name;
          })
          .join(', ');
      if (itemCount <= 0) itemCount = qtySum > 0 ? qtySum : itemsRaw.length;
    } else {
      items = itemsRaw?.toString() ?? '';
      if (itemCount <= 0 && items.isNotEmpty) {
        itemCount = items.split(',').where((s) => s.trim().isNotEmpty).length;
      }
    }

    final createdAt = _str(j, ['createdAt', 'placedAt', 'orderDate'], '');
    final when = OrderStatusUtils.formatPastDateTime(createdAt);

    final rest = j['restaurant'] ?? j['branch'];
    String restId = '';
    String restName = '';
    if (rest is Map) {
      final rm = Map<String, dynamic>.from(rest);
      restId = _str(rm, ['id', '_id', 'branchId'], '');
      restName = _str(rm, ['name', 'branchName'], '');
    } else {
      restId = _str(j, ['restaurantId', 'branchId'], '');
    }
    if (restName.isEmpty) {
      restName = _str(j, ['restaurantName', 'restaurantLabel', 'branchName'], '');
    }

    final orderId = _str(j, ['id', '_id', 'orderId'], '');
    final orderNumber = _str(j, ['orderNumber', 'order_number'], orderId);

    return PastOrder(
      orderId: orderId.isNotEmpty ? orderId : orderNumber,
      orderNumber: orderNumber.isNotEmpty ? orderNumber : orderId,
      restaurantId: restId,
      restaurantName: restName,
      items: items,
      itemCount: itemCount,
      total: _num(j, [
        'grandTotal',
        'total',
        'totalAmount',
        'amount',
      ], 0).round(),
      status: OrderStatusUtils.normalize(
        _str(j, ['status', 'orderStatus'], 'PLACED'),
      ),
      createdAt: createdAt,
      when: when.isNotEmpty ? when : createdAt,
      rating: _num(j, ['rating', 'customerRating'], 0).round(),
    );
  }
}
