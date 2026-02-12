import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;

  const Category({required this.id, required this.name, required this.slug});

  // Factory to create from the simple string API response
  factory Category.fromString(String name) {
    return Category(
      id: name, // Using name as ID for this specific API
      name: name.capitalize(),
      slug: name,
    );
  }

  @override
  List<Object?> get props => [id, name, slug];
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
