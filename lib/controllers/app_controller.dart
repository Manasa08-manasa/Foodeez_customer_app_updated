import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/app_repository.dart';
import '../data/mock_data.dart';
import '../data/mock_data.dart' as store;
import '../data/remote_mappers.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Mirrors the prototype's `Component` state machine: a screen stack for
/// push/pop flows, plus a "tab reset" mode for the 4 bottom-dock destinations.
class AppController extends ChangeNotifier {
  AppController() {
    _bootstrap();
    listenForSupportChatMessages();
  }

  List<String> stack = ['splash'];
  String get screen => stack.last;

  String rid = 'paradise';
  Restaurant get restaurant => store.restaurantById(rid);

  final Map<String, int> cart = {};

  /// Backend cart-line id keyed by local menu item id (when logged in).
  final Map<String, String> _remoteCartItemIds = {};

  String? appliedCouponCode = 'WELCOME50';
  String deliveryType = 'bolt'; // 'bolt' (free) | 'eco' (₹20)
  String selectedPay = 'foodeez-upi';
  String paymentContext = 'checkout'; // 'checkout' | 'booking'
  bool vegOnly = false;

  String ordersTab = 'delivery'; // 'delivery' | 'dining'

  int bDateIdx = 0;
  int bTimeIdx = 2;
  int bGuests = 2;
  String bookingRid = 'paradise';

  final List<Booking> bookings = List.of(seedBookings);
  Booking? lastBooking;

  bool trackMenuOpen = false;
  String? activeOrderId;

  final List<ChatMessage> chatMessages = [];
  bool agentTyping = false;
  String? activeSupportSessionId;
  final SupportChatService _supportChatService = SupportChatService();
  bool supportChatReady = false;
  String? supportChatError;

  bool isHydrating = true;
  bool get isLoggedIn => TokenStore.isLoggedIn;

  /// Flag to determine if SelectLocationScreen should update home location (true) or save address (false)
  bool selectLocationForHome = false;

  // ---- Auth State ----
  /// 'login' | 'signup'
  String authMode = 'login';
  String? authEmail;
  String? authPhone;
  String? authName;
  bool otpSent = false;
  bool isLoggingIn = false;
  String? authError;

  /// When set (e.g. `'cart'`), successful login/signup returns to checkout.
  String? authReturnTarget;
  String? checkoutError;
  bool isPlacingOrder = false;

  void clearAuthError() {
    authError = null;
    notifyListeners();
  }

  void setAuthMode(String mode) {
    authMode = mode;
    otpSent = false;
    authError = null;
    notifyListeners();
  }

  void setAuthEmail(String email) {
    authEmail = email;
    otpSent = false;
    authError = null;
    notifyListeners();
  }

  void setAuthPhone(String phone) {
    authPhone = phone;
    notifyListeners();
  }

  void setAuthName(String name) {
    authName = name;
    notifyListeners();
  }

  void markOtpSent() {
    otpSent = true;
    authError = null;
    notifyListeners();
  }

  void setAuthError(String error) {
    authError = error;
    notifyListeners();
  }

  void resetAuth() {
    authEmail = null;
    authPhone = null;
    authName = null;
    otpSent = false;
    isLoggingIn = false;
    authError = null;
    authMode = 'login';
    notifyListeners();
  }

  void requireAuthForCheckout() {
    authReturnTarget = 'cart';
    authMode = 'login';
    otpSent = false;
    authError = null;
    push('onboarding');
  }

  void finishAuthNavigation() {
    resetAuth();
    final target = authReturnTarget;
    authReturnTarget = null;
    if (target == 'cart') {
      stack.removeWhere((s) => s == 'onboarding');
      if (!stack.contains('cart')) {
        push('cart');
      } else {
        notifyListeners();
      }
      return;
    }
    toHome();
  }

  void backToCredentials() {
    otpSent = false;
    authError = null;
    notifyListeners();
  }

  final _rand = Random();

  Future<void> _bootstrap() async {
    try {
      await AppRepository.hydrate();
      if (TokenStore.isLoggedIn) {
        final remoteIds = await AppRepository.syncCart();
        if (store.lastSyncedCart.isNotEmpty) {
          cart
            ..clear()
            ..addAll(store.lastSyncedCart);
          _remoteCartItemIds
            ..clear()
            ..addAll(remoteIds);
          if (store.lastSyncedCouponCode != null) {
            appliedCouponCode = store.lastSyncedCouponCode;
          }
        }
      }
      // Splash owns the first navigation after hydrate; only auto-route
      // if we somehow land on onboarding while already logged in.
      if (TokenStore.isLoggedIn &&
          stack.isNotEmpty &&
          stack.last == 'onboarding') {
        stack = ['home'];
      }
    } catch (e) {
      debugPrint('[AppController] hydrate failed: $e');
    } finally {
      isHydrating = false;
      notifyListeners();
    }
  }

  /// Re-fetch guarded data after a successful login/signup.
  Future<void> refreshAfterAuth() async {
    await Future.wait([
      AppRepository.syncProfile(),
      AppRepository.syncAddresses(),
      AppRepository.syncOrders(),
      AppRepository.syncWallet(),
      AppRepository.syncWalletTransactions(),
      AppRepository.syncRestaurants(),
      AppRepository.syncFavorites(),
      AppRepository.syncSupportTickets(),
    ]);
    final remoteIds = await AppRepository.syncCart();
    if (store.lastSyncedCart.isNotEmpty) {
      cart
        ..clear()
        ..addAll(store.lastSyncedCart);
      _remoteCartItemIds
        ..clear()
        ..addAll(remoteIds);
      if (store.lastSyncedCouponCode != null) {
        appliedCouponCode = store.lastSyncedCouponCode;
      }
    }
    notifyListeners();
  }

  Future<void> refreshHome() async {
    try {
      await LocationService.ensureLocation();
      await Future.wait([
        AppRepository.syncRestaurants(),
        AppRepository.syncTrending(),
        AppRepository.syncPopularDishes(),
        AppRepository.syncCoupons(),
      ]);
    } catch (e) {
      debugPrint('[AppController] refreshHome failed: $e');
    } finally {
      if (hasListeners) notifyListeners();
    }
  }

  Future<void> refreshLocationAndNearby() async {
    await LocationService.ensureLocation();
    await AppRepository.syncRestaurants();
    notifyListeners();
  }

  double _parseLatLng(dynamic value, [double fallback = 0.0]) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  void selectAddress(Map<String, dynamic> address) {
    final lat = _parseLatLng(address['latitude'] ?? address['lat'], ApiConfig.lat);
    final lng = _parseLatLng(address['longitude'] ?? address['lng'], ApiConfig.lng);
    final line1 = (address['addressLine1'] ?? '').toString();
    final city = (address['city'] ?? '').toString();
    final label = line1.isNotEmpty
        ? (city.isNotEmpty ? '$line1, $city' : line1)
        : (address['label']?.toString() ?? 'Saved location');

    ApiConfig.setLocation(latitude: lat, longitude: lng, label: label);
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    await AppRepository.syncOrders();
    notifyListeners();
  }

  Future<void> refreshAccount() async {
    await Future.wait([
      AppRepository.syncProfile(),
      AppRepository.syncAddresses(),
      AppRepository.syncWallet(),
      AppRepository.syncWalletTransactions(),
      AppRepository.syncFavorites(),
    ]);
    notifyListeners();
  }

  Future<void> refreshHelp() async {
    await AppRepository.syncSupportTickets();
    notifyListeners();
  }

  Future<List<Restaurant>> searchRestaurants(String q) =>
      AppRepository.searchRestaurants(q);

  bool isFavoriteRestaurant(String id) => store.favoriteRestaurantIds.contains(id);
  bool isFavoriteItem(String id) => store.favoriteMenuItemIds.contains(id);

  Future<void> toggleFavoriteRestaurant(String restaurantId) async {
    if (!TokenStore.isLoggedIn) {
      if (store.favoriteRestaurantIds.contains(restaurantId)) {
        store.favoriteRestaurantIds.remove(restaurantId);
      } else {
        store.favoriteRestaurantIds.add(restaurantId);
      }
      notifyListeners();
      return;
    }
    await AppRepository.toggleFavRestaurant(restaurantId);
    notifyListeners();
  }

  Future<void> toggleFavoriteItem(String menuItemId) async {
    if (!TokenStore.isLoggedIn) {
      if (store.favoriteMenuItemIds.contains(menuItemId)) {
        store.favoriteMenuItemIds.remove(menuItemId);
      } else {
        store.favoriteMenuItemIds.add(menuItemId);
      }
      notifyListeners();
      return;
    }
    await AppRepository.toggleFavItem(menuItemId, rid);
    notifyListeners();
  }

  Future<void> reorderPastOrder(String orderId) async {
    if (TokenStore.isLoggedIn) {
      final ok = await AppRepository.reorder(orderId);
      if (ok) {
        final remoteIds = await AppRepository.syncCart();
        if (store.lastSyncedCart.isNotEmpty) {
          cart
            ..clear()
            ..addAll(store.lastSyncedCart);
          _remoteCartItemIds
            ..clear()
            ..addAll(remoteIds);
        }
        notifyListeners();
        toCart();
        return;
      }
    }
    PastOrder? order;
    for (final o in store.pastOrders) {
      if (o.id == orderId) {
        order = o;
        break;
      }
    }
    openRest(order?.restaurantId ?? rid);
  }

  Future<void> ratePastOrder(String orderId, {int rating = 5}) async {
    if (!TokenStore.isLoggedIn) return;
    await AppRepository.submitReview(
      orderId: orderId,
      restaurantRating: rating,
      foodRating: rating,
    );
  }

  Future<void> cancelActiveOrder({String reason = 'Changed my mind'}) async {
    if (activeOrderId == null) return;
    await AppRepository.cancelOrder(activeOrderId!, reason);
    activeOrderId = null;
    await AppRepository.syncOrders();
    notifyListeners();
  }

  Future<void> createSupportFromChat(String text) async {
    if (!TokenStore.isLoggedIn) return;
    final lower = text.toLowerCase();
    var type = 'OTHER';
    if (lower.contains('cancel')) type = 'REFUND_REQUEST';
    if (lower.contains('payment') || lower.contains('billing')) type = 'PAYMENT_ISSUE';
    if (lower.contains('where') || lower.contains('track')) type = 'DELIVERY_ISSUE';
    if (lower.contains('wrong') || lower.contains('missing')) type = 'WRONG_ORDER';
    await AppRepository.createSupportTicket(
      orderId: activeOrderId,
      type: type,
      description: text,
      priority: 'MEDIUM',
    );
  }

  Future<void> initializeSupportChat() async {
    if (!TokenStore.isLoggedIn) {
      supportChatError = 'Please sign in to access support chat.';
      supportChatReady = false;
      notifyListeners();
      return;
    }
    try {
      supportChatError = null;
      supportChatReady = false;
      notifyListeners();
      await _supportChatService.connect();
      supportChatReady = true;
      notifyListeners();
    } catch (e) {
      supportChatReady = false;
      supportChatError = e.toString();
      notifyListeners();
    }
  }

  Future<void> startSupportChat({String? topic}) async {
    if (!TokenStore.isLoggedIn) {
      supportChatError = 'Please sign in to access support chat.';
      supportChatReady = false;
      notifyListeners();
      return;
    }
    try {
      supportChatError = null;
      supportChatReady = false;
      notifyListeners();
      final sessionId = await _supportChatService.startSession(orderId: activeOrderId);
      activeSupportSessionId = sessionId;
      supportChatReady = true;
      if (topic != null) {
        chatMessages.add(ChatMessage(text: topic, fromCustomer: true, time: _timeNow()));
        await _supportChatService.sendMessage(sessionId, topic);
      }
      notifyListeners();
    } catch (e) {
      supportChatReady = false;
      supportChatError = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendSupportChatMessage(String text) async {
    if (activeSupportSessionId == null) {
      await startSupportChat(topic: text);
      return;
    }
    chatMessages.add(ChatMessage(text: text.trim(), fromCustomer: true, time: _timeNow()));
    notifyListeners();
    await _supportChatService.sendMessage(activeSupportSessionId!, text.trim());
  }

  void listenForSupportChatMessages() {
    _supportChatService.events.listen((event) {
      switch (event.type) {
        case SupportChatEventType.authenticated:
        case SupportChatEventType.connected:
          supportChatReady = true;
          supportChatError = null;
          break;
        case SupportChatEventType.messageReceived:
          if (event.message != null) {
            chatMessages.add(event.message!);
          }
          break;
        case SupportChatEventType.error:
          supportChatError = event.error;
          supportChatReady = false;
          break;
        case SupportChatEventType.sessionStarted:
          if (event.sessionId != null) activeSupportSessionId = event.sessionId;
          if (event.messages != null) {
            chatMessages
              ..clear()
              ..addAll(event.messages!);
          }
          break;
        case SupportChatEventType.closed:
          supportChatReady = false;
          break;
      }
      notifyListeners();
    });
  }

  Future<void> topupWallet(num amount) async {
    await AppRepository.topupWallet(amount);
    notifyListeners();
  }

  Future<void> logoutAllDevices() async {
    await AppRepository.logoutAll();
    _remoteCartItemIds.clear();
    cart.clear();
    resetAuth();
    userName = 'Guest';
    userInitials = 'G';
    userEmail = '';
    userPhone = '';
    stack = ['onboarding'];
    notifyListeners();
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  // ---- navigation ----

  void push(String s) {
    stack.add(s);
    trackMenuOpen = false;
    notifyListeners();
  }

  void back() {
    if (stack.length > 1) {
      stack.removeLast();
    } else {
      stack = ['home'];
    }
    trackMenuOpen = false;
    notifyListeners();
  }

  /// System/hardware back: pop overlays in the custom stack, otherwise return
  /// to Home. Returns `true` if the OS may exit the app (already on Home).
  bool handleSystemBack() {
    if (stack.length > 1) {
      back();
      return false;
    }
    if (screen == 'home' || screen == 'splash') {
      return true;
    }
    // Dining / Delivery tabs / Orders / Account / Search → Home (don't exit).
    toHome();
    return false;
  }

  void setTab(String s) {
    stack = [s];
    trackMenuOpen = false;
    notifyListeners();
  }

  void toOrders() {
    setTab('orders');
    refreshOrders();
  }

  void toAccount() {
    setTab('account');
    refreshAccount();
  }

  void toHome() {
    final already = screen == 'home';
    setTab('home');
    // Avoid re-triggering heavy GPS/API work on every Home tap (causes UI glitches).
    if (!already) {
      // ignore: unawaited_futures
      refreshHome();
    }
  }
  void toSearch() => setTab('search');
  void toDining() => setTab('dining');
  void toList() => push('list');
  void toPayment() {
    paymentContext = 'checkout';
    push('payment');
    AppRepository.syncWallet().then((_) => notifyListeners());
    AppRepository.syncWalletTransactions().then((_) => notifyListeners());
  }

  void goToBookingPayment() {
    paymentContext = 'booking';
    push('payment');
  }
  void toCart() => push('cart');
  void toCoupons() => push('coupons');
  void toHelp() {
    trackMenuOpen = false;
    push('help');
    refreshHelp();
  }

  Future<void> openChat({String? topic}) async {
    trackMenuOpen = false;
    chatMessages.clear();
    chatMessages.add(ChatMessage(
      text: "Hi ${store.userName.split(' ').first}! I can help you with your order, delivery, refunds, or account questions.",
      fromCustomer: false,
      time: _timeNow(),
    ));
    if (topic != null) {
      await createSupportFromChat(topic);
      await startSupportChat(topic: topic);
    } else {
      await initializeSupportChat();
      await startSupportChat();
    }
    push('chat');
  }

  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;
    await createSupportFromChat(text.trim());
    await sendSupportChatMessage(text.trim());
  }

  Future<void> openRest(String id) async {
    rid = id;
    if (appliedCouponCode != null &&
        !couponsForCurrentRestaurant.any((c) => c.code == appliedCouponCode)) {
      appliedCouponCode = null;
    }
    push('menu');
    await Future.wait([
      AppRepository.syncRestaurantDetails(id),
      AppRepository.syncMenu(id),
      AppRepository.syncRestaurantCoupons(id),
    ]);
    notifyListeners();
  }

  void openBooking(String id) {
    bookingRid = id;
    bDateIdx = 0;
    bTimeIdx = 2;
    bGuests = 2;
    push('booking');
  }

  Future<void> openProfile(String id) async {
    bookingRid = id;
    push('profile');
    await AppRepository.syncRestaurantDetails(id);
    await AppRepository.restaurantReviews(id);
    notifyListeners();
  }

  void confirmBooking() {
    final when =
        '${store.bookingDates[bDateIdx]} · ${store.bookingTimes[bTimeIdx]} PM';
    final guests = '$bGuests ${bGuests == 1 ? 'guest' : 'guests'}';
    final id = 'FZB${1000 + _rand.nextInt(9000)}';
    final booking = Booking(
      id: id,
      restaurantId: bookingRid,
      when: when,
      guests: guests,
      feePaid: store.bookingFee,
      paymentMethodId: selectedPay,
    );
    bookings.insert(0, booking);
    lastBooking = booking;
    push('booking-done');
  }

  Future<void> logout() async {
    try {
      if (TokenStore.isLoggedIn) {
        await CustomerAuthApi.logout();
      }
    } catch (_) {
      await TokenStore.clear();
    }
    _remoteCartItemIds.clear();
    cart.clear();
    resetAuth();
    userName = 'Guest';
    userInitials = 'G';
    userEmail = '';
    userPhone = '';
    stack = ['onboarding'];
    notifyListeners();
  }

  /// Guest skip — live nearby + Guest profile (no dummy Rahul name).
  void continueAsGuest() {
    resetAuth();
    store.userName = 'Guest';
    store.userInitials = 'G';
    store.userEmail = '';
    store.userPhone = '';
    toHome();
  }

  void noop() {}

  // ---- cart ----

  Future<void> add(String id) async {
    cart[id] = (cart[id] ?? 0) + 1;
    notifyListeners();
    if (!TokenStore.isLoggedIn) return;
    try {
      final remoteId = _remoteCartItemIds[id];
      if (remoteId != null) {
        await CustomerCartApi.updateItem(remoteId, cart[id]!);
      } else {
        final res = await CustomerCartApi.addItem(
          menuItemId: id,
          branchId: rid,
          quantity: cart[id]!,
        );
        final data = RemoteMappers.unwrap(res);
        if (data is Map) {
          final itemId = (data['id'] ?? data['_id'] ?? data['cartItemId'])?.toString();
          if (itemId != null && itemId.isNotEmpty) {
            _remoteCartItemIds[id] = itemId;
          }
        }
      }
    } catch (e) {
      debugPrint('[AppController] cart add sync failed: $e');
    }
  }

  Future<void> sub(String id) async {
    final qty = (cart[id] ?? 0) - 1;
    if (qty <= 0) {
      cart.remove(id);
      final remoteId = _remoteCartItemIds.remove(id);
      notifyListeners();
      if (TokenStore.isLoggedIn && remoteId != null) {
        try {
          await CustomerCartApi.removeItem(remoteId);
        } catch (_) {/* fail-soft */}
      }
    } else {
      cart[id] = qty;
      notifyListeners();
      final remoteId = _remoteCartItemIds[id];
      if (TokenStore.isLoggedIn && remoteId != null) {
        try {
          await CustomerCartApi.updateItem(remoteId, qty);
        } catch (_) {/* fail-soft */}
      }
    }
  }

  int qtyOf(String id) => cart[id] ?? 0;

  List<MapEntry<MenuItem, int>> get cartLines => cart.entries
      .where((e) => e.value > 0 && menu.any((m) => m.id == e.key))
      .map((e) => MapEntry(menuItemById(e.key), e.value))
      .toList();

  int get cartCount => cart.values.fold(0, (a, b) => a + b);

  bool get hasCart => cartCount > 0;
  bool get cartEmpty => !hasCart;

  int get orderBadgeCount {
    final pastCount = store.pastOrders.length;
    return activeOrderId != null ? pastCount + 1 : pastCount;
  }

  int get itemsTotal =>
      cartLines.fold(0, (sum, l) => sum + l.key.price * l.value);

  List<Coupon> get couponsForCurrentRestaurant =>
      coupons.where((c) => c.isApplicableTo(rid)).toList();

  Coupon? get appliedCoupon {
    if (appliedCouponCode == null) return null;
    for (final c in couponsForCurrentRestaurant) {
      if (c.code == appliedCouponCode) return c;
    }
    return null;
  }

  int get discount => itemsTotal > 0 ? (appliedCoupon?.discountFor(itemsTotal) ?? 0) : 0;

  int get deliveryFee => deliveryType == 'bolt' ? 0 : 20;

  int get taxes => itemsTotal > 0 ? (itemsTotal * 0.05).round() : 0;

  int get grandTotal =>
      max(0, itemsTotal - discount + deliveryFee + taxes);

  Future<void> applyCoupon(String code) async {
    appliedCouponCode = code;
    notifyListeners();
    if (!TokenStore.isLoggedIn) return;
    try {
      await CustomerCartApi.applyCoupon(code);
    } catch (e) {
      debugPrint('[AppController] applyCoupon sync failed: $e');
    }
  }

  Future<void> removeCoupon() async {
    appliedCouponCode = null;
    notifyListeners();
    if (!TokenStore.isLoggedIn) return;
    try {
      await CustomerCartApi.removeCoupon();
    } catch (_) {/* fail-soft */}
  }

  void setBolt() {
    deliveryType = 'bolt';
    notifyListeners();
  }

  void setEco() {
    deliveryType = 'eco';
    notifyListeners();
  }

  void choosePay(String id) {
    selectedPay = id;
    if (paymentContext == 'booking') {
      confirmBooking();
    } else {
      back();
    }
  }

  String _paymentMethodForApi() {
    switch (selectedPay) {
      case 'foodeez-wallet':
        return 'WALLET';
      case 'cod':
        return 'COD';
      default:
        return 'ONLINE';
    }
  }

  Future<void> placeOrder() async {
    checkoutError = null;

    if (!TokenStore.isLoggedIn) {
      requireAuthForCheckout();
      return;
    }

    isPlacingOrder = true;
    notifyListeners();

    try {
      final hasAddress = await AppRepository.ensureDefaultAddressForCheckout();
      if (!hasAddress ||
          store.defaultAddressId == null ||
          store.defaultAddressId!.isEmpty) {
        checkoutError =
            'Please add a delivery address in Account before placing your order.';
        return;
      }

      final method = _paymentMethodForApi();
      final addressId = store.defaultAddressId!;

      if (method == 'ONLINE') {
        await _placeOrderWithRazorpay(addressId);
        return;
      }

      final res = await CustomerOrdersApi.place(
        deliveryAddressId: addressId,
        paymentMethod: method,
        useWalletBalance: method == 'WALLET',
      );
      await _onOrderPlacedSuccess(res);
    } on ApiException catch (e) {
      checkoutError = e.message;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      checkoutError = msg.isNotEmpty
          ? msg
          : 'Could not place order. Please try again.';
      debugPrint('[AppController] placeOrder failed: $e');
    } finally {
      isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<void> _placeOrderWithRazorpay(String addressId) async {
    final initRes = await CustomerPaymentsApi.initiatePayment(
      deliveryAddressId: addressId,
      gateway: 'razorpay',
    );
    final payment = RemoteMappers.unwrap(initRes);
    if (payment is! Map) {
      throw Exception('Could not start payment. Please try again.');
    }

    final keyId =
        (payment['keyId'] ?? payment['key_id'] ?? '').toString();
    final razorpayOrderId = (payment['razorpayOrderId'] ??
            payment['razorpay_order_id'] ??
            payment['order_id'] ??
            '')
        .toString();
    final currency = (payment['currency'] ?? 'INR').toString();
    final description = payment['description']?.toString();
    final amountRaw = payment['amount'];
    final amount = amountRaw is num
        ? amountRaw.toInt()
        : int.tryParse('$amountRaw') ?? 0;

    if (keyId.isEmpty || razorpayOrderId.isEmpty || amount <= 0) {
      throw Exception('Could not start payment. Please try again.');
    }

    final contact = store.userPhone.replaceAll(RegExp(r'\D'), '');
    final response = await RazorpayCheckout.open(
      keyId: keyId,
      amount: amount,
      currency: currency,
      razorpayOrderId: razorpayOrderId,
      name: store.userName != 'Guest' ? store.userName : 'FooDeeZ Customer',
      email: store.userEmail.isNotEmpty ? store.userEmail : null,
      contact: contact.length >= 10 ? contact : null,
      description: description,
    );

    final verifyRes = await CustomerPaymentsApi.verifyPayment(
      razorpayOrderId: razorpayOrderId,
      paymentId: response['paymentId'] ?? '',
      signature: response['signature'] ?? '',
      gateway: 'razorpay',
    );
    await _onOrderPlacedSuccess(verifyRes);
  }

  Future<void> _onOrderPlacedSuccess(dynamic res) async {
    final data = RemoteMappers.unwrap(res);
    if (data is Map) {
      activeOrderId =
          (data['orderId'] ?? data['id'] ?? data['_id'])?.toString();
    }
    cart.clear();
    _remoteCartItemIds.clear();
    appliedCouponCode = null;
    await AppRepository.syncOrders();
    push('tracking');
  }

  Future<void> fetchTracking() async {
    if (activeOrderId == null || !TokenStore.isLoggedIn) return;
    await AppRepository.tracking(activeOrderId!);
  }

  Future<void> clearRemoteCart() async {
    cart.clear();
    _remoteCartItemIds.clear();
    notifyListeners();
    if (!TokenStore.isLoggedIn) return;
    try {
      await CustomerCartApi.clear();
    } catch (_) {/* fail-soft */}
  }

  void toggleVegOnly() {
    vegOnly = !vegOnly;
    notifyListeners();
  }

  bool sortByRating = false;
  bool fastDeliveryOnly = false;
  bool minRating4 = false;

  void toggleSortByRating() {
    sortByRating = !sortByRating;
    notifyListeners();
  }

  void toggleFastDelivery() {
    fastDeliveryOnly = !fastDeliveryOnly;
    notifyListeners();
  }

  void toggleMinRating4() {
    minRating4 = !minRating4;
    notifyListeners();
  }

  List<Restaurant> get visibleRestaurants {
    var list = vegOnly ? restaurants.where((r) => r.veg).toList() : List.of(restaurants);
    if (minRating4) list = list.where((r) => r.rating >= 4.0).toList();
    if (fastDeliveryOnly) list = list.where((r) => _isFast(r.time)).toList();
    if (sortByRating) list.sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }

  bool _isFast(String time) {
    final match = RegExp(r'\d+').firstMatch(time);
    if (match == null) return true;
    return int.parse(match.group(0)!) <= 25;
  }

  // ---- orders tab ----

  void setOrdersDelivery() {
    ordersTab = 'delivery';
    notifyListeners();
  }

  void setOrdersDining() {
    ordersTab = 'dining';
    notifyListeners();
  }

  // ---- booking guest stepper ----

  void incG() {
    if (bGuests < 20) bGuests++;
    notifyListeners();
  }

  void decG() {
    if (bGuests > 1) bGuests--;
    notifyListeners();
  }

  void setBDate(int i) {
    bDateIdx = i;
    notifyListeners();
  }

  void setBTime(int i) {
    bTimeIdx = i;
    notifyListeners();
  }

  // ---- tracking "..." menu ----

  void toggleTrackMenu() {
    trackMenuOpen = !trackMenuOpen;
    notifyListeners();
  }

  void closeTrackMenu() {
    trackMenuOpen = false;
    notifyListeners();
  }

  // ---- dock ----

  static const hideTabScreens = {
    'splash',
    'onboarding',
    'menu',
    'cart',
    'payment',
    'tracking',
    'booking',
    'booking-done',
    'help',
    'chat',
    'profile',
    'coupons',
  };

  bool get showTabBar => !hideTabScreens.contains(screen);

  static const _tabOf = {
    'home': 'home',
    'list': 'home',
    'search': 'search',
    'dining': 'dining',
    'orders': 'orders',
    'account': 'account',
  };

  String get activeTab => _tabOf[screen] ?? '';
}
