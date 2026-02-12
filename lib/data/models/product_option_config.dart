class ProductOptionConfig {
  final String label;
  final List<String> values;
  final List<double> priceModifiers;

  ProductOptionConfig({required this.label, required this.values, this.priceModifiers = const []});
}
