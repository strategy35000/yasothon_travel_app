// ignore_for_file: depend_on_referenced_packages, unused_element

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart'; // NEW: Import Provider
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../api/api_service.dart';

class ViewDetailScreen extends StatefulWidget {
  final int postId;

  const ViewDetailScreen({super.key, required this.postId});

  @override
  State<ViewDetailScreen> createState() => _ViewDetailScreenState();
}

class _ViewDetailScreenState extends State<ViewDetailScreen> {
  late Future<Post> futurePost;
  late Future<List<Comment>> futureComments; // NEW: Future for comments
  final ApiService apiService = ApiService();

  // NEW: State for comment input
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  
  // Removed PageController as Gallery is now Horizontal ListView/SingleChildScrollView based, not PageView
  // int _currentImageIndex = 0;
  // final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    futurePost = apiService.fetchPostDetails(widget.postId);
    futureComments = apiService.fetchComments(widget.postId); // NEW: Load comments
    
    // NEW: อัปเดตจำนวนผู้ชมวิวเมื่อหน้าจอถูกโหลด
    _updatePostViewCount();
  }
  
  // NEW: ฟังก์ชันเรียก API สำหรับนับวิว
  void _updatePostViewCount() {
    // ไม่ต้อง await เพื่อไม่ให้ block UI ในขณะที่รอการโหลดข้อมูลโพสต์หลัก
    apiService.incrementPostView(widget.postId);
  }
  
  @override
  void dispose() {
    _commentController.dispose(); // NEW: Dispose controller
    // _pageController.dispose(); // Removed dispose since PageController is removed
    super.dispose();
  }

  Future<void> _refreshPost() async {
    setState(() {
      futurePost = apiService.fetchPostDetails(widget.postId);
      futureComments = apiService.fetchComments(widget.postId); // NEW: Refresh comments
    });
  }

  // NEW: Refresh only comments
  Future<void> _refreshComments() async {
     setState(() {
      _commentController.clear();
      _isPostingComment = false;
      futureComments = apiService.fetchComments(widget.postId);
    });
  }

  // NEW: Handle posting a new comment
  Future<void> _handlePostComment() async {
    final authService = context.read<AuthService>();
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกความคิดเห็น')),
      );
      return;
    }

    if (!authService.isLoggedIn) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณต้องเข้าสู่ระบบเพื่อแสดงความคิดเห็น')),
      );
      return;
    }

    setState(() {
      _isPostingComment = true;
    });

    final String? token = authService.currentUser?.token;
    
    final error = await apiService.postComment(
      postId: widget.postId,
      content: content,
      token: token!,
    );

    setState(() {
      _isPostingComment = false;
    });

    if (error == null) {
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งความคิดเห็นสำเร็จ'), backgroundColor: Colors.green),
      );
      _refreshComments(); // Refresh the comment list
    } else {
      // Failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $error'), backgroundColor: Colors.red),
      );
    }
  }


  // Helper function to launch URLs safely
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    // Use LaunchMode.externalApplication for tel: links and http/https links
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถเปิดลิงก์: $url')));
      }
    }
  }

  // Lightbox for Gallery (Handles multiple images with PageView)
  void _openImageLightbox(
      BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black, // Use full black for better light box effect
      barrierDismissible: true, // Allow closing by tapping the backdrop (outside the dialog area)
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          // Use a full-screen container to ensure the Dialog takes up the whole screen for easier tap to dismiss
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Image Viewer (Carousel)
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator(color: Colors.white)),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.white, size: 50),
                      ),
                    );
                  },
                ),
              ),
              // Close Button (X)
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // NEW: Lightbox for single images embedded in the post content
  void _openSingleImageLightbox(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white, size: 50),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('กรุณาเปิด GPS เพื่อใช้งานฟังก์ชันนี้')));
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

  Future<void> _launchMapsNavigation(Post post) async {
    if (post.latitude == null || post.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบพิกัด GPS สำหรับสถานที่นี้')));
      }
      return;
    }

    final destinationLat = post.latitude;
    final destinationLng = post.longitude;

    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้')));
      }
    }
  }

  Future<void> _shareContent(Post post) async {
    final String textToShare =
        '${post.title}\n\nที่อยู่: ${post.address ?? 'ไม่มีข้อมูล'}\n\nแชร์จากแอปพลิเคชัน Travel Yasothon';
    await Share.share(textToShare, subject: post.title);
  }

  @override
  Widget build(BuildContext) {
    // We assume AuthService is provided by an ancestor widget (e.g., in main.dart)
    // This allows us to use context.watch() and context.read()
    // Example main.dart setup:
    // ChangeNotifierProvider(
    //   create: (_) => AuthService(),
    //   child: MaterialApp(...)
    // )
    
    return Scaffold(
      body: FutureBuilder<Post>(
        future: futurePost,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final post = snapshot.data!;
            return _buildContent(context, post);
          } else {
            return const Center(child: Text('ไม่พบข้อมูล'));
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Post post) {
    return RefreshIndicator(
      onRefresh: _refreshPost,
      color: Colors.deepOrange,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, post),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.address ?? 'ไม่มีข้อมูลที่อยู่',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Gallery with height 80, showing all images via horizontal scroll (Keep as is)
                    _buildGallery(context, post),
                    const SizedBox(height: 24),
                    _buildActionButtons(post),
                    const SizedBox(height: 24),
                    _buildRatingSection(post),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black12, thickness: 1),
                    const SizedBox(height: 16),
                    // HTML Content rendering with image support (NEW Renderer)
                    Html(
                      data: post.htmlContent ?? 'ไม่มีคำอธิบาย',
                      onLinkTap: (url, _, __) {
                        if (url != null) {
                          _launchUrl(url); // Handle all links including tel:
                        }
                      },
                      // FIXED: Changed 'customRender' back to 'extensions' and using TagExtension
                      extensions: [
                        TagExtension(
                          tagsToExtend: {"img"},
                          builder: (context) {
                            final String? src = context.attributes['src'];
                            if (src != null) {
                              return GestureDetector(
                                // ADDED ! to confirm buildContext is non-null
                                onTap: () => _openSingleImageLightbox(context.buildContext!, src),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: src,
                                    fit: BoxFit.fitWidth, // Make image fit container width
                                    // ADDED ! to confirm buildContext is non-null
                                    width: MediaQuery.of(context.buildContext!).size.width,
                                    placeholder: (context, url) => Container(
                                      height: 150, // Placeholder height
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                      style: {
                        "body": Style(
                          fontSize: FontSize(15.0),
                          color: Colors.black54,
                          lineHeight: LineHeight.number(1.5),
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        "a": Style(
                          textDecoration: TextDecoration.none, // ลบขีดเส้นใต้
                          color: Colors.blue.shade700, // กำหนดสีลิงก์
                          fontWeight: FontWeight.w500, // ให้ลิงก์ดูเด่นขึ้น
                        ),
                        "p": Style(margin: Margins.only(bottom: 10)),
                        // Removed default img style as it's now handled by the custom renderer
                        "figure": Style(
                            margin: Margins.zero, padding: HtmlPaddings.zero)
                      },
                    ),

                    // ===================================
                    // NEW: COMMENT SECTION
                    // ===================================
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black12, thickness: 1),
                    const SizedBox(height: 16),
                    _buildCommentSection(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Post post) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      backgroundColor: Colors.deepOrange,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: const [
        // Stack(
        //   alignment: Alignment.center,
        //   children: [
        //     IconButton(
        //       icon: const Icon(Icons.favorite, color: Colors.white, size: 28),
        //       onPressed: () {},
        //     ),
        //     Positioned(
        //       top: 10,
        //       right: 8,
        //       child: Container(
        //         padding:
        //             const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        //         decoration: BoxDecoration(
        //           color: Colors.red,
        //           borderRadius: BorderRadius.circular(10),
        //         ),
        //         constraints: const BoxConstraints(
        //           minWidth: 18,
        //           minHeight: 18,
        //         ),
        //         child: const Text(
        //           '2',
        //           style: TextStyle(
        //               color: Colors.white,
        //               fontSize: 12,
        //               fontWeight: FontWeight.bold),
        //           textAlign: TextAlign.center,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(
        //   width: 8,
        // )
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: CachedNetworkImage(
          imageUrl: post.imageUrl,
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(0.3),
          colorBlendMode: BlendMode.darken,
          placeholder: (context, url) => Container(color: Colors.grey[300]),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }

  // UPDATED: Gallery: Shows all images in a horizontal scrollable view, fixed height 80, showing multiple images at once.
  Widget _buildGallery(BuildContext context, Post post) {
    if (post.galleryImages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate the width of each item to show roughly 3 images (2.5 images fully visible)
    // The total width is determined by the ListView itself, but we enforce the item height.
    final double itemWidth = (MediaQuery.of(context).size.width - 40) / 3;

    return SizedBox(
      height: 80, // Height is fixed at 80 as requested
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: post.galleryImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0), // Padding between images
            child: GestureDetector(
              onTap: () =>
                  _openImageLightbox(context, post.galleryImages, index),
              child: Hero(
                tag: 'gallery-image-${post.id}-$index',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: post.galleryImages[index],
                    // Set width to itemWidth for 3-images-per-view effect, height is fixed by the SizedBox
                    width: itemWidth, 
                    height: 80, 
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 40)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Post post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(null, 'คะแนน', '${post.rating}', isRating: true),
        // MODIFIED: Icon changed, label updated
        _buildActionButton(Icons.mode_comment_outlined, 'ความคิดเห็น', null), 
        _buildActionButton(Icons.near_me_outlined, 'นำทาง', null,
            onTap: () => _launchMapsNavigation(post)),
        _buildActionButton(FontAwesomeIcons.facebook, 'แชร์', null,
            onTap: () => _shareContent(post)),
        // Views display
        Column(
          children: [
            Icon(Icons.visibility_outlined, color: Colors.grey.shade600, size: 28),
            const SizedBox(height: 8),
            Text(
              '${post.postViews} เข้าชม',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData? icon, String label, String? rating,
      {bool isRating = false, VoidCallback? onTap}) {
    final bool isEnabled = onTap != null;
    // MODIFIED: Adjusted colors for clarity
    final Color iconColor = Colors.grey.shade600;
    final Color labelColor = Colors.grey.shade700;

    final content = Column(
      children: [
        if (isRating)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12)),
            child: Text(rating ?? '0.0',
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          )
        else
          Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 14,
          ),
        ),
      ],
    );

    if (isEnabled) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildRatingSection(Post post) {
    int fullStars = post.rating.floor();
    bool hasHalfStar = (post.rating - fullStars) >= 0.5;

    return Row(
      children: [
        const Text(
          'ให้คะแนน :',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(width: 10),
        ...List.generate(5, (index) {
          if (index < fullStars) {
            return const Icon(Icons.star, color: Colors.amber, size: 28);
          }
          if (index == fullStars && hasHalfStar) {
            return const Icon(Icons.star_half, color: Colors.amber, size: 28);
          }
          return const Icon(Icons.star_border, color: Colors.amber, size: 28);
        }),
      ],
    );
  }

  // ===================================
  // NEW: WIDGETS FOR COMMENT SECTION
  // ===================================
  
  /// Main wrapper for the comment section
  Widget _buildCommentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ความคิดเห็น',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildCommentInput(context), // Input field (Dynamic based on login state)
        const SizedBox(height: 24),
        _buildCommentList(context), // List of comments
      ],
    );
  }

  /// Shows TextField if logged in, otherwise shows a "Login to comment" message
  Widget _buildCommentInput(BuildContext context) {
    // Watch for changes in AuthService to rebuild this widget
    final authService = context.watch<AuthService>();

    if (authService.isLoggedIn) {
      // User is logged in, show the comment form
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(
                  authService.currentUser?.avatarUrl ?? 'https://i.pravatar.cc/150?u=default'
                ),
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 12),
              Text(
                authService.currentUser?.displayName ?? 'ผู้ใช้',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'เขียนความคิดเห็นของคุณ...',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            minLines: 1,
            enabled: !_isPostingComment, // Disable while posting
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isPostingComment ? null : _handlePostComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isPostingComment 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('ส่งความคิดเห็น'),
            ),
          ),
        ],
      );
    } else {
      // User is a guest, show login prompt
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.grey),
            const SizedBox(width: 12),
            // TODO: Wrap this Text with a GestureDetector to navigate to LoginScreen
            Text(
              'กรุณาเข้าสู่ระบบเพื่อแสดงความคิดเห็น', 
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
          ],
        ),
      );
    }
  }

  /// Renders the list of comments using a FutureBuilder
  Widget _buildCommentList(BuildContext context) {
    return FutureBuilder<List<Comment>>(
      future: futureComments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('ไม่สามารถโหลดความคิดเห็นได้: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('ยังไม่มีความคิดเห็น', style: TextStyle(color: Colors.grey)));
        }

        final comments = snapshot.data!;
        
        // Use ListView.separated for dividers, but set physics to NeverScrollableScrollPhysics
        // because it's already inside a CustomScrollView
        return ListView.separated(
          itemCount: comments.length,
          shrinkWrap: true, // Important inside CustomScrollView
          physics: const NeverScrollableScrollPhysics(), // Important inside CustomScrollView
          itemBuilder: (context, index) {
            final comment = comments[index];
            return _buildCommentItem(comment);
          },
          separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 24),
        );
      },
    );
  }

  /// Renders a single comment item
  Widget _buildCommentItem(Comment comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: CachedNetworkImageProvider(comment.avatarUrl),
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.date,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Use Html widget to render comment content safely
              Html(
                data: comment.content,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14.0),
                    color: Colors.black54,
                    lineHeight: LineHeight.number(1.4),
                  ),
                  "p": Style(margin: Margins.zero),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

