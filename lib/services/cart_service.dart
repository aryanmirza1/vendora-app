import 'package:vendora/models/product_model.dart';
import 'package:vendora/services/database_service.dart';

class CartService {
  static final DatabaseService _db = DatabaseService();

  static Future<void> addToCart(String userId, Product product, int qty) async {
    await _db.addToCart(userId, product.id, qty);
  }

  static Future<void> removeItem(String userId, String productId) async {
    await _db.removeFromCart(userId, productId);
  }

  static Future<void> updateQty(String userId, String productId, int qty) async {
    await _db.updateCartQuantity(userId, productId, qty);
  }

  static Future<Map<String, int>> getCart(String userId) async {
    return await _db.getUserCart(userId);
  }

  static Future<void> clearCart(String userId) async {
    await _db.clearCart(userId);
  }
}
