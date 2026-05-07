import 'package:flutter/material.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/services/auth_service.dart';
import 'package:vendora/services/cart_service.dart';
import 'package:vendora/services/database_service.dart';
import 'package:vendora/models/order_model.dart';
import 'package:vendora/models/user_model.dart';
import 'package:vendora/models/product_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Editable fields
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  String selectedPayment = "";
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  Map<String, int> _cartItems = {};
  Map<String, Product> _products = {};
  double _subtotal = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
        _showLoginDialog();
      }
      return;
    }

    try {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        nameCtrl.text = userData.name;
        phoneCtrl.text = userData.phone;
        addressCtrl.text = userData.address ?? '';
      }

      final cart = await CartService.getCart(user.uid);
      setState(() {
        _cartItems = cart;
      });

      await _loadProducts();

      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    final productIds = _cartItems.keys.toList();
    final products = <String, Product>{};
    double subtotal = 0;

    for (var productId in productIds) {
      try {
        final product = await _db.getProduct(productId);
        if (product != null) {
          products[productId] = product;
          subtotal += product.price * (_cartItems[productId] ?? 1);
        }
      } catch (e) {
        // Product not found, skip
      }
    }

    if (mounted) {
      setState(() {
        _products = products;
        _subtotal = subtotal;
      });
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to proceed to checkout.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.login, arguments: 'buyer');
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.signup, arguments: 'buyer');
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        centerTitle: true,
        title: const Text(
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------
            // SHIPPING INFORMATION
            // ---------------------
            const SizedBox(height: 10),
            const Text(
              "Shipping Information",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            _editableField(nameCtrl),
            const SizedBox(height: 12),
            _editableField(addressCtrl),
            const SizedBox(height: 12),
            _editableField(phoneCtrl),

            const SizedBox(height: 6),

            const SizedBox(height: 6),

            const SizedBox(height: 25),

            // ---------------------
            // PAYMENT SECTION
            // ---------------------
            const Text(
              "Payment Info",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            _paymentOption(
              title: "Debit / Credit Card",
              iconPath: "assets/images/visa.png",
              onTap: () => _openCardModal(),
            ),
            const SizedBox(height: 12),

            _paymentOption(
              title: "JazzCash",
              iconPath: "assets/images/jazzcash.png",
              onTap: () => _openJazzCashModal(),
            ),
            const SizedBox(height: 12),

            _paymentOption(
              title: "Cash on Delivery",
              iconPath: "assets/images/cod.png",
              onTap: () {
                setState(() => selectedPayment = "Cash on Delivery");
              },
            ),

            const SizedBox(height: 30),

            // ---------------------
            // ORDER SUMMARY
            // ---------------------
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            ..._cartItems.entries.map((entry) {
              final product = _products[entry.key];
              if (product == null) return const SizedBox.shrink();
              final quantity = entry.value;
              final total = product.price * quantity;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          Text("Qty ($quantity)",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]))
                        ]),
                    Text("Rs ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),

            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sub Total",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text("Rs ${_subtotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),

            const SizedBox(height: 30),

            // ---------------------
            // PAY BUTTON
            // ---------------------
            GestureDetector(
              onTap: _isLoading ? null : () async {
                if (selectedPayment.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Select a payment method")));
                  return;
                }

                final user = _authService.currentUser;
                if (user == null) {
                  _showLoginDialog();
                  return;
                }

                setState(() {
                  _isLoading = true;
                });

                try {
                  // Create order items
                  final orderItems = _cartItems.entries.map((entry) {
                    final product = _products[entry.key]!;
                    return OrderItem(
                      productId: product.id,
                      productName: product.name,
                      quantity: entry.value,
                      price: product.price,
                    );
                  }).toList();

                  // Create order
                  final order = Order(
                    id: '',
                    userId: user.uid,
                    items: orderItems,
                    subtotal: _subtotal,
                    total: _subtotal,
                    status: 'pending',
                    createdAt: DateTime.now(),
                    shippingInfo: ShippingInfo(
                      name: nameCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                    ),
                    paymentInfo: PaymentInfo(
                      method: selectedPayment,
                      maskedNumber: '****',
                    ),
                  );

                  await _db.createOrder(order);
                  await CartService.clearCart(user.uid);

                  if (mounted) {
                    Navigator.pushNamed(context, AppRoutes.orderComplete);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error placing order: $e')),
                    );
                  }
                }
              },
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : const Center(
                        child: Text(
                          "Pay",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // EDITABLE FIELD UI
  Widget _editableField(TextEditingController c) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none),
      ),
    );
  }

  // PAYMENT OPTION CARD
  Widget _paymentOption({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedPayment == title;

    return InkWell(
      onTap: () {
        setState(() => selectedPayment = title);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 40, height: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // MODAL — CARD PAYMENT
  // -------------------------
  void _openCardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Card Payment",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(decoration: _modalInput("Name on Card")),
              const SizedBox(height: 12),

              TextField(
                  keyboardType: TextInputType.number,
                  decoration: _modalInput("Card Number")),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                    child: TextField(
                        decoration: _modalInput("Expiry (MM/YY)"))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        decoration: _modalInput("CVV"))),
              ]),

              const SizedBox(height: 20),

              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                      child: Text("Save & Continue",
                          style: TextStyle(color: Colors.white))),
                ),
              )
            ]),
          ),
        );
      },
    );
  }

  // -------------------------
  // MODAL — JAZZCASH PAYMENT
  // -------------------------
  void _openJazzCashModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("JazzCash Payment",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(decoration: _modalInput("Full Name")),
              const SizedBox(height: 12),

              TextField(
                  keyboardType: TextInputType.number,
                  decoration:
                  _modalInput("JazzCash Account Number")),
              const SizedBox(height: 12),

              ElevatedButton(
                  onPressed: () {}, child: const Text("Upload Payment Proof")),

              const SizedBox(height: 20),

              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                      child: Text("Save & Continue",
                          style: TextStyle(color: Colors.white))),
                ),
              )
            ]),
          ),
        );
      },
    );
  }

  // DECORATION FOR MODAL FIELDS
  InputDecoration _modalInput(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
