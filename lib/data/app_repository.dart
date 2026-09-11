import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'mock_data.dart' as store;
import 'remote_mappers.dart';

/// Fail-soft hub for every path in [ApiEndpoints].
/// Live responses update [store]; failures leave seed/mock data in place.
class AppRepository {
  AppRepository._();

  static bool backendLive = false;
  static bool cartSyncSucceeded = false;

  static Future<bool> hydrate() async {
    await TokenStore.init();

    // Resolve GPS in parallel — first nearby call uses fallback Hyderabad coords.
    final locationFuture = LocationService.ensureLocation();

    // Refresh token quietly when we have one.
    if (TokenStore.refreshToken != null) {
      try {
        await CustomerAuthApi.refresh();
      } catch (_) {
        /* keep existing access token */
      }
    }

    // Nearby first at current/fallback coords so Home has API restaurants
    // even if GPS later resolves far from INT Hyderabad test data.
    var live = await syncRestaurants();

    await locationFuture;
    store.shortAddress = ApiConfig.locationLabel;
    live = await syncRestaurants() || live;
    live = await syncTrending() || live;

    final results = await Future.wait<bool>([
      Future.value(live),
      syncPopularDishes(),
      syncCoupons(),
      if (TokenStore.isLoggedIn) syncProfile(),
      if (TokenStore.isLoggedIn) syncAddresses(),
      if (TokenStore.isLoggedIn) syncOrders(),
      if (TokenStore.isLoggedIn) syncWallet(),
      if (TokenStore.isLoggedIn) syncWalletTransactions(),
      if (TokenStore.isLoggedIn) syncFavorites(),
      if (TokenStore.isLoggedIn) syncSupportTickets(),
    ]);

    if (TokenStore.isLoggedIn) {
      await syncCart();
    }
    return results.isNotEmpty && results.any((ok) => ok);
  }

  // ── Discovery ──────────────────────────────────────────────────────────────

  static bool _isFallbackCoords(double lat, double lng) =>
      (lat - ApiConfig.fallbackLat).abs() < 0.0005 &&
      (lng - ApiConfig.fallbackLng).abs() < 0.0005;

  static Future<List<Restaurant>> _nearbyAt(double lat, double lng) async {
    // Exact website call shape:
    // GET /customer/discovery/nearby?lat=&lng=&radius=50000&limit=200
    const radii = <int>[50000, 100000, 500000];
    for (final radius in radii) {
      try {
        final res = await CustomerDiscoveryApi.nearby(
          lat: lat,
          lng: lng,
          radius: radius,
          limit: 200,
        );
        final list = RemoteMappers.discoveryRestaurants(res);
        debugPrint(
          '[AppRepository] nearby lat=$lat lng=$lng radius=$radius '
          '→ ${list.length} restaurants'
          '${list.isEmpty ? '' : ': ${list.map((r) => r.name).join(', ')}'}',
        );
        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint('[AppRepository] nearby(radius=$radius) failed: $e');
      }
    }
    return const [];
  }

  static Future<bool> syncRestaurants({bool allowEmpty = false}) async {
    var list = await _nearbyAt(ApiConfig.lat, ApiConfig.lng);

    // INT restaurants are pinned near Hyderabad. Device GPS elsewhere
    // returns [] and used to wipe the Home list — retry the known pin.
    if (list.isEmpty && !_isFallbackCoords(ApiConfig.lat, ApiConfig.lng)) {
      debugPrint(
        '[AppRepository] no restaurants at GPS '
        '(${ApiConfig.lat}, ${ApiConfig.lng}) — retrying fallback pin',
      );
      list = await _nearbyAt(ApiConfig.fallbackLat, ApiConfig.fallbackLng);
    }

    if (list.isEmpty) {
      if (!allowEmpty && store.restaurants.isNotEmpty) {
        debugPrint(
          '[AppRepository] nearby empty — keeping '
          '${store.restaurants.length} already-loaded restaurants',
        );
        return true;
      }
      store.restaurants.clear();
      backendLive = true;
      return true;
    }

    store.restaurants
      ..clear()
      ..addAll(list);
    backendLive = true;
    // Fire-and-forget cover backfill (website does the same from menu).
    // ignore: unawaited_futures
    _backfillRestaurantImages(list.take(8).map((r) => r.id).toList());
    return true;
  }

  static Future<void> _backfillRestaurantImages(List<String> branchIds) async {
    for (final id in branchIds) {
      try {
        final idx = store.restaurants.indexWhere((rest) => rest.id == id);
        if (idx < 0) continue;
        final current = store.restaurants[idx];
        final looksMock = !current.photoKey.startsWith('http');
        if (!looksMock) continue;
        final res = await CustomerDiscoveryApi.menu(id);
        final items = RemoteMappers.menu(res);
        String? url;
        for (final m in items) {
          if (m.photoKey.startsWith('http')) {
            url = m.photoKey;
            break;
          }
        }
        if (url == null) continue;
        store.restaurants[idx] = current.copyWith(photoKey: url);
      } catch (e) {
        debugPrint('[AppRepository] image backfill failed for $id: $e');
      }
    }
  }

  static Future<List<Restaurant>> searchRestaurants(String q) async {
    try {
      final res = await CustomerDiscoveryApi.search(
        q,
        ApiConfig.lat,
        ApiConfig.lng,
      );
      final list = RemoteMappers.discoveryRestaurants(res);
      backendLive = true;
      return list;
    } catch (_) {
      final needle = q.toLowerCase();
      return store.restaurants
          .where(
            (r) =>
                r.name.toLowerCase().contains(needle) ||
                r.cuisines.toLowerCase().contains(needle),
          )
          .toList();
    }
  }

  static Future<bool> syncTrending() async {
    try {
      final res = await CustomerDiscoveryApi.trending(
        ApiConfig.lat,
        ApiConfig.lng,
      );
      final mapped = RemoteMappers.discoveryRestaurants(res);
      if (mapped.isEmpty) return false;
      // Prefer trending order at the front; keep others after.
      final ids = mapped.map((r) => r.id).toSet();
      final rest = store.restaurants.where((r) => !ids.contains(r.id));
      store.restaurants
        ..clear()
        ..addAll([...mapped, ...rest]);
      store.trendingRestaurantIds
        ..clear()
        ..addAll(mapped.map((r) => r.id));
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] trending failed: $e');
    }
    return false;
  }

  static Future<bool> syncPopularDishes() async {
    try {
      final res = await CustomerDiscoveryApi.popularDishes(
        ApiConfig.lat,
        ApiConfig.lng,
      );
      final list = RemoteMappers.unwrapList(res, [
        'dishes',
        'items',
        'popularDishes',
        'results',
      ]);
      if (list.isEmpty) return false;
      store.popularDishNames
        ..clear()
        ..addAll(
          list
              .map(
                (j) =>
                    (j['name'] ?? j['itemName'] ?? j['title'] ?? '').toString(),
              )
              .where((s) => s.isNotEmpty),
        );
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] popular-dishes failed: $e');
    }
    return false;
  }

  static Future<bool> syncRestaurantDetails(String branchId) async {
    try {
      final res = await CustomerDiscoveryApi.restaurantDetails(branchId);
      final data = RemoteMappers.unwrap(res);
      if (data is Map) {
        final raw = Map<String, dynamic>.from(data);
        // Details nests brand fields under `restaurant` (same as nearby).
        final nested = raw['restaurant'];
        if (nested is Map) {
          final n = Map<String, dynamic>.from(nested);
          raw['brandDescription'] ??= n['brandDescription'];
          raw['description'] ??= n['brandDescription'] ?? n['description'];
          raw['cuisineTags'] ??= n['cuisineTags'];
          raw['coverPhoto'] ??= n['coverPhoto'];
          raw['logoUrl'] ??= n['logoUrl'];
          raw['avgCostForTwo'] ??= n['avgCostForTwo'];
          raw['name'] ??= n['name'];
        }
        final r = RemoteMappers.restaurant(raw);
        final idx = store.restaurants.indexWhere((e) => e.id == branchId);
        if (idx >= 0) {
          final prev = store.restaurants[idx];
          store.restaurants[idx] = r.copyWith(
            // Keep a cover we already resolved if details has none.
            photoKey: r.photoKey == 'biryani' ? prev.photoKey : r.photoKey,
            description: r.description.isNotEmpty
                ? r.description
                : prev.description,
            address: r.address.isNotEmpty ? r.address : prev.address,
          );
        } else {
          store.restaurants.add(r);
        }
        backendLive = true;
        return true;
      }
    } catch (e) {
      debugPrint('[AppRepository] restaurantDetails($branchId) failed: $e');
    }
    return false;
  }

  static Future<bool> syncMenu(String branchId) async {
    try {
      final res = await CustomerDiscoveryApi.menu(branchId);
      final mapped = RemoteMappers.menu(res);
      store.menu
        ..clear()
        ..addAll(mapped);
      final sections = <String>[];
      for (final m in mapped) {
        if (!sections.contains(m.section)) sections.add(m.section);
      }
      store.menuSectionOrder
        ..clear()
        ..addAll(sections);
      backendLive = true;
      debugPrint(
        '[AppRepository] menu($branchId) → ${mapped.length} items, '
        '${sections.length} categories',
      );
      return true;
    } catch (e) {
      debugPrint('[AppRepository] menu($branchId) failed: $e');
      store.menu.clear();
      store.menuSectionOrder.clear();
    }
    return false;
  }

  // ── Coupons (not in ApiEndpoints — keep fail-soft) ─────────────────────────

  static Future<bool> syncCoupons() async {
    try {
      final res = await CouponsApi.catalog();
      // Website shape: { foodeezOffers: [], restaurantOffers: [] }
      final payload = RemoteMappers.unwrap(res);
      final list = <Map<String, dynamic>>[];
      if (payload is Map) {
        for (final key in [
          'foodeezOffers',
          'restaurantOffers',
          'coupons',
          'catalog',
          'results',
          'items',
        ]) {
          final v = payload[key];
          if (v is List) {
            list.addAll(
              v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
            );
          }
        }
      } else {
        list.addAll(
          RemoteMappers.unwrapList(res, [
            'foodeezOffers',
            'restaurantOffers',
            'coupons',
            'catalog',
            'results',
            'items',
          ]),
        );
      }
      final mapped = <Coupon>[
        for (var i = 0; i < list.length; i++) RemoteMappers.coupon(list[i], i),
      ];
      if (mapped.isNotEmpty) {
        store.coupons
          ..clear()
          ..addAll(mapped);
        backendLive = true;
        return true;
      }
    } catch (e) {
      debugPrint('[AppRepository] coupons catalog failed: $e');
    }
    return false;
  }

  static Future<void> syncRestaurantCoupons(String restaurantId) async {
    try {
      final res = await CouponsApi.forRestaurant(restaurantId);
      final list = RemoteMappers.unwrapList(res, [
        'coupons',
        'results',
        'items',
      ]);
      var i = store.coupons.length;
      for (final j in list) {
        final c = RemoteMappers.coupon(j, i++);
        if (!store.coupons.any((e) => e.code == c.code)) store.coupons.add(c);
      }
      backendLive = true;
    } catch (_) {
      /* fail-soft */
    }
  }

  // ── Cart ───────────────────────────────────────────────────────────────────

  /// Pulls server cart into local id→qty map. Returns remote ids keyed by menu item.
  static Future<Map<String, String>> syncCart() async {
    final remoteIds = <String, String>{};
    cartSyncSucceeded = false;
    try {
      final res = await CustomerCartApi.get();
      final data = RemoteMappers.unwrap(res);
      final items = data is Map
          ? RemoteMappers.unwrapList(data, ['items', 'cartItems', 'results'])
          : RemoteMappers.unwrapList(res, ['items', 'cartItems', 'results']);

      final local = <String, int>{};
      for (final it in items) {
        final menuId =
            (it['menuItemId'] ?? it['itemId'] ?? it['productId'] ?? '')
                .toString();
        final cartItemId = (it['id'] ?? it['_id'] ?? it['cartItemId'] ?? '')
            .toString();
        final qty = (it['quantity'] is num)
            ? (it['quantity'] as num).round()
            : int.tryParse('${it['quantity']}') ?? 1;
        if (menuId.isEmpty) continue;
        local[menuId] = qty;
        if (cartItemId.isNotEmpty) remoteIds[menuId] = cartItemId;
      }
      store.lastSyncedCart
        ..clear()
        ..addAll(local);
      final coupon = data is Map
          ? (data['couponCode'] ?? data['appliedCoupon'] ?? '').toString()
          : '';
      if (coupon.isNotEmpty) store.lastSyncedCouponCode = coupon;
      backendLive = true;
      cartSyncSucceeded = true;
    } catch (e) {
      debugPrint('[AppRepository] cart sync failed: $e');
    }
    return remoteIds;
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  static Future<bool> syncOrders() async {
    try {
      final res = await CustomerOrdersApi.history(limit: 20);
      // Backend: { data: [...orders], meta } — unwrapList digs the array.
      var list = RemoteMappers.unwrapList(res, [
        'orders',
        'results',
        'items',
        'data',
      ]);
      if (list.isEmpty) {
        final raw = RemoteMappers.unwrap(res);
        if (raw is List) {
          list = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      final mapped = list.map(RemoteMappers.pastOrder).toList();
      store.pastOrders
        ..clear()
        ..addAll(mapped);
      backendLive = true;
      debugPrint('[AppRepository] orders synced → ${mapped.length}');
      return true;
    } catch (e) {
      debugPrint('[AppRepository] order history failed: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final res = await CustomerOrdersApi.get(orderId);
      final data = RemoteMappers.unwrap(res);
      backendLive = true;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('[AppRepository] getOrder failed: $e');
    }
    return null;
  }

  static Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      await CustomerOrdersApi.cancel(orderId, reason);
      await syncOrders();
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] cancelOrder failed: $e');
    }
    return false;
  }

  static Future<bool> reorder(String orderId) async {
    try {
      await CustomerOrdersApi.reorder(orderId);
      await syncCart();
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] reorder failed: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> tracking(String orderId) async {
    try {
      final res = await CustomerOrdersApi.tracking(orderId);
      final data = RemoteMappers.unwrap(res);
      backendLive = true;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('[AppRepository] tracking failed: $e');
    }
    return null;
  }

  // ── Profile / addresses / favorites ────────────────────────────────────────

  static Future<bool> syncProfile() async {
    try {
      final res = await CustomerProfileApi.get();
      final p = RemoteMappers.unwrap(res);
      if (p is Map) {
        final name = (p['name'] ?? '').toString();
        if (name.isNotEmpty) {
          store.userName = name;
          final parts = name.trim().split(RegExp(r'\s+'));
          store.userInitials = parts
              .take(2)
              .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
              .join();
        }
        if ((p['email'] ?? '').toString().isNotEmpty) {
          store.userEmail = p['email'].toString();
        }
        if ((p['phone'] ?? '').toString().isNotEmpty) {
          store.userPhone = p['phone'].toString();
        }
      }
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] profile failed: $e');
    }
    return false;
  }

  static Future<bool> updateProfile({
    String? name,
    String? email,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      await CustomerProfileApi.update(
        name: name,
        email: email,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );
      await syncProfile();
      return true;
    } catch (e) {
      debugPrint('[AppRepository] updateProfile failed: $e');
    }
    return false;
  }

  static Future<bool> updateProfileImage(String imageKey) async {
    try {
      await CustomerProfileApi.updateImage(imageKey);
      return true;
    } catch (e) {
      debugPrint('[AppRepository] updateProfileImage failed: $e');
    }
    return false;
  }

  static Future<bool> syncAddresses() async {
    try {
      final ares = await CustomerProfileApi.getAddresses();
      final addrs = RemoteMappers.unwrapList(ares, [
        'addresses',
        'results',
        'items',
      ]);
      // Normalize lat/lng onto top-level keys so Select Location / Home can pin.
      final normalized = addrs.map((raw) {
        final a = Map<String, dynamic>.from(raw);
        dynamic lat = a['latitude'] ?? a['lat'];
        dynamic lng = a['longitude'] ?? a['lng'] ?? a['long'];
        final nested = a['location'] ?? a['geoLocation'] ?? a['geo'];
        if (nested is Map) {
          lat ??= nested['latitude'] ?? nested['lat'];
          lng ??= nested['longitude'] ?? nested['lng'] ?? nested['long'];
          final coords = nested['coordinates'];
          if ((lat == null || lng == null) &&
              coords is List &&
              coords.length >= 2) {
            lng ??= coords[0];
            lat ??= coords[1];
          }
        }
        if (lat != null)
          a['latitude'] = lat is num
              ? lat.toDouble()
              : double.tryParse(lat.toString());
        if (lng != null)
          a['longitude'] = lng is num
              ? lng.toDouble()
              : double.tryParse(lng.toString());
        return a;
      }).toList();
      store.addresses
        ..clear()
        ..addAll(normalized);
      if (normalized.isNotEmpty) {
        final def = normalized.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => normalized.first,
        );
        final line1 = (def['addressLine1'] ?? '').toString();
        final city = (def['city'] ?? '').toString();
        if (line1.isNotEmpty) {
          final parts = <String>[
            line1,
            (def['addressLine2'] ?? '').toString(),
            city,
          ].where((s) => s.isNotEmpty);
          store.homeAddress = parts.join(', ');
          store.shortAddress = city.isNotEmpty ? '$line1, $city' : line1;
          store.defaultAddressId = (def['id'] ?? def['_id'] ?? '').toString();
        }
      }
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] addresses failed: $e');
    }
    return false;
  }

  static Future<bool> addAddress({
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    required double latitude,
    required double longitude,
    bool? isDefault,
  }) async {
    try {
      await CustomerProfileApi.addAddress(
        label: label,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        pincode: pincode,
        landmark: landmark,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
      await syncAddresses();
      return true;
    } catch (e) {
      debugPrint('[AppRepository] addAddress failed: $e');
    }
    return false;
  }

  static Future<bool> updateAddress(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await CustomerProfileApi.updateAddress(id, data);
      await syncAddresses();
      return true;
    } catch (e) {
      debugPrint('[AppRepository] updateAddress failed: $e');
    }
    return false;
  }

  static Future<bool> deleteAddress(String id) async {
    try {
      await CustomerProfileApi.deleteAddress(id);
      await syncAddresses();
      return true;
    } catch (e) {
      debugPrint('[AppRepository] deleteAddress failed: $e');
    }
    return false;
  }

  static Future<bool> setDefaultAddress(String id) async {
    try {
      await CustomerProfileApi.setDefaultAddress(id);
      await syncAddresses();
      return true;
    } catch (e) {
      debugPrint('[AppRepository] setDefaultAddress failed: $e');
    }
    return false;
  }

  /// Ensures a default delivery address exists (sync saved addresses or create from GPS).
  static Future<bool> ensureDefaultAddressForCheckout() async {
    if (store.defaultAddressId != null && store.defaultAddressId!.isNotEmpty)
      return true;
    await syncAddresses();
    if (store.defaultAddressId != null && store.defaultAddressId!.isNotEmpty)
      return true;
    if (!TokenStore.isLoggedIn) return false;

    try {
      await LocationService.ensureLocation();
      final details = await LocationService.resolveAddressDetails(
        ApiConfig.lat,
        ApiConfig.lng,
      );
      return addAddress(
        label: 'Current Location',
        addressLine1: details.addressLine1,
        city: details.city,
        state: details.state,
        pincode: details.pincode.isNotEmpty ? details.pincode : '000000',
        latitude: ApiConfig.lat,
        longitude: ApiConfig.lng,
        isDefault: true,
      );
    } catch (e) {
      debugPrint('[AppRepository] ensureDefaultAddressForCheckout failed: $e');
    }
    return false;
  }

  static Future<bool> syncFavorites() async {
    try {
      final rRes = await CustomerProfileApi.getFavRestaurants();
      final iRes = await CustomerProfileApi.getFavItems();
      final rests = RemoteMappers.unwrapList(rRes, [
        'restaurants',
        'favorites',
        'results',
        'items',
      ]);
      final items = RemoteMappers.unwrapList(iRes, [
        'items',
        'favorites',
        'results',
        'menuItems',
      ]);
      store.favoriteRestaurantIds
        ..clear()
        ..addAll(
          rests
              .map(
                (j) =>
                    (j['id'] ??
                            j['_id'] ??
                            j['restaurantId'] ??
                            j['branchId'] ??
                            '')
                        .toString(),
              )
              .where((s) => s.isNotEmpty),
        );
      store.favoriteMenuItemIds
        ..clear()
        ..addAll(
          items
              .map(
                (j) =>
                    (j['id'] ?? j['_id'] ?? j['menuItemId'] ?? '').toString(),
              )
              .where((s) => s.isNotEmpty),
        );
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] favorites failed: $e');
    }
    return false;
  }

  static Future<bool> toggleFavRestaurant(String restaurantId) async {
    final isFav = store.favoriteRestaurantIds.contains(restaurantId);
    try {
      if (isFav) {
        await CustomerProfileApi.removeFavRestaurant(restaurantId);
        store.favoriteRestaurantIds.remove(restaurantId);
      } else {
        await CustomerProfileApi.addFavRestaurant(restaurantId);
        if (!store.favoriteRestaurantIds.contains(restaurantId)) {
          store.favoriteRestaurantIds.add(restaurantId);
        }
      }
      return true;
    } catch (e) {
      debugPrint('[AppRepository] toggleFavRestaurant failed: $e');
    }
    return false;
  }

  static Future<bool> toggleFavItem(
    String menuItemId,
    String restaurantId,
  ) async {
    final isFav = store.favoriteMenuItemIds.contains(menuItemId);
    try {
      if (isFav) {
        await CustomerProfileApi.removeFavItem(menuItemId);
        store.favoriteMenuItemIds.remove(menuItemId);
      } else {
        await CustomerProfileApi.addFavItem(menuItemId, restaurantId);
        if (!store.favoriteMenuItemIds.contains(menuItemId)) {
          store.favoriteMenuItemIds.add(menuItemId);
        }
      }
      return true;
    } catch (e) {
      debugPrint('[AppRepository] toggleFavItem failed: $e');
    }
    return false;
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  static Future<bool> syncWallet() async {
    try {
      final res = await CustomerPaymentsApi.wallet();
      final w = RemoteMappers.unwrap(res);
      if (w is Map) {
        final bal = w['balance'] ?? w['walletBalance'] ?? w['amount'];
        if (bal is num) store.walletBalance = bal.round();
      }
      backendLive = true;
      return true;
    } catch (_) {}
    return false;
  }

  static Future<bool> syncWalletTransactions() async {
    try {
      final res = await CustomerPaymentsApi.transactions();
      final list = RemoteMappers.unwrapList(res, [
        'transactions',
        'results',
        'items',
      ]);
      store.walletTransactions
        ..clear()
        ..addAll(
          list.map(
            (j) => {
              'id': (j['id'] ?? j['_id'] ?? '').toString(),
              'title':
                  (j['title'] ?? j['description'] ?? j['type'] ?? 'Transaction')
                      .toString(),
              'amount': j['amount'] ?? j['value'] ?? 0,
              'createdAt': (j['createdAt'] ?? j['date'] ?? '').toString(),
            },
          ),
        );
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] wallet transactions failed: $e');
    }
    return false;
  }

  static Future<bool> topupWallet(
    num amount, {
    String gateway = 'razorpay',
  }) async {
    try {
      await CustomerPaymentsApi.topupInitiate(amount, gateway);
      await syncWallet();
      await syncWalletTransactions();
      return true;
    } catch (e) {
      debugPrint('[AppRepository] topup failed: $e');
    }
    return false;
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  static Future<bool> submitReview({
    required String orderId,
    required num restaurantRating,
    num? deliveryRating,
    num? foodRating,
    String? reviewText,
  }) async {
    try {
      await CustomerReviewsApi.create(
        orderId: orderId,
        restaurantRating: restaurantRating,
        deliveryRating: deliveryRating,
        foodRating: foodRating,
        reviewText: reviewText,
      );
      return true;
    } catch (e) {
      debugPrint('[AppRepository] submitReview failed: $e');
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> restaurantReviews(
    String restaurantId,
  ) async {
    try {
      final res = await CustomerReviewsApi.byRestaurant(restaurantId);
      backendLive = true;
      return RemoteMappers.unwrapList(res, ['reviews', 'results', 'items']);
    } catch (_) {
      return const [];
    }
  }

  // ── Support ────────────────────────────────────────────────────────────────

  static Future<bool> syncSupportTickets() async {
    try {
      final res = await CustomerSupportApi.getTickets();
      final list = RemoteMappers.unwrapList(res, [
        'tickets',
        'results',
        'items',
      ]);
      store.supportTickets
        ..clear()
        ..addAll(
          list.map(
            (j) => {
              'id': (j['id'] ?? j['_id'] ?? '').toString(),
              'type': (j['type'] ?? '').toString(),
              'description': (j['description'] ?? '').toString(),
              'status': (j['status'] ?? 'OPEN').toString(),
            },
          ),
        );
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] support tickets failed: $e');
    }
    return false;
  }

  static Future<bool> createSupportTicket({
    String? orderId,
    required String type,
    required String description,
    String? priority,
  }) async {
    try {
      await CustomerSupportApi.createTicket(
        orderId: orderId,
        type: type,
        description: description,
        priority: priority,
      );
      await syncSupportTickets();
      return true;
    } catch (e) {
      debugPrint('[AppRepository] createSupportTicket failed: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getSupportTicket(String id) async {
    try {
      final res = await CustomerSupportApi.getTicket(id);
      final data = RemoteMappers.unwrap(res);
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }

  // ── Auth extras ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> syncSessions() async {
    try {
      final res = await CustomerAuthApi.getSessions();
      return RemoteMappers.unwrapList(res, ['sessions', 'results', 'items']);
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> revokeSession(String deviceId) async {
    try {
      await CustomerAuthApi.revokeSession(deviceId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> logoutAll() async {
    try {
      await CustomerAuthApi.logoutAll();
      return true;
    } catch (_) {
      await TokenStore.clear();
      return false;
    }
  }
}
