/// Centralized API path constants.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth (public API) ──────────────────────────────────────────────────────
  static const sendOtp = '/customer/auth/send-otp';
  static const signup = '/customer/auth/signup';
  static const login = '/customer/auth/login';
  static const refresh = '/customer/auth/refresh';
  static const resetPassword = '/customer/auth/reset-password';
  static const logout = '/customer/auth/logout';
  static const logoutAll = '/customer/auth/logout-all';
  static const sessions = '/customer/auth/sessions';
  static String revokeSession(String deviceId) =>
      '/customer/auth/sessions/$deviceId';

  // ── Discovery ──────────────────────────────────────────────────────────────
  static const discoveryNearby = '/customer/discovery/nearby';
  static const discoverySearch = '/customer/discovery/search';
  static const discoveryTrending = '/customer/discovery/trending';
  static const discoveryPopularDishes = '/customer/discovery/popular-dishes';

  static String restaurantDetails(String branchId) =>
      '/customer/discovery/restaurants/$branchId';

  static String restaurantMenu(String branchId) =>
      '/customer/discovery/restaurants/$branchId/menu';

  // ── Cart ───────────────────────────────────────────────────────────────────
  static const cart = '/customer/cart';
  static const cartItems = '/customer/cart/items';
  static String cartItem(String itemId) => '/customer/cart/items/$itemId';
  static const cartCoupon = '/customer/cart/coupon';

  // ── Orders ─────────────────────────────────────────────────────────────────
  static const orders = '/customer/orders';
  static String order(String orderId) => '/customer/orders/$orderId';
  static String orderCancel(String orderId) => '/customer/orders/$orderId/cancel';
  static String orderReorder(String orderId) => '/customer/orders/$orderId/reorder';
  static String orderTracking(String orderId) =>
      '/customer/orders/$orderId/tracking';

  // ── Profile ────────────────────────────────────────────────────────────────
  static const profile = '/customer/profile';
  static const profileImage = '/customer/profile/image';
  static const addresses = '/customer/profile/addresses';
  static String address(String id) => '/customer/profile/addresses/$id';
  static String addressDefault(String id) =>
      '/customer/profile/addresses/$id/set-default';
  static const favRestaurants = '/customer/profile/favorites/restaurants';
  static String favRestaurant(String id) =>
      '/customer/profile/favorites/restaurants/$id';
  static const favItems = '/customer/profile/favorites/items';
  static String favItem(String menuItemId) =>
      '/customer/profile/favorites/items/$menuItemId';

  // ── Payments ───────────────────────────────────────────────────────────────
  static const wallet = '/customer/payments/wallet';
  static const walletTransactions = '/customer/payments/wallet/transactions';
  static const walletTopupInitiate = '/customer/payments/wallet/topup/initiate';

  // ── Reviews ────────────────────────────────────────────────────────────────
  static const reviews = '/customer/reviews';

  // ── Support ────────────────────────────────────────────────────────────────
  static const supportTickets = '/customer/support/tickets';
  static String supportTicket(String id) => '/customer/support/tickets/$id';
}
