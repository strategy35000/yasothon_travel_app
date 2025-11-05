import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../api/api_service.dart';
import 'view_detail_screen.dart'; // Import detail screen for navigation

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ApiService apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // State variables for pagination
  List<Post> _newsItems = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInitialNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // If we've scrolled to the end of the list, load more data
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreNews();
    }
  }

  Future<void> _fetchInitialNews() async {
    try {
      final news = await apiService.fetchPostsByCategory(13, page: 1); // Always fetch page 1
      setState(() {
        _newsItems = news;
        _isLoading = false;
        _hasMore = news.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
  
  // ADDED: Function to handle pull-to-refresh
  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
      _newsItems = [];
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
    });
    await _fetchInitialNews();
  }


  Future<void> _fetchMoreNews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    try {
      final newNews = await apiService.fetchPostsByCategory(13, page: _currentPage);
      setState(() {
        if (newNews.isEmpty) {
          _hasMore = false;
        }
        _newsItems.addAll(newNews);
        _isLoadingMore = false;
      });
    } catch (e) {
       setState(() {
        _isLoadingMore = false;
        // Optionally handle error for subsequent loads
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'ข่าวสารท่องเที่ยว',
          style: GoogleFonts.sarabun(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF9772B), Color(0xFFF55B2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }
    if (_errorMessage != null) {
      return Center(
        child: Text('เกิดข้อผิดพลาด: $_errorMessage'),
      );
    }
    if (_newsItems.isEmpty) {
      return const Center(
        child: Text('ไม่พบข่าวสารในขณะนี้'),
      );
    }
    
    // MODIFIED: Wrapped ListView with RefreshIndicator
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFFF55B2E),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _newsItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _newsItems.length) {
            // Show a loader at the end of the list
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          final newsItem = _newsItems[index];
          return NewsCard(newsItem: newsItem);
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: 5, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.4,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// MODIFIED: Converted to StatefulWidget for hover effect
class NewsCard extends StatefulWidget {
  final Post newsItem;

  const NewsCard({super.key, required this.newsItem});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _isHovering 
                    ? Colors.black.withOpacity(0.15) 
                    : Colors.black.withOpacity(0.08),
                blurRadius: _isHovering ? 15 : 10,
                offset: _isHovering ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewDetailScreen(postId: widget.newsItem.id)
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.newsItem.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 50)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.newsItem.title,
                          style: GoogleFonts.sarabun(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              widget.newsItem.date, // This will now show Buddhist Era year
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                            const Spacer(),
                            Icon(Icons.visibility_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.newsItem.postViews} ครั้ง',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
