import 'package:flutter/material.dart';
import 'package:vendora/core/widgets/bottom_navigation_bar.dart';
import 'package:vendora/core/routes/app_routes.dart';
import 'package:vendora/models/demo_data.dart';
import 'package:vendora/models/product_model.dart';
import 'package:vendora/services/database_service.dart';
import 'package:vendora/services/auth_service.dart';
import 'package:vendora/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "All Items";
  String searchQuery = "";
  int _currentIndex = 2;
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  User? _currentUser;

  // Sorting mode
  String sortMode = "none";

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
    debugPrint("HomeScreen: Loading user data... Current User ID: ${user?.uid}");
    
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      debugPrint("HomeScreen: User data fetched: ${userData?.name}");
      
      if (mounted) {
        setState(() {
          _currentUser = userData;
        });
      }
    } else {
      debugPrint("HomeScreen: No logged in user.");
      if (mounted) {
        setState(() {
          _currentUser = null;
        });
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamed(context, AppRoutes.buyerNotifications);
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.cart);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.settings);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sort By",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _filterOption("Price: Low → High", "low_high"),
              _filterOption("Price: High → Low", "high_low"),
              _filterOption("Newest First", "newest"),
              _filterOption("Oldest First", "oldest"),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() => sortMode = "none");
                  Navigator.pop(context);
                },
                child: const Text("Clear Filters"),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _filterOption(String label, String mode) {
    return ListTile(
      title: Text(label),
      trailing:
      sortMode == mode ? const Icon(Icons.check, color: Colors.black) : null,
      onTap: () {
        setState(() => sortMode = mode);
        Navigator.pop(context);
      },
    );
  }

  List<Product> _applySorting(List<Product> list) {
    switch (sortMode) {
      case "low_high":
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case "high_low":
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case "newest":
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case "oldest":
        list.sort((a, b) => a.id.compareTo(b.id));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categoryTabs = categories;
    final theme = Theme.of(context); // Cached for cleaner code

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        role: NavigationRole.buyer,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),

                // HEADER
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentUser != null) ...[
                          Text(
                            "Hello, Welcome 👋",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.name,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ] else ...[
                          Text(
                            "Hello, Guest 👋",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Welcome to Vendora",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    if (_currentUser != null)
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: _currentUser!.profileImageUrl != null
                            ? NetworkImage(_currentUser!.profileImageUrl!)
                            : const AssetImage("assets/images/profile.png") as ImageProvider,
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.person_outline, color: theme.iconTheme.color),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.login, arguments: 'buyer');
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 25),

                // SEARCH + FILTER
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() => searchQuery = value);
                          },
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.hintColor,
                              size: 22,
                            ),
                            hintText: "Search clothes...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // FILTER BUTTON
                    GestureDetector(
                      onTap: _openFilterSheet,
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // CATEGORY TABS
                SizedBox(
                  height: 45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final cat = categoryTabs[index];
                      final isSelected = selectedCategory == cat;

                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedCategory = cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // PRODUCT GRID
                StreamBuilder<List<Product>>(
                  stream: _db.getApprovedProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            Icon(Icons.inventory_2_outlined, size: 60, color: theme.disabledColor),
                            const SizedBox(height: 10),
                            Text(
                              'No products available',
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      );
                    }

                    List<Product> products = snapshot.data!;

                    List<Product> filtered = products.where((p) {
                      final matchesCategory =
                          selectedCategory == "All Items" || p.category == selectedCategory;
                      final matchesSearch = searchQuery.isEmpty
                          ? true
                          : p.name.toLowerCase().contains(searchQuery.toLowerCase());
                      return matchesCategory && matchesSearch;
                    }).toList();

                    filtered = _applySorting(filtered);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.56,
                      ),
                      itemBuilder: (context, index) {
                        final product = filtered[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.productDetails,
                              arguments: product,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // IMAGE
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: product.imageUrl.startsWith('http')
                                      ? CachedNetworkImage(
                                    imageUrl: product.imageUrl,
                                    height: 210,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 210,
                                      color: Colors.grey.shade200,
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      height: 210,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.error),
                                    ),
                                  )
                                      : Image.asset(
                                    product.imageUrl,
                                    height: 210,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 210,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.error),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  product.name,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),

                                Text(
                                  product.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Text(
                                      product.formattedPrice,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 14),
                                    Text(
                                      product.rating.toString(),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodyMedium?.color
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}