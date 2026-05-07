import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/services/database_service.dart';
import 'package:vendora/services/auth_service.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _currentIndex = 2; // Dashboard remains the middle tab (index 2)
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  int _pendingOrders = 0;
  int _confirmedOrders = 0;
  int _approvedProducts = 0;
  int _pendingProducts = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
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
      // Load products
      final products = await _db.getProductsBySeller(user.uid).first;
      int approved = 0, pending = 0;
      for (var product in products) {
        if (product.status == 'approved') {
          approved++;
        } else if (product.status == 'pending') {
          pending++;
        }
      }

      // Load orders (simplified - would need proper implementation)
      // For now, we'll set default values
      
      if (mounted) {
        setState(() {
          _approvedProducts = approved;
          _pendingProducts = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.sellerOrders);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.manageProducts);
        break;
      case 2:
      // Already on dashboard - do nothing or pushNamed if coming from another screen
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.manageCategories);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... Welcome Badge and Title ...

              const SizedBox(height: 28),

              // ------------------ Cards ------------------
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        SellerDashboardCard(
                          title: "Orders",
                          line1: "Pending ($_pendingOrders)",
                          line2: "Confirmed ($_confirmedOrders)",
                          icon: "assets/images/orders.png",
                          onTap: () => Navigator.pushNamed(context, AppRoutes.sellerOrders),
                        ),
                        const SizedBox(height: 18),
                        SellerDashboardCard(
                          title: "Products",
                          line1: "Approved ($_approvedProducts)",
                          line2: "Pending ($_pendingProducts)",
                          icon: "assets/images/products.png",
                          onTap: () => Navigator.pushNamed(context, AppRoutes.manageProducts),
                        ),
                        const SizedBox(height: 18),
                        SellerDashboardCard(
                          title: "Categories",
                          line1: "Manage Categories",
                          line2: "",
                          icon: "assets/images/categories.png",
                          onTap: () => Navigator.pushNamed(context, AppRoutes.manageCategories),
                        ),
                        const SizedBox(height: 18),
                        SellerDashboardCard(
                          title: "Sales",
                          line1: "View Sales",
                          line2: "",
                          icon: "assets/images/sales.png",
                          onTap: () => Navigator.pushNamed(context, AppRoutes.sales),
                        ),
                        const SizedBox(height: 18),
                        SellerDashboardCard(
                          title: "Stats",
                          line1: "View Stats",
                          line2: "",
                          icon: "assets/images/stats.png",
                          onTap: () => Navigator.pushNamed(context, AppRoutes.stats),
                        ),
                      ],
                    ),


              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        role: NavigationRole.seller,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REUSABLE SELLER DASHBOARD CARD
// -----------------------------------------------------------------------------
class SellerDashboardCard extends StatelessWidget {
  final String title;
  final String line1;
  final String line2;
  final String icon;
  final VoidCallback onTap;

  const SellerDashboardCard({
    required this.title,
    required this.line1,
    required this.line2,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // ------ TEXT ------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line1,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.80),
                      ),
                    ),
                    if (line2.isNotEmpty)
                      Text(
                        line2,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.80),
                        ),
                      ),
                  ],
                ),
              ),

              // ------ ICON ------
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(icon, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
