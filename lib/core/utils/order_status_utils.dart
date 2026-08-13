/// Mirrors website customer orders status maps
/// (`app/(customer)/customer/orders/page.tsx` + `[orderId]/page.tsx`).
class OrderStatusUtils {
  OrderStatusUtils._();

  static const activeStatuses = {
    'PLACED',
    'CONFIRMED',
    'PREPARING',
    'ASSIGNED',
    'READY_FOR_PICKUP',
    'ACCEPTED',
    'PICKED_UP',
    'ON_THE_WAY',
    'ARRIVED',
  };

  static const aliases = <String, String>{
    'PLACED': 'PLACED',
    'CONFIRMED': 'CONFIRMED',
    'PREPARING': 'PREPARING',
    'READY': 'READY_FOR_PICKUP',
    'READY_FOR_PICKUP': 'READY_FOR_PICKUP',
    'ASSIGNED': 'ASSIGNED',
    'ACCEPTED': 'ACCEPTED',
    'PICKED_UP': 'PICKED_UP',
    'ON_THE_WAY': 'ON_THE_WAY',
    'ARRIVED': 'ARRIVED',
    'DELIVERED': 'DELIVERED',
    'COMPLETED': 'DELIVERED',
    'CANCELLED': 'CANCELLED',
    'REJECTED': 'CANCELLED',
    'FAILED': 'CANCELLED',
  };

  /// Journey steps shown on the live tracking screen (website TRACKING_STEPS).
  static const trackingSteps = <OrderTrackingStep>[
    OrderTrackingStep(
      key: 'CONFIRMED',
      title: 'Order Confirmed',
      subtitle: 'Your order has been placed',
    ),
    OrderTrackingStep(
      key: 'PREPARING',
      title: 'Food Being Prepared',
      subtitle: 'Chef is cooking your order',
    ),
    OrderTrackingStep(
      key: 'ASSIGNED',
      title: 'Delivery Partner Assigned',
      subtitle: 'Partner has been assigned',
    ),
    OrderTrackingStep(
      key: 'READY_FOR_PICKUP',
      title: 'Ready for Pickup',
      subtitle: 'Order is ready and waiting for pickup',
    ),
    OrderTrackingStep(
      key: 'ACCEPTED',
      title: 'Delivery Partner Accepted',
      subtitle: 'Partner is on the way to collect',
    ),
    OrderTrackingStep(
      key: 'PICKED_UP',
      title: 'Food Picked Up',
      subtitle: 'Partner collected your order',
    ),
    OrderTrackingStep(
      key: 'ON_THE_WAY',
      title: 'On The Way',
      subtitle: 'Heading to your address',
    ),
    OrderTrackingStep(
      key: 'DELIVERED',
      title: 'Order Delivered',
      subtitle: 'Order delivered — enjoy!',
    ),
  ];

  static const _stepMap = <String, String>{
    'PLACED': 'CONFIRMED',
    'ASSIGNED': 'ASSIGNED',
    'ACCEPTED': 'ACCEPTED',
    'READY_FOR_PICKUP': 'READY_FOR_PICKUP',
    'ARRIVED': 'ON_THE_WAY',
    'PICKED_UP': 'PICKED_UP',
  };

  static const statusLabels = <String, String>{
    'PLACED': 'Order Placed',
    'CONFIRMED': 'Confirmed',
    'PREPARING': 'Preparing',
    'ASSIGNED': 'Partner Assigned',
    'READY_FOR_PICKUP': 'Ready for Pickup',
    'ACCEPTED': 'Partner Accepted',
    'PICKED_UP': 'Picked Up',
    'ON_THE_WAY': 'On the Way',
    'ARRIVED': 'Arrived',
    'DELIVERED': 'Delivered',
    'CANCELLED': 'Cancelled',
  };

  /// Heuristic ETA minutes by status (website ETACountdown).
  static const etaMinsByStatus = <String, int>{
    'PLACED': 45,
    'CONFIRMED': 40,
    'PREPARING': 30,
    'READY': 15,
    'READY_FOR_PICKUP': 15,
    'ASSIGNED': 20,
    'ACCEPTED': 18,
    'PICKED_UP': 12,
    'ON_THE_WAY': 8,
    'ARRIVED': 3,
  };

  static String normalize(String? status) {
    final value = (status ?? '').trim().toUpperCase();
    if (value.isEmpty) return 'PLACED';
    return aliases[value] ?? value;
  }

  static bool isActive(String? status) =>
      activeStatuses.contains(normalize(status));

  static bool isPast(String? status) => !isActive(status);

  static String label(String? status) {
    final n = normalize(status);
    return statusLabels[n] ?? n.replaceAll('_', ' ');
  }

  static int stepIndex(String? status, {bool hasDeliveryPartner = false}) {
    final n = normalize(status);
    if (n == 'ACCEPTED' && !hasDeliveryPartner) {
      return trackingSteps.indexWhere((s) => s.key == 'CONFIRMED');
    }
    final resolved = _stepMap[n] ?? n;
    final i = trackingSteps.indexWhere((s) => s.key == resolved);
    return i < 0 ? 0 : i;
  }

  static String headline(String? status, {bool hasDeliveryPartner = false}) {
    final idx = stepIndex(status, hasDeliveryPartner: hasDeliveryPartner);
    return trackingSteps[idx].title;
  }

  static String subtitle(String? status, {bool hasDeliveryPartner = false}) {
    final idx = stepIndex(status, hasDeliveryPartner: hasDeliveryPartner);
    return trackingSteps[idx].subtitle;
  }

  /// Remaining minutes from createdAt + status heuristic, or live [etaMins].
  static int? remainingEtaMins({
    required String? status,
    String? createdAt,
    int? liveEtaMins,
  }) {
    if (liveEtaMins != null && liveEtaMins > 0) return liveEtaMins;
    final n = normalize(status);
    final base = etaMinsByStatus[n];
    if (base == null) return null;
    final dt = DateTime.tryParse(createdAt ?? '');
    if (dt == null) return base;
    final elapsed = DateTime.now().difference(dt.toLocal()).inMinutes;
    return (base - elapsed).clamp(0, base);
  }

  /// Past-order list format: `13 Aug 2026, 11:28 am`
  static String formatPastDateTime(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return iso ?? '';
    final local = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'pm' : 'am';
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year}, $h:$mm $ampm';
  }

  /// Tracking header format: `Aug 13, 11:28 am`
  static String formatTrackingDateTime(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return iso ?? '';
    final local = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'pm' : 'am';
    final mm = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, $h:$mm $ampm';
  }
}

class OrderTrackingStep {
  const OrderTrackingStep({
    required this.key,
    required this.title,
    required this.subtitle,
  });

  final String key;
  final String title;
  final String subtitle;
}
