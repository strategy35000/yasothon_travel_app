import 'dart:convert';
import 'package:flutter/foundation.dart'; // สำหรับ ChangeNotifier
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart'; // สำหรับจัดเก็บ Token

// ==========================================================
// 1. AUTHENTICATION MODELS AND SERVICE
// ==========================================================

/// Model สำหรับเก็บข้อมูลผู้ใช้ที่ได้จากการล็อกอิน
class User {
  final String token;
  final String email;
  final String nicename;
  final String displayName;
  final String avatarUrl; // เปลี่ยนชื่อฟิลด์จาก profileImageUrl เป็น avatarUrl

  User({
    required this.token,
    required this.email,
    required this.nicename,
    required this.displayName,
    this.avatarUrl = 'https://i.pravatar.cc/150?u=default', // ใช้ avatarUrl แทน
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // ใน JWT Response ทั่วไปมักจะไม่มี URL รูปโปรไฟล์ แต่เราสามารถใช้ Gravatar
    // หรือ Placeholder ได้ หากต้องการใช้รูปจริงต้องดึงจาก WP User Endpoint แยกต่างหาก
    final String userEmail = json['user_email'] ?? '';

    return User(
      token: json['token'] ?? '',
      email: userEmail,
      nicename: json['user_nicename'] ?? '',
      displayName: json['user_display_name'] ?? '',
      // Note: ใน production, ควรดึงรูปโปรไฟล์จริงจาก WordPress
      avatarUrl: 'https://i.pravatar.cc/150?u=$userEmail', 
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'user_email': email,
        'user_nicename': nicename,
        'user_display_name': displayName,
        'avatar_url': avatarUrl, // เปลี่ยนชื่อคีย์ใน JSON เป็น avatar_url
      };
}

/// Service สำหรับจัดการสถานะการเข้าสู่ระบบและ API ของ JWT
class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  final String _loginUrl =
      'https://travel.yasothon.go.th/wp-json/jwt-auth/v1/token';
  
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadUser();
  }

  // --- Persistent Storage Management ---

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userDataJson = prefs.getString(_userKey);
      
      if (token != null && userDataJson != null) {
        final userData = jsonDecode(userDataJson);
        // สร้าง User object จากข้อมูลที่จัดเก็บ
        _currentUser = User(
          token: token,
          email: userData['user_email'],
          nicename: userData['user_nicename'],
          displayName: userData['user_display_name'],
          avatarUrl: userData['avatar_url'], // ใช้ avatar_url
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
      _currentUser = null; // Ensure user is null if loading fails
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // --- Authentication Operations ---

  /// ฟังก์ชันล็อกอิน
  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data);
        _currentUser = user;
        await _saveUser(user);
        notifyListeners();
        return null; // Login successful
      } else {
        // Handle non-200 status codes (e.g., login failed due to wrong creds)
        final errorData = jsonDecode(response.body);
        return errorData['message'] ?? 'เข้าสู่ระบบล้มเหลว';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
    }
  }

  /// ฟังก์ชันออกจากระบบ
  Future<void> logout() async {
    _currentUser = null;
    await _deleteUser();
    notifyListeners();
  }
}

// ==========================================================
// 2. POST MODELS AND API SERVICE
// ==========================================================

// Model for the Post data, updated with location and category fields
class Post {
  final int id;
  final String title;
  final String imageUrl;
  final String date;
  final String? content; // This will now be plain text content
  final String? htmlContent; // This will hold the raw HTML content
  final String? address;
  final double rating;
  final int postViews;
  final List<String> galleryImages;
  final List<int> categoryIds;

  // Fields for nearby feature
  final double? latitude;
  final double? longitude;
  final String? district;
  double? distanceInKm; // To store calculated distance

  Post({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.date,
    this.content,
    this.htmlContent,
    this.address,
    this.rating = 0.0,
    this.postViews = 0,
    this.galleryImages = const [],
    this.categoryIds = const [],
    this.latitude,
    this.longitude,
    this.district,
    this.distanceInKm,
  });

  static String _parseHtmlString(String htmlString) {
    try {
      initializeDateFormatting('th', null);
      final document = parse(htmlString);
      final String? parsedString =
          parse(document.body?.text).documentElement?.text;
      return parsedString ?? '';
    } catch (e) {
      return htmlString;
    }
  }

  static String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'ไม่มีข้อมูล';
    try {
      DateTime dateTime = DateTime.parse(dateString);
      // เพิ่ม 543 ปี เพื่อแปลงเป็น พ.ศ. สำหรับการแสดงผล
      dateTime = DateTime(dateTime.year + 543, dateTime.month, dateTime.day,
          dateTime.hour, dateTime.minute, dateTime.second);
      final formatter = DateFormat('d MMM yyyy', 'th');
      return formatter.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  static List<String> _parseGalleryImages(String htmlContent) {
    try {
      final document = parse(htmlContent);
      final galleryElement = document.querySelector('.wp-block-gallery');
      if (galleryElement == null) {
        return [];
      }
      final imageElements = galleryElement.querySelectorAll('img');
      return imageElements
          .map((element) => element.attributes['src'])
          .where((src) => src != null)
          .cast<String>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  // This helper is now only for plain text previews, not for detail view
  static String _getCleanedContentForPlainText(String htmlContent) {
    try {
      final document = parse(htmlContent);
      document.querySelector('.wp-block-gallery')?.remove();
      return document.body?.innerHtml ?? '';
    } catch (e) {
      return htmlContent;
    }
  }

  factory Post.fromJson(Map<String, dynamic> json, {String? featuredImageUrl}) {
    final imageUrl = featuredImageUrl ??
        'https://placehold.co/600x400/EEE/31343C?text=No+Image';

    double? lat;
    double? lon;
    String? dist;
    String? addr;

    if (json.containsKey('location_data') && json['location_data'] is Map) {
      final locationData = json['location_data'];
      lat = double.tryParse(locationData['latitude']?.toString() ?? '');
      lon = double.tryParse(locationData['longitude']?.toString() ?? '');
      dist = locationData['district']?['label'] ?? '';
      addr = locationData['address'] ?? 'ไม่มีข้อมูลที่อยู่';
    }

    final rawContent = json['content']?['rendered'] ?? '';
    final gallery = _parseGalleryImages(rawContent);
    final cleanedHtmlForPlainText = _getCleanedContentForPlainText(rawContent);

    return Post(
      id: json['id'],
      title: _parseHtmlString(json['title']?['rendered'] ?? 'ไม่มีชื่อเรื่อง'),
      date: _formatDate(json['date'] ?? ''),
      content: _parseHtmlString(cleanedHtmlForPlainText), // Plain text for previews
      htmlContent: rawContent, // MODIFIED: Use the full raw HTML for rendering in detail view
      address: addr,
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      postViews: int.tryParse(json['post_views']?.toString() ?? '0') ?? 0,
      imageUrl: imageUrl,
      galleryImages: gallery,
      categoryIds: List<int>.from(json['categories'] ?? []),
      latitude: lat,
      longitude: lon,
      district: dist,
    );
  }
}

// ==========================================================
// 3. NEW: COMMENT MODEL
// ==========================================================
class Comment {
  final int id;
  final String authorName;
  final String avatarUrl;
  final String date;
  final String content;

  Comment({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.date,
    required this.content,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      authorName: json['author_name'] ?? 'ผู้ใช้',
      // ดึง URL รูปภาพขนาด 96x96
      avatarUrl: json['author_avatar_urls']?['96'] ??
          'https://i.pravatar.cc/150?u=anonymous',
      // ใช้วันที่จาก Post._formatDate เพื่อให้รูปแบบตรงกัน
      date: Post._formatDate(json['date'] ?? ''),
      content: json['content']?['rendered'] ?? '...',
    );
  }
}


class ApiService {
  final String _baseUrl = 'https://travel.yasothon.go.th/wp-json/wp/v2';
  // MODIFIED: Base URL สำหรับ Custom Endpoint ที่สร้างใน functions.php
  final String _appBaseUrl = 'https://travel.yasothon.go.th/wp-json/app/v1';

  Future<List<Post>> fetchFeaturedPosts() async {
    return fetchPostsByCategory(13);
  }

  Future<List<Post>> fetchAllNearbyPosts({int page = 1}) async {
    const int perPage = 15;
    final response = await http.get(Uri.parse(
        '$_baseUrl/posts?categories_exclude=1,32&per_page=$perPage&page=$page&_fields=id,title,date,_links,location_data,categories'));

    if (response.statusCode == 200) {
      List<dynamic> postsJson = json.decode(response.body);
      if (postsJson.isEmpty) {
        return [];
      }

      List<Future<Post?>> futurePosts = postsJson.map((postJson) async {
        final mediaLink = postJson['_links']['wp:featuredmedia']?[0]?['href'];
        if (mediaLink != null) {
          try {
            final mediaResponse = await http.get(Uri.parse(mediaLink));
            if (mediaResponse.statusCode == 200) {
              final mediaJson = json.decode(mediaResponse.body);
              final imageUrl = mediaJson['source_url'];
              return Post.fromJson(postJson, featuredImageUrl: imageUrl);
            }
          } catch (e) {
            // Handle error
          }
        }
        return Post.fromJson(postJson);
      }).toList();

      final posts = await Future.wait(futurePosts);
      return posts.where((p) => p != null).cast<Post>().toList();
    } else {
      throw Exception('Failed to load nearby posts');
    }
  }

  Future<List<Post>> fetchPostsByCategory(int categoryId, {int page = 1, int perPage = 10}) async {
    final postsResponse = await http.get(Uri.parse(
        '$_baseUrl/posts?categories=$categoryId&per_page=$perPage&page=$page&_fields=id,title,date,post_views,_links,content,location_data'));

    if (postsResponse.statusCode == 200) {
      List<dynamic> postsJson = json.decode(postsResponse.body);
      if (postsJson.isEmpty) {
        return [];
      }

      List<Future<Post?>> futurePosts = postsJson.map((postJson) async {
        final mediaLink = postJson['_links']['wp:featuredmedia']?[0]?['href'];
        if (mediaLink != null) {
          try {
            final mediaResponse = await http.get(Uri.parse(mediaLink));
            if (mediaResponse.statusCode == 200) {
              final mediaJson = json.decode(mediaResponse.body);
              final imageUrl = mediaJson['source_url'];
              return Post.fromJson(postJson, featuredImageUrl: imageUrl);
            }
          } catch (e) {
            return Post.fromJson(postJson);
          }
        }
        return Post.fromJson(postJson);
      }).toList();

      final posts = await Future.wait(futurePosts);
      return posts.where((p) => p != null).cast<Post>().toList();
    } else {
      throw Exception('Failed to load posts for category $categoryId');
    }
  }

  Future<List<Post>> searchPosts(String query, {int page = 1, int perPage = 20}) async {
    final encodedQuery = Uri.encodeComponent(query);
    final postsResponse = await http.get(Uri.parse(
        '$_baseUrl/posts?search=$encodedQuery&per_page=$perPage&page=$page&_fields=id,title,date,post_views,_links,content,location_data'));

    if (postsResponse.statusCode == 200) {
      List<dynamic> postsJson = json.decode(postsResponse.body);
      if (postsJson.isEmpty) {
        return [];
      }

      List<Future<Post?>> futurePosts = postsJson.map((postJson) async {
        final mediaLink = postJson['_links']['wp:featuredmedia']?[0]?['href'];
        if (mediaLink != null) {
          try {
            final mediaResponse = await http.get(Uri.parse(mediaLink));
            if (mediaResponse.statusCode == 200) {
              final mediaJson = json.decode(mediaResponse.body);
              final imageUrl = mediaJson['source_url'];
              return Post.fromJson(postJson, featuredImageUrl: imageUrl);
            }
          } catch (e) {
            // In case of media fetch error, still return post without image
            return Post.fromJson(postJson);
          }
        }
        return Post.fromJson(postJson);
      }).toList();

      final posts = await Future.wait(futurePosts);
      return posts.where((p) => p != null).cast<Post>().toList();
    } else {
      throw Exception('Failed to search posts for query: $query');
    }
  }

  Future<Post> fetchPostDetails(int postId) async {
    // MODIFIED: Requesting 'content' field to get the full HTML
    final response = await http.get(Uri.parse(
        '$_baseUrl/posts/$postId?_fields=id,title,date,content,rating,post_views,_links,location_data,categories'));

    if (response.statusCode == 200) {
      final postJson = json.decode(response.body);
      final mediaLink = postJson['_links']['wp:featuredmedia']?[0]?['href'];
      String? imageUrl;

      if (mediaLink != null) {
        final mediaResponse = await http.get(Uri.parse(mediaLink));
        if (mediaResponse.statusCode == 200) {
          final mediaJson = json.decode(mediaResponse.body);
          imageUrl = mediaJson['source_url'];
        }
      }

      return Post.fromJson(postJson, featuredImageUrl: imageUrl);
    } else {
      throw Exception('Failed to load post details for ID $postId');
    }
  }

  /// NEW: ฟังก์ชันสำหรับอัปเดตจำนวนผู้ชมวิวผ่าน Custom Endpoint
  /// Endpoint นี้ชี้ไปที่ฟังก์ชันที่เราสร้างใน functions.php
  Future<void> incrementPostView(int postId) async {
    // ใช้ Custom Endpoint ที่สร้างใน functions.php: /wp-json/app/v1/increment-view/<id>
    final url = '$_appBaseUrl/increment-view/$postId'; 
    try {
      // ใช้ GET request เพื่อเรียก Custom Endpoint 
      final response = await http.get(Uri.parse(url));

      if (kDebugMode) {
        if (response.statusCode == 200) {
          print('Post ID $postId view count incremented successfully (Custom API). Status: ${response.statusCode}');
        } else {
          print('Failed to increment view count for Post ID $postId (Custom API). Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calling view increment API for Post ID $postId: $e');
      }
      // ไม่ต้อง throw exception เพราะการนับวิวไม่ควรทำให้หน้าจอหลักพัง
    }
  }

  // ==========================================================
  // 4. NEW: COMMENT API FUNCTIONS
  // ==========================================================

  /// ดึงรายการความคิดเห็นสำหรับโพสต์
  Future<List<Comment>> fetchComments(int postId) async {
    // order=asc เรียงจากเก่าไปใหม่
    final url = '$_baseUrl/comments?post=$postId&_fields=id,author_name,author_avatar_urls,date,content&orderby=date&order=asc';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> commentsJson = json.decode(response.body);
        return commentsJson.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching comments: $e');
      }
      return []; // คืนค่า list ว่างหากมีปัญหา
    }
  }

  /// ส่งความคิดเห็นใหม่ (ต้องใช้ Token)
  /// คืนค่าเป็น String (ข้อความ error) หรือ null (ถ้าสำเร็จ)
  Future<String?> postComment({
    required int postId,
    required String content,
    required String token,
  }) async {
    final url = '$_baseUrl/comments';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ส่ง Token เพื่อยืนยันตัวตน
        },
        body: jsonEncode({
          'post': postId,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        // 201 Created = Success
        return null;
      } else {
        // จัดการ Error (เช่น 401/403 ถ้าไม่ได้ล็อกอิน หรือ 400 ถ้าข้อมูลไม่ครบ)
        final errorData = jsonDecode(response.body);
        String message = errorData['message'] ?? 'ไม่สามารถส่งความคิดเห็นได้';
        if (errorData['code'] == 'rest_comment_login_required') {
          message = 'คุณต้องเข้าสู่ระบบเพื่อแสดงความคิดเห็น';
        }
        return message;
      }
    } catch (e) {
      return 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
    }
  }
}

