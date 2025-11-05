import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Add provider import

import '../api/api_service.dart';
import '../screens/view_detail_screen.dart';
import '../screens/category_screen.dart';
import '../screens/news_screen.dart';
import '../screens/search_screen.dart';
import '../screens/login_screen.dart'; // Import LoginScreen
import '../screens/profile_screen.dart'; // Import ProfileScreen

const kBorderColorDark = Color(0xFFF57D2C);
const kBorderColorLight = Color(0xFFF9B234);

// ============== MAIN HOME SCREEN (UNCHANGED) ==============
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      // AppDrawer ถูกเปลี่ยนเป็น StatefulWidget เพื่อใช้ Consumer
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          const SliverPersistentHeader(
            delegate: CustomSliverAppBarDelegate(),
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 30),
                const FeaturedSection(),
                const SizedBox(height: 24),
                const ApiContentSection(
                  title: 'ที่เที่ยว',
                  categoryId: 3,
                ),
                const ApiContentSection(
                  title: 'ร้านอาหารเด็ด',
                  categoryId: 4,
                  hasDropdown: true,
                ),
                const ApiContentSection(
                  title: 'คาเฟ่น่านั่ง',
                  categoryId: 6,
                  hasDropdown: true,
                ),
                const ApiContentSection(
                  title: 'ที่พักแนะนำ',
                  categoryId: 5,
                  hasDropdown: true,
                ),
                const ApiContentSection(
                  title: 'สินค้า OTOP',
                  categoryId: 7,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== NAVIGATION DRAWER WIDGET (UPDATED to Stateful) ==============
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          final isLoggedIn = authService.isLoggedIn;
          final user = authService.currentUser;

          return Column(
            children: <Widget>[
              // Custom Drawer Header
              _buildDrawerHeader(context, isLoggedIn, user),

              // Scrollable list of categories and main items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // --- Profile or Login Link (Conditional) ---
                    if (isLoggedIn)
                      ListTile(
                        leading: const Icon(Icons.person, color: kBorderColorDark),
                        title: const Text('ดูข้อมูลส่วนตัว'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.login, color: kBorderColorDark),
                        title: const Text('เข้าสู่ระบบ'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                      ),
                      
                    const Divider(height: 1),

                    // --- Category List ---
                    ...categories.map((category) {
                      return ListTile(
                        leading: Icon(category.icon, color: category.color),
                        title: Text(category.label),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryScreen(
                                categoryName: category.label,
                                categoryId: category.id,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    // END Category List
                  ],
                ),
              ),

              // --- Logout Button (NEW: Always at the bottom) ---
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        onTap: () async {
                          // Show confirmation dialog before logging out
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('ยืนยันการออกจากระบบ'),
                              content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('ยืนยัน', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await authService.logout();
                            if (mounted) {
                              Navigator.pop(context); // Close the drawer
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ออกจากระบบเรียบร้อยแล้ว')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, bool isLoggedIn, User? user) {
    return UserAccountsDrawerHeader(
      accountName: Text(
        isLoggedIn ? (user?.displayName ?? 'สมาชิก') : 'ผู้เยี่ยมชม',
        style: GoogleFonts.sriracha(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
              blurRadius: 2.0,
              color: Colors.black45,
              offset: Offset(0.5, 0.5),
            ),
          ],
        ),
      ),
      accountEmail: Text(
        isLoggedIn ? (user?.email ?? '') : 'กรุณาเข้าสู่ระบบ',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: isLoggedIn
            ? Text(
                user!.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : (user.nicename.isNotEmpty ? user.nicename[0].toUpperCase() : 'U'),
                style: GoogleFonts.sriracha(fontSize: 40, color: kBorderColorDark),
              )
            : const Icon(
                Icons.person_outline,
                size: 40,
                color: kBorderColorDark,
              ),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kBorderColorDark, kBorderColorLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      onDetailsPressed: isLoggedIn
          ? () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }
          : null,
    );
  }
}


// ============== HEADER SECTION (REST OF FILE UNCHANGED) ==============
class CustomSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  const CustomSliverAppBarDelegate();

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFFF8F0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 10),
            child: ClipPath(
              clipper: MainHeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kBorderColorDark, kBorderColorLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, 5),
            child: ClipPath(
              clipper: MainHeaderClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kBorderColorLight,
                      kBorderColorLight.withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          ClipPath(
            clipper: MainHeaderClipper(),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/header.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 45,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      Text(
                        'เที่ยวยโส !',
                        style: GoogleFonts.sriracha(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              blurRadius: 10.0,
                              color: Colors.black45,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      // Add a spacer to balance the row and keep the title centered
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SearchBarWidget(),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              transform: Matrix4.translationValues(0.0, 25.0, 0.0),
              child: const CategoryIcons(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 280.0;
  @override
  double get minExtent => 250.0;
  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}

class MainHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.cubicTo(size.width * 0.25, size.height * 0.6, size.width * 0.75,
        size.height * 0.9, size.width, size.height * 0.75);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.trim().isNotEmpty) {
      // Navigate to a new search results screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(searchQuery: query.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Color(0xFFF57D2C)),
          hintText: 'ค้นหาที่เที่ยว ที่กิน ที่พัก ของฝาก..',
          border: InputBorder.none,
        ),
        onSubmitted: _handleSearch,
      ),
    );
  }
}

// Data model for a category (UNCHANGED)
class Category {
  final String label;
  final IconData icon;
  final Color color;
  final int id;

  const Category({
    required this.label,
    required this.icon,
    required this.color,
    required this.id,
  });
}

// List of categories (UNCHANGED)
const List<Category> categories = [
  Category(label: 'ที่เที่ยว', icon: Icons.account_balance, color: Color(0xFFF47B72), id: 3),
  Category(label: 'ร้านอาหารเด็ด', icon: Icons.restaurant, color: Color(0xFF78E08F), id: 4),
  Category(label: 'คาเฟ่น่านั่ง', icon: Icons.coffee, color: Color(0xFF74B9FF), id: 6),
  Category(label: 'ที่พักแนะนำ', icon: Icons.hotel, color: Color(0xFF9B59B6), id: 5),
  Category(label: 'สินค้า OTOP', icon: Icons.shopping_bag, color: Color.fromARGB(255, 236, 153, 83), id: 7),
];

class CategoryIcons extends StatelessWidget {
  const CategoryIcons({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: categories.map((category) {
          return CategoryIcon(
            icon: category.icon,
            label: category.label,
            color: category.color,
            categoryId: category.id,
          );
        }).toList(),
      ),
    );
  }
}


class CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int categoryId;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              categoryName: label,
              categoryId: categoryId,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ============== FEATURED SECTION (UNCHANGED) ==============
class FeaturedSection extends StatefulWidget {
  const FeaturedSection({super.key});

  @override
  State<FeaturedSection> createState() => _FeaturedSectionState();
}

class _FeaturedSectionState extends State<FeaturedSection> {
  late Future<List<Post>> futurePosts;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    futurePosts = apiService.fetchFeaturedPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ห้ามพลาด',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewsScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('ดูเพิ่ม'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Post>>(
          future: futurePosts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator())
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.3,
                  enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: snapshot.data!.map((post) {
                  return Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewDetailScreen(postId: post.id),
                            ),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: post.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[300]),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Text(
                                      post.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            } else {
               return const Text('No posts found.');
            }
          },
        ),
      ],
    );
  }
}

// ============== API CONTENT SECTION (UNCHANGED) ==============
class ApiContentSection extends StatefulWidget {
  final String title;
  final int categoryId;
  final bool hasDropdown;

  const ApiContentSection({
    super.key,
    required this.title,
    required this.categoryId,
    this.hasDropdown = false,
  });

  @override
  State<ApiContentSection> createState() => _ApiContentSectionState();
}

class _ApiContentSectionState extends State<ApiContentSection> {
  final ApiService apiService = ApiService();
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  List<String> _districts = ['ทั้งหมด'];
  String _selectedDistrict = 'ทั้งหมด';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final posts = await apiService.fetchPostsByCategory(widget.categoryId, perPage: 100);
      final uniqueDistricts = <String>{};
      for (var post in posts) {
        if (post.district != null && post.district!.isNotEmpty) {
          uniqueDistricts.add(post.district!);
        }
      }

      if (mounted) {
        setState(() {
          _allPosts = posts;
          _filteredPosts = posts;
          _districts = ['ทั้งหมด', ...uniqueDistricts.toList()..sort()];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Failed to load posts for category ${widget.categoryId}: $e');
    }
  }

  void _filterByDistrict(String? newDistrict) {
    if (newDistrict == null) return;

    setState(() {
      _selectedDistrict = newDistrict;
      if (newDistrict == 'ทั้งหมด') {
        _filteredPosts = _allPosts;
      } else {
        _filteredPosts = _allPosts.where((post) => post.district == newDistrict).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              widget.hasDropdown
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDistrict,
                          items: _districts.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: _filterByDistrict,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryScreen(
                              categoryName: widget.title,
                              categoryId: widget.categoryId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('ดูเพิ่ม'),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPosts.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filteredPosts.length,
                      padding: const EdgeInsets.only(left: 16),
                      itemBuilder: (context, index) {
                        return ApiPlaceCard(post: _filteredPosts[index]);
                      },
                    )
                  : const Center(child: Text('ไม่พบข้อมูลในอำเภอนี้')),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ============== API PLACE CARD (UNCHANGED) ==============
class ApiPlaceCard extends StatelessWidget {
  final Post post;

  const ApiPlaceCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
       onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewDetailScreen(postId: post.id),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
