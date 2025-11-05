import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../api/api_service.dart';
import 'view_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String searchQuery;

  const SearchScreen({super.key, required this.searchQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Post> _searchResults = [];
  bool _isLoading = true;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.searchQuery;
    _searchController.text = _currentQuery;
    _fetchSearchResults();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSearchResults() async {
    if (_currentQuery.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final results = await apiService.searchPosts(_currentQuery, perPage: 50);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      debugPrint('Failed to search posts: $e');
      // Optionally show an error message to the user
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty && query.trim() != _currentQuery) {
      setState(() {
        _currentQuery = query.trim();
      });
      _fetchSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false, // Set to false to prevent keyboard popping up immediately
          decoration: const InputDecoration(
            hintText: 'ค้นหาอีกครั้ง...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onSubmitted: _onSearchSubmitted,
        ),
        backgroundColor: const Color(0xFFF57D2C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'ไม่พบผลลัพธ์สำหรับคำค้นหา:\n"$_currentQuery"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }
    return _buildResultsList(_searchResults);
  }
  
  // Using a ListView for search results as it's more standard
  Widget _buildResultsList(List<Post> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return SearchResultCard(post: posts[index]);
      },
    );
  }
  
  // A shimmer loading effect for the list view
  Widget _buildLoadingGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 8, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(height: 20, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 16, width: MediaQuery.of(context).size.width * 0.4, color: Colors.white),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// A new card widget for search results for better layout
class SearchResultCard extends StatelessWidget {
  final Post post;
  const SearchResultCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDetailScreen(postId: post.id),
            ),
          );
        },
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CachedNetworkImage(
                imageUrl: post.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      post.title,
                      style: GoogleFonts.kanit(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (post.district != null && post.district!.isNotEmpty)
                      Text(
                        post.district!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
