class Booking {
  final String id;
  final String restaurantId;
  final String when;
  final String guests;
  final int feePaid;
  final String paymentMethodId;

  const Booking({
    required this.id,
    required this.restaurantId,
    required this.when,
    required this.guests,
    this.feePaid = 0,
    this.paymentMethodId = 'foodeez-upi',
  });
}
