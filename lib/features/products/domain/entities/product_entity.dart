import 'package:equatable/equatable.dart';

class ReviewEntity {
  final int stars;
  final String text;
  final String? userName;

  const ReviewEntity({
    required this.stars,
    required this.text,
    this.userName,
  });

  Map<String, dynamic> toJson() => {
        'stars': stars,
        'text': text,
        'userName': userName,
      };

  factory ReviewEntity.fromJson(Map<String, dynamic> json) => ReviewEntity(
        stars: json['stars'] as int,
        text: json['text'] as String,
        userName: json['userName'] as String?,
      );
}

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
  final double rating;
  final int reviewCount;
  final List<ReviewEntity> reviews;
  final bool isAvailable;

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
    this.rating = 4.8,
    this.reviewCount = 320,
    this.reviews = const [],
    this.isAvailable = true,
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
        rating,
        reviewCount,
        reviews,
        isAvailable,
      ];
}
