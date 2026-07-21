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

  static Future<bool> hydrate() async {
    await TokenStore.init();

    // GPS first so nearby/search use the same coords as the website.
    await LocationService.ensureLocation();
    store.shortAddress = ApiConfig.locationLabel;

    // Refresh token quietly when we have one.
    if (TokenStore.refreshToken != null) {
      try {
        await CustomerAuthApi.refresh();
      } catch (_) {/* keep existing access token */}
    }

    final results = await Future.wait<bool>([
      syncRestaurants(),
      syncTrending(),
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

  static Future<bool> syncRestaurants() async {
    // Exact website call shape:
    // GET /customer/discovery/nearby?lat=&lng=&radius=50000&limit=200
    const radii = <double>[50000, 100000, 500000];
    for (final radius in radii) {
      try {
        final res = await CustomerDiscoveryApi.nearby(
          lat: ApiConfig.lat,
          lng: ApiConfig.lng,
          radius: radius,
          limit: 200,
        );
        final list = RemoteMappers.discoveryRestaurants(res);
        debugPrint(
          '[AppRepository] nearby lat=${ApiConfig.lat} lng=${ApiConfig.lng} '
          'radius=$radius → ${list.length} restaurants',
        );
        if (list.isNotEmpty) {
          store.restaurants
            ..clear()
            ..addAll(list);
          backendLive = true;
          // Fire-and-forget cover backfill (website does the same from menu).
          // ignore: unawaited_futures
          _backfillRestaurantImages(list.take(8).map((r) => r.id).toList());
          return true;
        }
      } catch (e) {
        debugPrint('[AppRepository] nearby(radius=$radius) failed: $e');
      }
    }
    return false;
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
        store.restaurants[idx] = Restaurant(
          id: current.id,
          name: current.name,
          cuisines: current.cuisines,
          rating: current.rating,
          time: current.time,
          price: current.price,
          dist: current.dist,
          offer: current.offer,
          veg: current.veg,
          photoKey: url,
          isOpen: current.isOpen,
          galleryPhotoKeys: current.galleryPhotoKeys,
          videoThumbnailKey: current.videoThumbnailKey,
          videoDuration: current.videoDuration,
        );
      } catch (e) {
        debugPrint('[AppRepository] image backfill failed for $id: $e');
      }
    }
  }

  static Future<List<Restaurant>> searchRestaurants(String q) async {
    try {
      final res = await CustomerDiscoveryApi.search(
          q, ApiConfig.lat, ApiConfig.lng);
      final list = RemoteMappers.discoveryRestaurants(res);
      backendLive = true;
      return list;
    } catch (_) {
      final needle = q.toLowerCase();
      return store.restaurants
          .where((r) =>
              r.name.toLowerCase().contains(needle) ||
              r.cuisines.toLowerCase().contains(needle))
          .toList();
    }
  }

  static Future<bool> syncTrending() async {
    try {
      final res = await CustomerDiscoveryApi.trending(
          ApiConfig.lat, ApiConfig.lng);
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
          ApiConfig.lat, ApiConfig.lng);
      final list = RemoteMappers.unwrapList(
          res, ['dishes', 'items', 'popularDishes', 'results']);
      if (list.isEmpty) return false;
      store.popularDishNames
        ..clear()
        ..addAll(list.map((j) =>
            (j['name'] ?? j['itemName'] ?? j['title'] ?? '').toString())
            .where((s) => s.isNotEmpty));
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
        final r = RemoteMappers.restaurant(Map<String, dynamic>.from(data));
        final idx = store.restaurants.indexWhere((e) => e.id == branchId);
        if (idx >= 0) {
          store.restaurants[idx] = r;
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
      if (mapped.isNotEmpty) {
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
        return true;
      }
    } catch (e) {
      debugPrint('[AppRepository] menu($branchId) failed: $e');
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
          RemoteMappers.unwrapList(
            res,
            ['foodeezOffers', 'restaurantOffers', 'coupons', 'catalog', 'results', 'items'],
          ),
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
      final list =
          RemoteMappers.unwrapList(res, ['coupons', 'results', 'items']);
      var i = store.coupons.length;
      for (final j in list) {
        final c = RemoteMappers.coupon(j, i++);
        if (!store.coupons.any((e) => e.code == c.code)) store.coupons.add(c);
      }
      backendLive = true;
    } catch (_) {/* fail-soft */}
  }

  // ── Cart ───────────────────────────────────────────────────────────────────

  /// Pulls server cart into local id→qty map. Returns remote ids keyed by menu item.
  static Future<Map<String, String>> syncCart() async {
    final remoteIds = <String, String>{};
    try {
      final res = await CustomerCartApi.get();
      final data = RemoteMappers.unwrap(res);
      final items = data is Map
          ? RemoteMappers.unwrapList(data, ['items', 'cartItems', 'results'])
          : RemoteMappers.unwrapList(res, ['items', 'cartItems', 'results']);
      if (items.isEmpty) return remoteIds;

      final local = <String, int>{};
      for (final it in items) {
        final menuId =
            (it['menuItemId'] ?? it['itemId'] ?? it['productId'] ?? '').toString();
        final cartItemId = (it['id'] ?? it['_id'] ?? it['cartItemId'] ?? '').toString();
        final qty = (it['quantity'] is num)
            ? (it['quantity'] as num).round()
            : int.tryParse('${it['quantity']}') ?? 1;
        if (menuId.isEmpty) continue;
        local[menuId] = qty;
        if (cartItemId.isNotEmpty) remoteIds[menuId] = cartItemId;
      }
      if (local.isNotEmpty) {
        // Caller merges into AppController.cart
        store.lastSyncedCart
          ..clear()
          ..addAll(local);
      }
      final coupon = data is Map
          ? (data['couponCode'] ?? data['appliedCoupon'] ?? '').toString()
          : '';
      if (coupon.isNotEmpty) store.lastSyncedCouponCode = coupon;
      backendLive = true;
    } catch (e) {
      debugPrint('[AppRepository] cart sync failed: $e');
    }
    return remoteIds;
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  static Future<bool> syncOrders() async {
    try {
      final res = await CustomerOrdersApi.history(limit: 20);
      final list = RemoteMappers.unwrapList(res, ['orders', 'results', 'items']);
      final mapped = list.map(RemoteMappers.pastOrder).toList();
      if (mapped.isNotEmpty) {
        store.pastOrders
          ..clear()
          ..addAll(mapped);
      }
      backendLive = true;
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
      final addrs =
          RemoteMappers.unwrapList(ares, ['addresses', 'results', 'items']);
      store.addresses
        ..clear()
        ..addAll(addrs);
      if (addrs.isNotEmpty) {
        final def = addrs.firstWhere(
            (a) => a['isDefault'] == true,
            orElse: () => addrs.first);
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

  static Future<bool> updateAddress(String id, Map<String, dynamic> data) async {
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
    if (store.defaultAddressId != null && store.defaultAddressId!.isNotEmpty) return true;
    await syncAddresses();
    if (store.defaultAddressId != null && store.defaultAddressId!.isNotEmpty) return true;
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
      final rests = RemoteMappers.unwrapList(
          rRes, ['restaurants', 'favorites', 'results', 'items']);
      final items = RemoteMappers.unwrapList(
          iRes, ['items', 'favorites', 'results', 'menuItems']);
      store.favoriteRestaurantIds
        ..clear()
        ..addAll(rests.map((j) =>
            (j['id'] ?? j['_id'] ?? j['restaurantId'] ?? j['branchId'] ?? '')
                .toString())
            .where((s) => s.isNotEmpty));
      store.favoriteMenuItemIds
        ..clear()
        ..addAll(items.map((j) =>
            (j['id'] ?? j['_id'] ?? j['menuItemId'] ?? '').toString())
            .where((s) => s.isNotEmpty));
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

  static Future<bool> toggleFavItem(String menuItemId, String restaurantId) async {
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
      final list = RemoteMappers.unwrapList(
          res, ['transactions', 'results', 'items']);
      store.walletTransactions
        ..clear()
        ..addAll(list.map((j) => {
              'id': (j['id'] ?? j['_id'] ?? '').toString(),
              'title': (j['title'] ?? j['description'] ?? j['type'] ?? 'Transaction')
                  .toString(),
              'amount': j['amount'] ?? j['value'] ?? 0,
              'createdAt': (j['createdAt'] ?? j['date'] ?? '').toString(),
            }));
      backendLive = true;
      return true;
    } catch (e) {
      debugPrint('[AppRepository] wallet transactions failed: $e');
    }
    return false;
  }

  static Future<bool> topupWallet(num amount, {String gateway = 'razorpay'}) async {
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
      String restaurantId) async {
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
      final list =
          RemoteMappers.unwrapList(res, ['tickets', 'results', 'items']);
      store.supportTickets
        ..clear()
        ..addAll(list.map((j) => {
              'id': (j['id'] ?? j['_id'] ?? '').toString(),
              'type': (j['type'] ?? '').toString(),
              'description': (j['description'] ?? '').toString(),
              'status': (j['status'] ?? 'OPEN').toString(),
            }));
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
