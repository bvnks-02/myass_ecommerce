import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String brand;
  final String model;
  final String description;
  final double price;
  final String image;
  final List<String> images;
  final List<String> colors;
  final List<String> sizes;
  final Map<String, dynamic> features;
  final int categoryId;
  final String category;
  final bool isFeatured;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.description,
    required this.price,
    required this.image,
    this.images = const [],
    this.colors = const [],
    this.sizes = const [],
    this.features = const {},
    required this.categoryId,
    required this.category,
    this.isFeatured = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        model,
        description,
        price,
        image,
        images,
        colors,
        sizes,
        features,
        categoryId,
        category,
        isFeatured,
      ];
}
