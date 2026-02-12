import 'package:equatable/equatable.dart';

class Product extends Equatable {
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

  const Product({
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

  double get discountedPrice {
    return price - (price * discountPercentage / 100);
  }

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
}
