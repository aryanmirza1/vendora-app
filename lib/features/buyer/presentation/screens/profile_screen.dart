import 'package:flutter/material.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/services/auth_service.dart';
import 'package:vendora/models/user_model.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    debugPrint("ProfileScreen: Loading user data... User: ${user?.uid}");
    
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      debugPrint("ProfileScreen: Data fetched: ${userData?.name}");
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.buyerNotifications);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.cart);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.buyerHome);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.settings);
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isLoggedIn = _currentUser != null;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.3,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // ---------------- PROFILE HEADER ----------------
          if (isLoggedIn)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.black,
                    backgroundImage: _currentUser?.profileImageUrl != null
                        ? NetworkImage(_currentUser!.profileImageUrl!)
                        : null,
                    child: _currentUser?.profileImageUrl == null
                        ? Text(
                            _currentUser?.name.isNotEmpty == true
                                ? _currentUser!.name[0].toUpperCase()
                                : "U",
                            style: const TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.name ?? "",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _currentUser?.email ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  "Please login to view your profile",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 30),

          // ---------------- ACCOUNT SECTION ----------------
          if (isLoggedIn) ...[
            _sectionTitle("Account"),

            _profileTile(
              icon: Icons.person_outline,
              label: "Edit Profile",
              onTap: () => _openEditProfileModal(),
            ),
          ],

          _profileTile(
            icon: Icons.settings_outlined,
            label: "Settings",
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),

          const SizedBox(height: 20),

          // ---------------- SUPPORT SECTION ----------------
          _sectionTitle("Support"),

          _profileTile(
            icon: Icons.help_outline,
            label: "Help Center",
            onTap: () => Navigator.pushNamed(context, AppRoutes.helpCenter),
          ),

          _profileTile(
            icon: Icons.mail_outline,
            label: "Contact Us",
            onTap: () => Navigator.pushNamed(context, AppRoutes.contactUs),
          ),

          _profileTile(
            icon: Icons.report_problem_outlined,
            label: "Report a Problem",
            onTap: () => Navigator.pushNamed(context, AppRoutes.reportProblem),
          ),

          const SizedBox(height: 20),

          // ---------------- SELLER SECTION ----------------
          _sectionTitle("Seller"),

          _profileTile(
            icon: Icons.storefront_outlined,
            label: "Login as Seller",
            subtitle: "Access your seller dashboard",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.login, arguments: "seller");
            },
          ),

          const SizedBox(height: 20),

          // ---------------- LOGIN/LOGOUT SECTION ----------------
          _sectionTitle("Security"),

          if (isLoggedIn)
            _logoutTile(
              icon: Icons.logout,
              label: "Logout",
              onTap: _handleLogout,
            )
          else
            _profileTile(
              icon: Icons.login,
              label: "Login",
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.login, arguments: 'buyer');
              },
            ),

          const SizedBox(height: 30),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 4,
        onTap: _onNavTap,
        role: NavigationRole.buyer,
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  // ==========================================================
  // NORMAL TILE
  // ==========================================================
  Widget _profileTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: Icon(icon, color: Theme.of(context).iconTheme.color),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // ==========================================================
  // LOGOUT TILE
  // ==========================================================
  Widget _logoutTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.red.shade100,
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // ==========================================================
  // EDIT PROFILE MODAL (BOTTOM SHEET)
  // ==========================================================
  void _openEditProfileModal() {
    if (_currentUser == null) return;
    
    final nameCtrl = TextEditingController(text: _currentUser?.name ?? "");
    final emailCtrl = TextEditingController(text: _currentUser?.email ?? "");
    final phoneCtrl = TextEditingController(text: _currentUser?.phone ?? "");
    final addressCtrl = TextEditingController(text: _currentUser?.address ?? "");
    final passCtrl = TextEditingController();

    bool hidePass = true;

    showModalBottomSheet(
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _editField("Name", nameCtrl),
                  const SizedBox(height: 12),

                  _editField("Email", emailCtrl),
                  const SizedBox(height: 12),

                  _editField("Phone Number", phoneCtrl),
                  const SizedBox(height: 12),

                  _editField("Address", addressCtrl),
                  const SizedBox(height: 12),

                  // PASSWORD FIELD WITH TOGGLE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: TextField(
                      controller: passCtrl,
                      obscureText: hidePass,
                      decoration: InputDecoration(
                        hintText: "Password",
                        border: InputBorder.none,
                        suffixIcon: InkWell(
                          onTap: () =>
                              setModal(() => hidePass = !hidePass),
                          child: Icon(
                            hidePass
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SAVE BUTTON
                  GestureDetector(
                    onTap: () async {
                      if (_currentUser == null) return;
                      try {
                        await _authService.updateUserData(_currentUser!.id, {
                          'name': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                        });
                        if (mounted) {
                          await _loadUserData();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating profile: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Reusable modal field
  Widget _editField(String hint, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(40),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }
}
