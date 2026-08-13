class PastOrder {
  /// Backend UUID — use for API routes (get / tracking / cancel / reorder).
  final String orderId;

  /// Human-facing id (e.g. FDZ-2026-00001).
  final String orderNumber;

  final String restaurantId;
  final String restaurantName;
  final String items;
  final int itemCount;
  final int total;
  final String status;

  /// ISO timestamp from API (`createdAt`).
  final String createdAt;

  /// Display string for list rows (en-IN style).
  final String when;
  final int rating;

  const PastOrder({
    required this.orderId,
    required this.orderNumber,
    required this.restaurantId,
    this.restaurantName = '',
    required this.items,
    this.itemCount = 0,
    required this.total,
    this.status = 'PLACED',
    this.createdAt = '',
    required this.when,
    this.rating = 0,
  });

  /// Back-compat alias — prefer [orderId] for API calls.
  String get id => orderId;

  String get displayName =>
      restaurantName.isNotEmpty ? restaurantName : 'Order #$orderNumber';
}
