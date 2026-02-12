import '../../domain/entities/address.dart';

class AddressModel {
  final String id;
  final String label;
  final String city;
  final String street;
  final String details;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.city,
    required this.street,
    this.details = '',
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      label: json['label'] as String,
      city: json['city'] as String,
      street: json['street'] as String,
      details: json['details'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'city': city,
      'street': street,
      'details': details,
      'isDefault': isDefault,
    };
  }

  Address toEntity() {
    return Address(
      id: id,
      label: label,
      city: city,
      street: street,
      details: details,
      isDefault: isDefault,
    );
  }

  factory AddressModel.fromEntity(Address address) {
    return AddressModel(
      id: address.id,
      label: address.label,
      city: address.city,
      street: address.street,
      details: address.details,
      isDefault: address.isDefault,
    );
  }
}
