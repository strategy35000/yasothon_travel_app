import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart';
import 'view_detail_screen.dart'; // Added for navigation

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final Geodesy _geodesy = Geodesy();
  final ScrollController _scrollController = ScrollController(); // For pagination

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  bool _isCardView = true; // State for view mode toggle

  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  List<String> _districts = ['ทุกอำเภอ'];
  String _selectedDistrict = 'ทุกอำเภอ';

  // Pagination state
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _searchController.addListener(_filterPosts);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPosts);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // If we've scrolled to the end of the list, load more data
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreData();
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _allPosts = [];
      _filteredPosts = [];
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      _currentPosition = await _getCurrentPosition();
      if (_currentPosition == null) {
        throw Exception('ไม่สามารถเข้าถึงตำแหน่งปัจจุบันได้');
      }

      final posts = await _apiService.fetchAllNearbyPosts(page: _currentPage);
      final validLocationPosts = posts
          .where((post) => post.latitude != null && post.longitude != null)
          .toList();

      for (var post in validLocationPosts) {
        post.distanceInKm = _geodesy.distanceBetweenTwoGeoPoints(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              LatLng(post.latitude!, post.longitude!),
            ) /
            1000;
      }
      
      // District filter is populated only once on initial load
      final uniqueDistricts = validLocationPosts
          .map((p) => p.district)
          .whereType<String>()
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList();
      uniqueDistricts.sort();

      setState(() {
        _allPosts = validLocationPosts;
        // Sort the entire list by distance
        _allPosts.sort((a, b) => a.distanceInKm!.compareTo(b.distanceInKm!));
        _filteredPosts = _allPosts;
        _districts = ['ทุกอำเภอ', ...uniqueDistricts];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchMoreData() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    final newPosts = await _apiService.fetchAllNearbyPosts(page: _currentPage);

    if (newPosts.isEmpty) {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
      return;
    }
    
    final newValidLocationPosts = newPosts
        .where((post) => post.latitude != null && post.longitude != null)
        .toList();

    for (var post in newValidLocationPosts) {
      post.distanceInKm = _geodesy.distanceBetweenTwoGeoPoints(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            LatLng(post.latitude!, post.longitude!),
          ) /
          1000;
    }

    setState(() {
      _allPosts.addAll(newValidLocationPosts);
      // Re-sort the entire list every time new data comes in
      _allPosts.sort((a, b) => a.distanceInKm!.compareTo(b.distanceInKm!));
      _filterPosts(); // Re-apply current filters
      _isLoadingMore = false;
    });
  }


  void _filterPosts() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        final titleMatches = post.title.toLowerCase().contains(searchQuery);
        final districtMatches =
            _selectedDistrict == 'ทุกอำเภอ' || post.district == _selectedDistrict;
        return titleMatches && districtMatches;
      }).toList();
    });
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาเปิด GPS เพื่อใช้งานฟังก์ชันนี้')));
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('การเข้าถึงตำแหน่งถูกปฏิเสธ')));
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('การเข้าถึงตำแหน่งถูกปฏิเสธถาวร, ไม่สามารถร้องขอได้')));
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }
  
  IconData _getCategoryIcon(List<int> categoryIds) {
    if (categoryIds.isEmpty) return Icons.place_outlined;
    final primaryCategoryId = categoryIds.first;
    switch (primaryCategoryId) {
      case 3: return Icons.account_balance_outlined;
      case 4: return Icons.restaurant_outlined;
      case 5: return Icons.hotel_outlined;
      case 6: return Icons.coffee_outlined;
      case 7: return Icons.shopping_bag_outlined;
      default: return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สถานที่ใกล้ฉัน',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหาสถานที่...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    icon: const Icon(Icons.filter_list, color: Colors.grey),
                    items: _districts.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDistrict = newValue!;
                      });
                      _filterPosts();
                    },
                  ),
                ),
              ),
              const Spacer(),
              ToggleButtons(
                isSelected: [_isCardView, !_isCardView],
                onPressed: (index) {
                  setState(() {
                    _isCardView = index == 0;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                selectedColor: Colors.white,
                fillColor: Colors.teal,
                color: Colors.teal,
                constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
                children: const [
                  Icon(Icons.view_module),
                  Icon(Icons.view_list),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('เกิดข้อผิดพลาด: $_errorMessage', textAlign: TextAlign.center),
        ),
      );
    }
    if (_filteredPosts.isEmpty && !_isLoadingMore) {
      return const Center(child: Text('ไม่พบสถานที่ที่ตรงกับเงื่อนไข'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPosts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredPosts.length) {
          return _isLoadingMore
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ))
              : const SizedBox.shrink();
        }
        final post = _filteredPosts[index];
        return _isCardView ? _buildLocationCard(post) : _buildLocationListItem(post);
      },
    );
  }

  Widget _buildLocationCard(Post post) {
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
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: FadeInImage.assetNetwork(
                placeholder:
                    'assets/images/placeholder.png',
                image: post.imageUrl,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/images/placeholder.png',
                      fit: BoxFit.cover);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.district ?? 'ไม่ระบุอำเภอ',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${post.distanceInKm?.toStringAsFixed(1) ?? 'N/A'} กม.',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationListItem(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16), // Use bottom margin for consistency
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDetailScreen(postId: post.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getCategoryIcon(post.categoryIds), color: Colors.teal, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.district ?? 'ไม่ระบุอำเภอ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    post.distanceInKm?.toStringAsFixed(1) ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    'กม.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

