import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';

class ProductModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final String brand;
  final String category;

  final double price;
  final double discountPercentage;
  final double rating;

  final String thumbnail;
  final List<String> images;
  final String availabilityStatus;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.brand,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.thumbnail,
    required this.images,
    required this.availabilityStatus,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    brand,
    category,
    price,
    discountPercentage,
    rating,
    thumbnail,
    images,
    availabilityStatus,
  ];

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      brand: json['brand'] as String? ?? 'No Brand',
      category: json['category'] as String? ?? 'Uncategorized',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] as String? ?? '',
      images: (json['images'] as List?)?.map((e) => e as String).toList() ?? [],
      availabilityStatus: json['availabilityStatus'] as String? ?? 'In Stock',
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      title: title,
      description: description,
      brand: brand,
      category: category,
      price: price,
      discountPercentage: discountPercentage,
      rating: rating,
      thumbnail: thumbnail,
      images: images,
      availabilityStatus: availabilityStatus,
    );
  }
}
