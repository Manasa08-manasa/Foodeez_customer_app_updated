import '../core/constants/api_endpoints.dart';
import 'api_client.dart';

/// Discovery — customer-facing endpoints via the customer backend.
class CustomerDiscoveryApi {
  CustomerDiscoveryApi._();

  static Future<dynamic> nearby({
    required double lat,
    required double lng,
    double? radius,
    int? page,
    int? limit,
    String? cuisine,
    double? minRating,
    int? maxDeliveryTime,
    bool? isVeg,
    String? sortBy,
  }) =>
      publicCustomerApi.get(ApiEndpoints.discoveryNearby, query: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'page': page,
        'limit': limit,
        'cuisine': cuisine,
        'minRating': minRating,
        'maxDeliveryTime': maxDeliveryTime,
        'isVeg': isVeg,
        'sortBy': sortBy,
      });

  static Future<dynamic> search(String q, double lat, double lng,
          {int page = 1, int limit = 20}) =>
      publicCustomerApi.get(ApiEndpoints.discoverySearch,
          query: {'q': q, 'lat': lat, 'lng': lng, 'page': page, 'limit': limit});

  static Future<dynamic> trending(double lat, double lng) =>
      publicCustomerApi.get(ApiEndpoints.discoveryTrending,
          query: {'lat': lat, 'lng': lng});

  static Future<dynamic> popularDishes(double lat, double lng) =>
      publicCustomerApi.get(ApiEndpoints.discoveryPopularDishes,
          query: {'lat': lat, 'lng': lng});

  static Future<dynamic> restaurantDetails(String branchId) =>
      publicCustomerApi.get(ApiEndpoints.restaurantDetails(branchId));

  static Future<dynamic> menu(String branchId) =>
      publicCustomerApi.get(ApiEndpoints.restaurantMenu(branchId));
}

class CustomerCartApi {
  CustomerCartApi._();

  static Future<dynamic> get() => customerApi.get(ApiEndpoints.cart);

  static Future<dynamic> addItem({
    required String menuItemId,
    String? branchId,
    required int quantity,
    List<Map<String, dynamic>>? selectedAddons,
    String? specialNote,
  }) =>
      customerApi.post(ApiEndpoints.cartItems, data: {
        'menuItemId': menuItemId,
        if (branchId != null) 'branchId': branchId,
        'quantity': quantity,
        if (selectedAddons != null) 'selectedAddons': selectedAddons,
        if (specialNote != null) 'specialNote': specialNote,
      });

  static Future<dynamic> updateItem(String itemId, int quantity) =>
      customerApi.patch(ApiEndpoints.cartItem(itemId),
          data: {'quantity': quantity});

  static Future<dynamic> removeItem(String itemId) =>
      customerApi.delete(ApiEndpoints.cartItem(itemId));

  static Future<dynamic> clear() => customerApi.delete(ApiEndpoints.cart);

  static Future<dynamic> applyCoupon(String couponCode) =>
      customerApi.post(ApiEndpoints.cartCoupon, data: {'couponCode': couponCode});

  static Future<dynamic> removeCoupon() =>
      customerApi.delete(ApiEndpoints.cartCoupon);
}

/// Customer coupon catalog — not in [ApiEndpoints]; fail-soft when unavailable.
class CouponsApi {
  CouponsApi._();

  static Future<dynamic> forRestaurant(String restaurantId) =>
      customerApi.get('/coupons/restaurant/$restaurantId');

  static Future<dynamic> catalog() => customerApi.get('/coupons/catalog');
}

class CustomerOrdersApi {
  CustomerOrdersApi._();

  static Future<dynamic> place({
    required String deliveryAddressId,
    required String paymentMethod,
    String? specialInstructions,
    bool? useWalletBalance,
    String? scheduledFor,
  }) =>
      customerApi.post(ApiEndpoints.orders, data: {
        'deliveryAddressId': deliveryAddressId,
        'paymentMethod': paymentMethod,
        if (specialInstructions != null)
          'specialInstructions': specialInstructions,
        if (useWalletBalance != null) 'useWalletBalance': useWalletBalance,
        if (scheduledFor != null) 'scheduledFor': scheduledFor,
      });

  static Future<dynamic> history({int page = 1, int limit = 10}) =>
      customerApi.get(ApiEndpoints.orders, query: {'page': page, 'limit': limit});

  static Future<dynamic> get(String orderId) =>
      customerApi.get(ApiEndpoints.order(orderId));

  static Future<dynamic> cancel(String orderId, String reason) =>
      customerApi.post(ApiEndpoints.orderCancel(orderId),
          data: {'reason': reason});

  static Future<dynamic> reorder(String orderId) =>
      customerApi.post(ApiEndpoints.orderReorder(orderId));

  static Future<dynamic> tracking(String orderId) =>
      customerApi.get(ApiEndpoints.orderTracking(orderId));
}

class CustomerPaymentsApi {
  CustomerPaymentsApi._();

  static Future<dynamic> initiatePayment({
    String? orderId,
    String? deliveryAddressId,
    String? specialInstructions,
    required String gateway,
  }) =>
      customerApi.post('/customer/payments/initiate', data: {
        if (orderId != null) 'orderId': orderId,
        if (deliveryAddressId != null) 'deliveryAddressId': deliveryAddressId,
        if (specialInstructions != null)
          'specialInstructions': specialInstructions,
        'gateway': gateway,
      });

  static Future<dynamic> verifyPayment({
    String? orderId,
    String? razorpayOrderId,
    required String paymentId,
    required String signature,
    required String gateway,
  }) =>
      customerApi.post('/customer/payments/verify', data: {
        if (orderId != null) 'orderId': orderId,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        'paymentId': paymentId,
        'signature': signature,
        'gateway': gateway,
      });

  static Future<dynamic> wallet() => customerApi.get(ApiEndpoints.wallet);

  static Future<dynamic> transactions({int page = 1, int limit = 20}) =>
      customerApi.get(ApiEndpoints.walletTransactions,
          query: {'page': page, 'limit': limit});

  static Future<dynamic> topupInitiate(num amount, String gateway) =>
      customerApi.post(ApiEndpoints.walletTopupInitiate,
          data: {'amount': amount, 'gateway': gateway});
}

class CustomerProfileApi {
  CustomerProfileApi._();

  static Future<dynamic> get() => customerApi.get(ApiEndpoints.profile);

  static Future<dynamic> update({
    String? name,
    String? email,
    String? dateOfBirth,
    String? gender,
    String? fcmToken,
  }) =>
      customerApi.patch(ApiEndpoints.profile, data: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (fcmToken != null) 'fcmToken': fcmToken,
      });

  static Future<dynamic> updateImage(String imageKey) =>
      customerApi.patch(ApiEndpoints.profileImage, data: {'imageKey': imageKey});

  static Future<dynamic> getAddresses() =>
      customerApi.get(ApiEndpoints.addresses);

  static Future<dynamic> addAddress({
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
  }) =>
      customerApi.post(ApiEndpoints.addresses, data: {
        'label': label,
        'addressLine1': addressLine1,
        if (addressLine2 != null) 'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'pincode': pincode,
        if (landmark != null) 'landmark': landmark,
        'latitude': latitude,
        'longitude': longitude,
        if (isDefault != null) 'isDefault': isDefault,
      });

  static Future<dynamic> updateAddress(String id, Map<String, dynamic> data) =>
      customerApi.patch(ApiEndpoints.address(id), data: data);

  static Future<dynamic> deleteAddress(String id) =>
      customerApi.delete(ApiEndpoints.address(id));

  static Future<dynamic> setDefaultAddress(String id) =>
      customerApi.patch(ApiEndpoints.addressDefault(id));

  static Future<dynamic> getFavRestaurants() =>
      customerApi.get(ApiEndpoints.favRestaurants);

  static Future<dynamic> addFavRestaurant(String restaurantId) =>
      customerApi.post(ApiEndpoints.favRestaurant(restaurantId));

  static Future<dynamic> removeFavRestaurant(String restaurantId) =>
      customerApi.delete(ApiEndpoints.favRestaurant(restaurantId));

  static Future<dynamic> getFavItems() =>
      customerApi.get(ApiEndpoints.favItems);

  static Future<dynamic> addFavItem(String menuItemId, String restaurantId) =>
      customerApi.post(ApiEndpoints.favItem(menuItemId),
          data: {'restaurantId': restaurantId});

  static Future<dynamic> removeFavItem(String menuItemId) =>
      customerApi.delete(ApiEndpoints.favItem(menuItemId));
}

class CustomerReviewsApi {
  CustomerReviewsApi._();

  static Future<dynamic> create({
    required String orderId,
    required num restaurantRating,
    num? deliveryRating,
    num? foodRating,
    String? reviewText,
    List<String>? imageUrls,
    bool? isAnonymous,
  }) =>
      customerApi.post(ApiEndpoints.reviews, data: {
        'orderId': orderId,
        'restaurantRating': restaurantRating,
        if (deliveryRating != null) 'deliveryRating': deliveryRating,
        if (foodRating != null) 'foodRating': foodRating,
        if (reviewText != null) 'reviewText': reviewText,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (isAnonymous != null) 'isAnonymous': isAnonymous,
      });

  static Future<dynamic> byRestaurant(String restaurantId,
          {int page = 1, int limit = 10}) =>
      defaultApi.get('/customer/reviews/restaurant/$restaurantId',
          query: {'page': page, 'limit': limit});

  static Future<dynamic> markHelpful(String reviewId) =>
      customerApi.post('${ApiEndpoints.reviews}/$reviewId/helpful');
}

class CustomerSupportApi {
  CustomerSupportApi._();

  static Future<dynamic> createTicket({
    String? orderId,
    required String type,
    required String description,
    String? priority,
  }) =>
      customerApi.post(ApiEndpoints.supportTickets, data: {
        if (orderId != null) 'orderId': orderId,
        'type': type,
        'description': description,
        if (priority != null) 'priority': priority,
      });

  static Future<dynamic> getTickets({int page = 1, int limit = 10}) =>
      customerApi.get(ApiEndpoints.supportTickets,
          query: {'page': page, 'limit': limit});

  static Future<dynamic> getTicket(String ticketId) =>
      customerApi.get(ApiEndpoints.supportTicket(ticketId));
}
