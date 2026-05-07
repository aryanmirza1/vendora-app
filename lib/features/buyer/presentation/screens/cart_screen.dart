import 'package:flutter/material.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/models/product_model.dart';
import 'package:vendora/services/cart_service.dart';
import 'package:vendora/services/database_service.dart';
import 'package:vendora/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  Map<String, int> _cartItems = {};
  Map<String, Product> _products = {};
  bool _isLoading = true;

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final cart = await CartService.getCart(user.uid);
      if (mounted) {
        setState(() {
          _cartItems = cart;
        });
        await _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cart: $e')),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final productIds = _cartItems.keys.toList();
    final products = <String, Product>{};

    for (var productId in productIds) {
      try {
        final product = await _db.getProduct(productId);
        if (product != null) {
          products[productId] = product;
        }
      } catch (e) {
        // Product not found, skip
      }
    }

    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.buyerNotifications);
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.settings);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  double _calculateTotal() {
    double total = 0;
    _cartItems.forEach((id, qty) {
      final product = _products[id];
      if (product != null) {
        total += product.price * qty;
      }
    });
    return total;
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      if (newQuantity > 0) {
        await CartService.updateQty(user.uid, productId, newQuantity);
        setState(() {
          _cartItems[productId] = newQuantity;
        });
      } else {
        await CartService.removeItem(user.uid, productId);
        setState(() {
          _cartItems.remove(productId);
          _products.remove(productId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating cart: $e')),
      );
    }
  }

  Future<void> _removeItem(String productId) async {
    await _updateQuantity(productId, 0);
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "My Cart",
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final productId = _cartItems.keys.elementAt(index);
                final product = _products[productId];
                if (product == null) {
                  return const SizedBox.shrink();
                }
                final quantity = _cartItems[productId] ?? 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: product.imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error),
                                ),
                              )
                            : Image.asset(
                                product.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(height: 3),
                            Text(product.category,
                                style: TextStyle(
                                    fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                            const SizedBox(height: 6),
                            Text(
                              product.formattedPrice,
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _removeItem(product.id),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              _qtyButton(Icons.remove, () {
                                _updateQuantity(product.id, quantity - 1);
                              }),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  "$quantity",
                                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                                ),
                              ),
                              _qtyButton(Icons.add, () {
                                _updateQuantity(product.id, quantity + 1);
                              }),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _priceRow("Total (${_cartItems.length} items)", total),
                _priceRow("Shipping Fee", 0),
                _priceRow("Discount", 0),
                const Divider(height: 24, thickness: 1),

                _priceRow("Sub Total", total, bold: true),
                const SizedBox(height: 16),

                // PROCEED BUTTON (FIGMA STYLE)
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: _cartItems.isEmpty
                          ? null
                          : () => Navigator.pushNamed(context, AppRoutes.checkout),
                      child: Center(
                        child: Text(
                          "Proceed to Checkout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _cartItems.isEmpty ? Colors.grey : Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        showNotifications: true,
        role: NavigationRole.buyer,
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              )),
          Text(
            "Rs ${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}
