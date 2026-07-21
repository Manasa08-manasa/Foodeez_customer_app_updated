class PastOrder {
  final String id;
  final String restaurantId;
  final String items;
  final int total;
  final String when;
  final int rating;

  const PastOrder({
    required this.id,
    required this.restaurantId,
    required this.items,
    required this.total,
    required this.when,
    required this.rating,
  });
}
