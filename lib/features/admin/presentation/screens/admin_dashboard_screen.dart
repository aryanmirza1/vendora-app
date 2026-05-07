import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/features/admin/presentation/screens/manage_sellers_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_products_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_users_screen.dart';
import 'package:vendora/features/admin/presentation/screens/manage_admins_screen.dart';
import 'package:vendora/services/database_service.dart';
import 'package:vendora/services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await _db.getAdminStats();
      final user = _authService.currentUser;
      if (user != null) {
        // Try to get admin name from users collection
        final userData = await _authService.getUserData(user.uid);
        if (userData != null) {
          _adminName = userData.name;
        }
      }
      if (mounted) {
        setState(() {
          _stats = stats;
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
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Welcome Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text(
                    'Welcome Back, $_adminName 👋',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Dashboard Cards
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _DashboardCard(
                          title: 'Vendors',
                          subtitle: 'Registered (${_stats['totalSellers'] ?? 0})',
                          icon: Icons.person_outline,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageSellersScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _DashboardCard(
                          title: 'Products',
                          subtitle: 'Approved (${_stats['approvedProducts'] ?? 0})\nPending (${_stats['pendingProducts'] ?? 0})',
                          icon: Icons.inventory_2,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _DashboardCard(
                          title: 'Users',
                          subtitle: 'Registered (${_stats['totalUsers'] ?? 0})',
                          icon: Icons.people_outline,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _DashboardCard(
                          title: 'Admins',
                          subtitle: 'Registered (${_stats['totalAdmins'] ?? 0})',
                          icon: Icons.admin_panel_settings,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ManageAdminsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        role: NavigationRole.admin,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[800],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                icon,
                color: Colors.grey[300],
                size: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
