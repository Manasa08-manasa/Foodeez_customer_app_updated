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
  });
}

class Category {
  final String name;
  final String photoKey;
  const Category(this.name, this.photoKey);
}
