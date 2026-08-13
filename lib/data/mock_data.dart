import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_config.dart';
import '../theme.dart';

/// Unsplash photo IDs used by the original design, keyed by dish/category.
const Map<String, String> _photoIds = {
  'biryani': '1631515243349-e0cb75fb8d3a',
  'burger': '1568901346375-23c9450c58cd',
  'pizza': '1513104890138-7c749659a591',
  'icecream': '1497034825429-c343d7c6a68f',
  'dosa': '1668236543090-82eba5ee5976',
  'idli': '1589301760014-d929f3979dbc',
  'momo': '1496116218417-1a781b1c416c',
  'kebab': '1633945274405-b6c8069047b0',
  'paneer': '1631452180519-c014fe946bc7',
  'thali': '1585937421612-70a008356fbe',
  'noodles': '1585032226651-759b368d7246',
  'rolls': '1626700051175-6818013e1d4f',
  'coffee': '1461023058943-07fcbe16d735',
  'cake': '1578985545062-69928b1d9587',
  'haleem': '1547928576-b822bc410bdf',
  'samosa': '1601050690597-df0568f70950',
  'coke': '1554866585-cd94860890b7',
  'gulab': '1571877227200-a0d98ea607e9',
  'curry': '1565557623262-b51c2513a641',
};

String foodImageUrl(String key, {int width = 520}) {
  // Absolute / resolved backend media URLs.
  if (key.startsWith('http://') ||
      key.startsWith('https://') ||
      key.startsWith('//')) {
    return key.startsWith('//') ? 'https:$key' : key;
  }
  final resolved = resolveMediaUrl(key);
  if (resolved != null &&
      (resolved.startsWith('http://') || resolved.startsWith('https://')) &&
      resolved != key &&
      !_photoIds.containsKey(key)) {
    return resolved;
  }
  if (key.startsWith('/') || key.contains('/uploads') || key.contains('/media')) {
    return resolveMediaUrl(key) ?? key;
  }
  final id = _photoIds[key] ?? _photoIds['biryani']!;
  return 'https://images.unsplash.com/photo-$id?w=$width&q=80&auto=format&fit=crop';
}

/// Live nearby results from [AppRepository.syncRestaurants] — starts empty (no mock seed).
final List<Restaurant> restaurants = [];

Restaurant restaurantById(String id) {
  for (final r in restaurants) {
    if (r.id == id) return r;
  }
  return Restaurant(
    id: id,
    name: 'Restaurant',
    cuisines: 'Multi-cuisine',
    description: '',
    address: '',
    rating: 4.0,
    time: '30-35 min',
    price: '₹300 for two',
    dist: '—',
    offer: '',
    veg: false,
    photoKey: 'biryani',
  );
}

const List<Category> categories = [
  Category('Biryani', 'biryani'),
  Category('Pizza', 'pizza'),
  Category('Burgers', 'burger'),
  Category('South Indian', 'dosa'),
  Category('Chinese', 'noodles'),
  Category('Desserts', 'cake'),
  Category('Thali', 'thali'),
  Category('Rolls', 'rolls'),
  Category('Coffee', 'coffee'),
  Category('Momos', 'momo'),
];

/// Live menu from [AppRepository.syncMenu] — starts empty (no mock seed).
final List<MenuItem> menu = [];

final List<String> menuSectionOrder = [];

MenuItem menuItemById(String id) {
  for (final m in menu) {
    if (m.id == id) return m;
  }
  return MenuItem(
    id: id,
    section: '',
    name: 'Item',
    desc: '',
    price: 0,
    veg: true,
    rating: 0,
    ratingsCount: '',
    bestseller: false,
    photoKey: 'biryani',
  );
}

const List<PaymentMethod> paymentMethods = [
  PaymentMethod(
    id: 'foodeez-upi',
    group: 'UPI',
    name: 'Foodeez UPI',
    sub: 'Fastest checkout · save ₹15',
    glyph: '',
    icon: Icons.flash_on_outlined,
    color: AppColors.accent,
  ),
  PaymentMethod(
    id: 'gpay',
    group: 'UPI',
    name: 'Google Pay',
    glyph: 'G',
    color: Color(0xFF4285F4),
  ),
  PaymentMethod(
    id: 'phonepe',
    group: 'UPI',
    name: 'PhonePe UPI',
    glyph: 'P',
    color: Color(0xFF5F259F),
  ),
  PaymentMethod(
    id: 'paytm',
    group: 'UPI',
    name: 'Paytm UPI',
    glyph: 'P',
    color: Color(0xFF00BAF2),
  ),
  PaymentMethod(
    id: 'foodeez-wallet',
    group: 'Wallets',
    name: 'Foodeez Wallet',
    sub: 'Balance ₹250',
    glyph: '₹',
    color: AppColors.gold,
  ),
  PaymentMethod(
    id: 'amazonpay',
    group: 'Wallets',
    name: 'Amazon Pay',
    sub: 'Balance ₹0',
    glyph: 'a',
    color: Color(0xFFFF9900),
  ),
  PaymentMethod(
    id: 'visa',
    group: 'Credit & Debit Cards',
    name: 'Visa •••• 4291',
    sub: 'HDFC Bank',
    glyph: '',
    icon: Icons.credit_card_outlined,
    color: AppColors.ink,
  ),
  PaymentMethod(
    id: 'add-card',
    group: 'Credit & Debit Cards',
    name: 'Add new card',
    sub: 'Save & pay faster',
    glyph: '＋',
    color: AppColors.bodyGrey,
  ),
  PaymentMethod(
    id: 'lazypay',
    group: 'Pay Later & Netbanking',
    name: 'LazyPay',
    sub: '1-tap, pay by 5th',
    glyph: 'L',
    color: Color(0xFF122E7A),
  ),
  PaymentMethod(
    id: 'netbanking',
    group: 'Pay Later & Netbanking',
    name: 'Netbanking',
    sub: 'All major banks',
    glyph: '',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF5A6B7A),
  ),
  PaymentMethod(
    id: 'cod',
    group: 'Pay on Delivery',
    name: 'Cash on Delivery',
    sub: 'Pay when it arrives',
    glyph: '',
    icon: Icons.attach_money_outlined,
    color: AppColors.green,
  ),
];

const List<String> paymentGroupOrder = [
  'UPI',
  'Wallets',
  'Credit & Debit Cards',
  'Pay Later & Netbanking',
  'Pay on Delivery',
];

PaymentMethod paymentMethodById(String id) =>
    paymentMethods.firstWhere((p) => p.id == id);

/// Live order history from [AppRepository.syncOrders] — starts empty (no mock seed).
final List<PastOrder> pastOrders = [];

final List<Booking> seedBookings = [
  const Booking(
    id: 'FZB2274',
    restaurantId: 'barbeque',
    when: 'Fri 6 · 8:00 PM',
    guests: '4 guests',
    feePaid: bookingFee,
    paymentMethodId: 'foodeez-upi',
  ),
];

/// Flat, fully-refundable fee charged to hold a table reservation.
const int bookingFee = 99;

const List<PromoAd> promoAds = [
  PromoAd(
    title: 'Free delivery, 30 days',
    subtitle: 'On orders above ₹149 — no limits',
    cta: 'Try Foodeez Plus',
    gradient: [AppColors.accentDeep, AppColors.accentLight],
    photoKey: 'biryani',
  ),
  PromoAd(
    title: 'Flat 50% OFF',
    subtitle: 'On your next 3 orders this week',
    cta: 'Grab offer',
    gradient: [AppColors.accentLight, AppColors.accent],
    photoKey: 'pizza',
  ),
  PromoAd(
    title: 'Refer & earn ₹100',
    subtitle: 'Invite friends — both of you win',
    cta: 'Invite now',
    gradient: [AppColors.gold, Color(0xFF9C7614)],
    photoKey: 'burger',
  ),
];

/// Coupons live on Foodeez's server-side in production and are either:
///  - approved & generated by a specific restaurant (scope: restaurant) — only
///    that restaurant's `restaurantIds` can redeem it, or
///  - created by Foodeez's admin/tech team (scope: global) — valid at every
///    restaurant, unless the admin scoped it to a chosen subset via
///    `restaurantIds`.
/// The checkout screen must only ever show/apply a coupon whose
/// `isApplicableTo(currentRestaurantId)` is true.
final List<Coupon> coupons = [
  Coupon(
    code: 'WELCOME50',
    title: '50% OFF',
    subtitle: 'up to ₹100 on your first order · all restaurants',
    scope: CouponScope.global,
    discountType: CouponDiscountType.percent,
    discountValue: 50,
    maxDiscount: 100,
    minOrderValue: 0,
    issuedBy: 'Foodeez',
    gradient: [AppColors.accent, AppColors.accentLight],
  ),
  Coupon(
    code: 'FREEDEL',
    title: 'Free Delivery',
    subtitle: 'on all orders above ₹199 · all restaurants',
    scope: CouponScope.global,
    discountType: CouponDiscountType.flat,
    discountValue: 20,
    minOrderValue: 199,
    issuedBy: 'Foodeez',
    gradient: [AppColors.gold, Color(0xFF9C7614)],
  ),
  Coupon(
    code: 'BIRYANIFEST',
    title: '₹75 OFF',
    subtitle: 'Foodeez biryani festival · select restaurants only',
    scope: CouponScope.global,
    discountType: CouponDiscountType.flat,
    discountValue: 75,
    minOrderValue: 249,
    restaurantIds: ['paradise', 'barbeque'],
    issuedBy: 'Foodeez',
    gradient: [AppColors.accentDeep, Color(0xFF7A2E56)],
  ),
  Coupon(
    code: 'PARADISE20',
    title: '20% OFF',
    subtitle: 'Paradise Biryani special · this restaurant only',
    scope: CouponScope.restaurant,
    discountType: CouponDiscountType.percent,
    discountValue: 20,
    maxDiscount: 80,
    minOrderValue: 199,
    restaurantIds: ['paradise'],
    issuedBy: 'Paradise Biryani',
    gradient: [AppColors.accent, AppColors.accentDeep],
  ),
  Coupon(
    code: 'TRUFFLE15',
    title: '₹150 OFF',
    subtitle: 'Truffles anniversary offer · this restaurant only',
    scope: CouponScope.restaurant,
    discountType: CouponDiscountType.flat,
    discountValue: 150,
    minOrderValue: 599,
    restaurantIds: ['truffles'],
    issuedBy: 'Truffles',
    gradient: [AppColors.gold, Color(0xFF9C7614)],
  ),
];

const List<HelpTopic> helpTopics = [
  HelpTopic(
    'I want to give instructions to the Delivery Partner',
    answer: 'You can add delivery instructions like landmarks or gate codes. This helps your rider find you faster.',
  ),
  HelpTopic(
    'I want to provide food preparation instructions to the restaurant',
    answer: 'Let the restaurant know about spice level, allergies, or any special requests for this order.',
  ),
  HelpTopic(
    'I want to modify items in this order',
    answer: 'Orders can only be modified within 2 minutes of placing them. After that, please cancel and reorder.',
  ),
  HelpTopic('Where is my order?', expandable: false),
  HelpTopic('I want to cancel my order.', expandable: false),
  HelpTopic(
    'I have coupon related query for this order',
    answer: 'Coupons are validated automatically at checkout. If a discount didn\'t apply, our team can look into it.',
  ),
  HelpTopic('Payment and billing related query', expandable: false),
];

const String supportAgentName = 'Foodeez Support';

/// Canned auto-reply used when a topic doesn't have a more specific one below.
const String defaultAgentReply =
    "Thanks for reaching out! Let me pull up your order details — one moment.";

/// Canned first agent reply keyed by the Help topic label that opened the chat.
const Map<String, String> agentRepliesByTopic = {
  'Where is my order?':
      "Your order is on its way — the rider is about 1.2 km from your address and should arrive shortly. You can track it live on the order screen.",
  'I want to cancel my order.':
      "I'm sorry to hear that. Since your order is already being prepared, cancelling now may not be eligible for a full refund. Would you like me to check with the restaurant?",
  'Payment and billing related query':
      "Sure, I can help with that. Could you tell me a bit more about the payment or billing issue you're facing?",
};

// User / address — mutable so profile sync can update them (seed = offline fallback).
String userName = 'Guest';
String userPhone = '';
String userEmail = '';
String userInitials = 'G';
String shortAddress = '42, Banjara Hills, Hyderabad';
String homeAddress =
    '202 Sri Nilayam, Venkata Ramana Colony, Banjara Hills, Hyderabad';
const String restAddressGeneric =
    'Plot 149, 150, 151 & 152, 1st Floor, KPHB Colony, Hyderabad';
int walletBalance = 250;
String? defaultAddressId;

/// Synced from discovery / profile / payments — seed for offline fallback.
final List<String> trendingRestaurantIds = [];
final List<String> popularDishNames = [
  'Biryani',
  'Cold coffee',
  'Paradise',
];
final List<String> favoriteRestaurantIds = ['paradise'];
final List<String> favoriteMenuItemIds = ['chicken-biryani'];
final List<Map<String, dynamic>> addresses = [];
final List<Map<String, dynamic>> walletTransactions = [
  {'id': 'tx1', 'title': 'Wallet top-up', 'amount': 250, 'createdAt': ''},
];
final List<Map<String, dynamic>> supportTickets = [];
final Map<String, int> lastSyncedCart = {};
String? lastSyncedCouponCode;

const List<String> bookingDates = ['Today', 'Tomorrow', 'Wed 4', 'Thu 5', 'Fri 6'];
const List<String> bookingTimes = ['12:30', '1:00', '7:30', '8:00', '8:30', '9:00'];
