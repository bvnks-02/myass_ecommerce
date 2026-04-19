import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final int categoryId;
  final String category;
  final bool isFeatured;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.categoryId,
    required this.category,
    this.isFeatured = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        image,
        categoryId,
        category,
        isFeatured,
      ];
}
