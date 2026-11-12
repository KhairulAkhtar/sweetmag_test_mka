class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    return Product(
      id: int.tryParse('${json['id']}') ?? 0,
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0,
      stock: int.tryParse('${json['stock']}') ?? 0,
      thumbnail: '${json['thumbnail'] ?? ''}',
      images: rawImages is List ? rawImages.map((e) => '$e').toList() : const [],
    );
  }
}
