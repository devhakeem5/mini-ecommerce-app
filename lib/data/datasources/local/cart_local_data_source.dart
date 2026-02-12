abstract class CartLocalDataSource {
  Future<List<Map<String, dynamic>>> loadCart();
  Future<void> saveCart(List<Map<String, dynamic>> items);
  Future<void> clearCart();
}
