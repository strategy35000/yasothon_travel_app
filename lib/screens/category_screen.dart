import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../api/api_service.dart';
import 'view_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final int categoryId;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  List<String> _districts = ['ทั้งหมด'];
  String _selectedDistrict = 'ทั้งหมด';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_runFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_runFilter);
    _searchController.dispose();
    super.dispose();
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

  void _runFilter() {
    List<Post> results = _allPosts;
    final searchQuery = _searchController.text.toLowerCase();

    // Filter by district first
    if (_selectedDistrict != 'ทั้งหมด') {
      results = results.where((post) => post.district == _selectedDistrict).toList();
    }

    // Then filter by search query
    if (searchQuery.isNotEmpty) {
      results = results.where((post) {
        return post.title.toLowerCase().contains(searchQuery);
      }).toList();
    }

    setState(() {
      _filteredPosts = results;
    });
  }

  void _onDistrictChanged(String? newDistrict) {
    if (newDistrict == null) return;
    setState(() {
      _selectedDistrict = newDistrict;
    });
    _runFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              widget.categoryName,
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFF57D2C),
            floating: true,
            pinned: true,
            snap: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _buildSearchBar()),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _buildDistrictFilter()),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? _buildLoadingGrid()
                : _filteredPosts.isNotEmpty
                    ? _buildPostsGrid(_filteredPosts)
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('ไม่พบข้อมูล'),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ค้นหา...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFF57D2C)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }
  
  Widget _buildDistrictFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedDistrict,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFF57D2C)),
          items: _districts.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _onDistrictChanged,
        ),
      ),
    );
  }

  Widget _buildPostsGrid(List<Post> posts) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 3 / 4.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      padding: const EdgeInsets.all(16.0),
      itemCount: posts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return PlaceCard(post: posts[index]);
      },
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 3 / 4.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      padding: const EdgeInsets.all(16.0),
      itemCount: 6, // Number of shimmer placeholders
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
            ),
          ),
        );
      },
    );
  }
}

class PlaceCard extends StatelessWidget {
  final Post post;
  const PlaceCard({super.key, required this.post});

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
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${post.postViews}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                post.title,
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

