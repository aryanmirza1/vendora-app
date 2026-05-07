import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vendora/models/product_model.dart';
import 'package:vendora/models/order_model.dart' as models;
import 'package:vendora/models/seller_model.dart';
import 'package:vendora/models/admin_model.dart';
import 'package:vendora/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== PRODUCTS ====================

  // Get all approved products for buyers
  Stream<List<Product>> getApprovedProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _productFromDoc(doc)).toList());
  }

  // Get all products (for admin)
  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _productFromDoc(doc)).toList());
  }

  // Get products by seller
  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _productFromDoc(doc)).toList());
  }

  // Get single product
  Future<Product?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (doc.exists) {
      return _productFromDoc(doc);
    }
    return null;
  }

  // Add product
  Future<String> addProduct(Product product) async {
    final docRef = await _firestore.collection('products').add({
      'name': product.name,
      'category': product.category,
      'description': product.description,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'specifications': product.specifications,
      'sellerId': product.sellerId,
      'status': product.status,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('products').doc(docRef.id).update({'id': docRef.id});
    return docRef.id;
  }

  // Update product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _firestore.collection('products').doc(productId).update(data);
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  // Approve/reject product
  Future<void> updateProductStatus(String productId, String status) async {
    await _firestore.collection('products').doc(productId).update({'status': status});
  }

  Product _productFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      specifications: Map<String, String>.from(data['specifications'] ?? {}),
      sellerId: data['sellerId'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }

  // ==================== CARTS ====================

  // Get user cart
  Future<Map<String, int>> getUserCart(String userId) async {
    final doc = await _firestore.collection('carts').doc(userId).get();
    if (doc.exists) {
      return Map<String, int>.from(doc.data()?['items'] ?? {});
    }
    return {};
  }

  // Update user cart
  Future<void> updateUserCart(String userId, Map<String, int> items) async {
    await _firestore.collection('carts').doc(userId).set({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Add to cart
  Future<void> addToCart(String userId, String productId, int quantity) async {
    final cart = await getUserCart(userId);
    cart[productId] = (cart[productId] ?? 0) + quantity;
    await updateUserCart(userId, cart);
  }

  // Remove from cart
  Future<void> removeFromCart(String userId, String productId) async {
    final cart = await getUserCart(userId);
    cart.remove(productId);
    await updateUserCart(userId, cart);
  }

  // Update cart item quantity
  Future<void> updateCartQuantity(String userId, String productId, int quantity) async {
    final cart = await getUserCart(userId);
    if (quantity > 0) {
      cart[productId] = quantity;
    } else {
      cart.remove(productId);
    }
    await updateUserCart(userId, cart);
  }

  // Clear cart
  Future<void> clearCart(String userId) async {
    await _firestore.collection('carts').doc(userId).delete();
  }

  // ==================== ORDERS ====================

  // Create order
  Future<String> createOrder(models.Order order) async {
    final docRef = await _firestore.collection('orders').add({
      'userId': order.userId,
      'items': order.items.map((item) => item.toMap()).toList(),
      'subtotal': order.subtotal,
      'total': order.total,
      'status': order.status,
      'createdAt': order.createdAt.millisecondsSinceEpoch,
      'shippingInfo': order.shippingInfo.toMap(),
      'paymentInfo': order.paymentInfo.toMap(),
    });
    await _firestore.collection('orders').doc(docRef.id).update({'id': docRef.id});
    return docRef.id;
  }

  // Get user orders
  Stream<List<models.Order>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _orderFromDoc(doc)).toList());
  }

  // Get all orders (for admin/seller)
  Stream<List<models.Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _orderFromDoc(doc)).toList());
  }

  // Get orders by seller
  Stream<List<models.Order>> getOrdersBySeller(String sellerId) {
    // Note: This requires getting products first and then orders
    // For simplicity, we'll get all orders and filter by seller's products
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final products = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      final productIds = products.docs.map((doc) => doc.id).toSet();

      final orders = <models.Order>[];
      for (var doc in snapshot.docs) {
        final order = _orderFromDoc(doc);
        final hasSellerProduct = order.items.any((item) => productIds.contains(item.productId));
        if (hasSellerProduct) {
          orders.add(order);
        }
      }
      return orders;
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({'status': status});
  }

  models.Order _orderFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return models.Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => models.OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
      shippingInfo: models.ShippingInfo.fromMap(data['shippingInfo'] as Map<String, dynamic>),
      paymentInfo: models.PaymentInfo.fromMap(data['paymentInfo'] as Map<String, dynamic>),
    );
  }

  // ==================== SELLERS ====================

  // Get all sellers
  Stream<List<Seller>> getAllSellers() {
    return _firestore
        .collection('sellers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _sellerFromDoc(doc)).toList());
  }

  // Get seller by ID
  Future<Seller?> getSeller(String sellerId) async {
    final doc = await _firestore.collection('sellers').doc(sellerId).get();
    if (doc.exists) {
      return _sellerFromDoc(doc);
    }
    return null;
  }

  // Update seller status
  Future<void> updateSellerStatus(String sellerId, String status) async {
    await _firestore.collection('sellers').doc(sellerId).update({'status': status});
  }

  Seller _sellerFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Seller(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      businessCategory: data['businessCategory'] ?? '',
      address: data['address'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      status: data['status'] ?? 'pending',
      totalProducts: data['totalProducts'] ?? 0,
      totalSales: (data['totalSales'] ?? 0).toDouble(),
    );
  }

  // ==================== USERS ====================

  // Get all users (buyers)
  Stream<List<User>> getAllUsers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'buyer')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _userFromDoc(doc)).toList());
  }

  // Get user by ID
  Future<User?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return _userFromDoc(doc);
    }
    return null;
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  User _userFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'],
      role: data['role'] ?? 'buyer',
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // ==================== ADMINS ====================

  // Get all admins
  Stream<List<Admin>> getAllAdmins() {
    return _firestore
        .collection('admins')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _adminFromDoc(doc)).toList());
  }

  // Get admin by ID
  Future<Admin?> getAdmin(String adminId) async {
    final doc = await _firestore.collection('admins').doc(adminId).get();
    if (doc.exists) {
      return _adminFromDoc(doc);
    }
    return null;
  }

  // Delete admin
  Future<void> deleteAdmin(String adminId) async {
    await _firestore.collection('admins').doc(adminId).delete();
  }

  Admin _adminFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Admin(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: '******', // Never expose real password
      role: data['role'] ?? 'admin',
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // ==================== STATISTICS ====================

  // Get dashboard stats for admin
  Future<Map<String, dynamic>> getAdminStats() async {
    final sellers = await _firestore.collection('sellers').get();
    final products = await _firestore.collection('products').get();
    final users = await _firestore.collection('users').where('role', isEqualTo: 'buyer').get();
    final admins = await _firestore.collection('admins').get();

    int pendingProducts = 0;
    int approvedProducts = 0;
    for (var doc in products.docs) {
      final status = doc.data()['status'] as String? ?? 'pending';
      if (status == 'pending') {
        pendingProducts++;
      } else if (status == 'approved') {
        approvedProducts++;
      }
    }

    return {
      'totalSellers': sellers.docs.length,
      'totalProducts': products.docs.length,
      'pendingProducts': pendingProducts,
      'approvedProducts': approvedProducts,
      'totalUsers': users.docs.length,
      'totalAdmins': admins.docs.length,
    };
  }
}
