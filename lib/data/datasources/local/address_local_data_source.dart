abstract class AddressLocalDataSource {
  Future<List<Map<String, dynamic>>> getAddresses();
  Future<void> saveAddresses(List<Map<String, dynamic>> addresses);
  Future<void> seedDefaultAddresses();
}
