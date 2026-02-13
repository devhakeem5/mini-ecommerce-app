abstract class CartLocalDataSource {
  Future<List<Map<String, dynamic>>> loadCart();
  Future<void> saveCart(
    List<Map<String, dynamic>> items,
  ); // Kept for generic save if needed, or deprecated
  Future<void> saveCartItem(Map<String, dynamic> item);
  Future<void> removeCartItem(int productId);
  Future<void> clearCart();
}
