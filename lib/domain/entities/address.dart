class Address {
  final String id;
  final String label;
  final String city;
  final String street;
  final String details;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.city,
    required this.street,
    this.details = '',
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city${details.isNotEmpty ? ' - $details' : ''}';

  Address copyWith({
    String? id,
    String? label,
    String? city,
    String? street,
    String? details,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      city: city ?? this.city,
      street: street ?? this.street,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
