import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.image,
    required super.categoryId,
    required super.category,
    super.isFeatured,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? json['product_name'] ?? '',
      description: json['description'] ?? json['product_description'] ?? '',
      price: json['price'] is double
          ? json['price']
          : double.parse((json['price'] ?? 0.0).toString()),
      image: json['image_url'] ?? json['image'] ?? json['product_image'] ?? '',
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.parse((json['category_id'] ?? 0).toString()),
      category: json['category_name'] ?? json['category'] ?? json['product_category'] ?? '',
      isFeatured: json['is_featured'] ?? json['featured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': image,
      'category_id': categoryId,
      'category_name': category,
      'is_featured': isFeatured,
    };
  }
}
