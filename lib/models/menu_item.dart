class MenuItem {
  final String id;
  final String section;
  final String name;
  final String desc;
  final int price;
  final bool veg;
  final double rating;
  final String ratingsCount;
  final bool bestseller;
  final String photoKey;
  /// Backend availability — when false, item cannot be added to cart.
  final bool isInStock;
  /// Merchant setting: stock can auto-toggle availability.
  final bool autoOutOfStock;
  final bool isVisible;

  const MenuItem({
    required this.id,
    required this.section,
    required this.name,
    required this.desc,
    required this.price,
    required this.veg,
    required this.rating,
    required this.ratingsCount,
    required this.bestseller,
    required this.photoKey,
    this.isInStock = true,
    this.autoOutOfStock = false,
    this.isVisible = true,
  });

  /// Cannot order when backend marks the item out of stock.
  bool get isOutOfStock => !isInStock;
}

class Category {
  final String name;
  final String photoKey;
  const Category(this.name, this.photoKey);
}
