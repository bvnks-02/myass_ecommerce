import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.brand,
    required super.model,
    required super.description,
    required super.price,
    required super.image,
    super.images = const [],
    super.colors = const [],
    super.sizes = const [],
    super.features = const {},
    required super.categoryId,
    required super.category,
    super.isFeatured = false,
    super.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? json['product_name'] ?? '',
      brand: json['brand'] ?? json['name']?.toString().split(' ').first ?? '',
      model: json['model'] ?? json['name']?.toString().split(' ').last ?? '',
      description: json['description'] ?? json['product_description'] ?? '',
      price: json['price'] is double
          ? json['price']
          : double.parse((json['price'] ?? 0.0).toString()),
      image: json['image_url'] ?? json['image'] ?? json['product_image'] ?? '',
      images: json['images'] is List
          ? List<String>.from(json['images'])
          : (json['image_url'] != null ? [json['image_url']] : []),
      colors: json['colors'] is List
          ? List<String>.from(json['colors'])
          : (json['color'] != null ? [json['color'].toString()] : []),
      sizes: json['sizes'] is List
          ? List<String>.from(json['sizes'])
          : (json['size'] != null ? [json['size'].toString()] : []),
      features: json['features'] is Map
          ? Map<String, dynamic>.from(json['features'])
          : {},
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.parse((json['category_id'] ?? 0).toString()),
      category: json['category_name'] ?? json['category'] ?? json['product_category'] ?? '',
      isFeatured: json['is_featured'] ?? json['featured'] ?? false,
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'description': description,
      'price': price,
      'image_url': image,
      'images': images,
      'colors': colors,
      'sizes': sizes,
      'features': features,
      'category_id': categoryId,
      'category_name': category,
      'is_featured': isFeatured,
    };
  }
}
