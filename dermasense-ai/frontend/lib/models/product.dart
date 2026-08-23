class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double rating;
  final String description;
  final List<String> suitableSkinTypes;
  final List<String> targetedConcerns;
  final List<String> keyIngredients;
  final List<String> pros;
  final List<String> cons;
  final bool isSustainable;
  final String imageUrl;
  final String productUrl;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.rating,
    required this.description,
    required this.suitableSkinTypes,
    required this.targetedConcerns,
    required this.keyIngredients,
    required this.pros,
    required this.cons,
    this.isSustainable = false,
    required this.imageUrl,
    required this.productUrl,
  });
}
