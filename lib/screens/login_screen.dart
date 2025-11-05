import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../api/api_service.dart';
import '../main.dart'; // For kPrimaryColor

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Removed _errorMessage state as it will be handled by a dialog

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // NEW: Function to display error message in a sweetalert-like dialog
  void _showErrorDialog(String message) {
    // Clean up HTML tags or long error strings from WordPress
    final cleanMessage = message
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '') // Remove HTML tags and entities
      .split(':').last.trim(); // Take the part after the first colon (to remove "ERROR:")

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          // Custom icon header
          title: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 10),
              Text('เกิดข้อผิดพลาด', style: GoogleFonts.sarabun(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            ],
          ),
          content: Text(
            cleanMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _login(AuthService authService) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน');
      return;
    }

    // Call login service
    final error = await authService.login(username, password);

    if (error == null) {
      if (mounted) {
        // Navigate back to the previous screen (Home Screen) upon success
        Navigator.of(context).pop(); 
      }
    } else {
      // Show the sweetalert-like error dialog
      if (mounted) {
        _showErrorDialog(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar for back navigation
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบสมาชิก', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: kPrimaryColor, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return Container(
            // --- Background Image (splash_bg.jpg) ---
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/splash_bg.jpg"), // ใช้รูปภาพ splash_bg.jpg
                fit: BoxFit.cover,
                // เพิ่ม colorFilter เพื่อให้ข้อความอ่านง่ายขึ้น
                colorFilter: ColorFilter.mode(
                  Colors.black38, // เพิ่มความมืดลงไปเล็กน้อย
                  BlendMode.darken,
                ),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 10, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0), 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- Title/Icon ---
                        const Icon(
                          Icons.travel_explore, 
                          color: kPrimaryColor,
                          size: 60,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ยินดีต้อนรับ', 
                          style: GoogleFonts.sarabun( 
                            fontSize: 28, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.black87
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'เข้าสู่ระบบเพื่อปลดล็อกคุณสมบัติพิเศษ', 
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey[600]
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // --- Username Field ---
                        TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'ชื่อผู้ใช้/อีเมล',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            floatingLabelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none, 
                            ),
                            enabledBorder: OutlineInputBorder( 
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder( 
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50], 
                            prefixIcon: const Icon(Icons.person_outline, color: kPrimaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Password Field ---
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'รหัสผ่าน',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            floatingLabelStyle: const TextStyle(color: kPrimaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.lock_outline, color: kPrimaryColor),
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // --- Login Button ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authService.isLoading ? null : () => _login(authService),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded button
                              padding: const EdgeInsets.symmetric(vertical: 18), // Taller button
                              elevation: 4,
                              shadowColor: kPrimaryColor.withOpacity(0.5),
                              disabledBackgroundColor: Colors.grey.shade400, // Handle loading state
                            ),
                            child: authService.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                  )
                                : const Text('เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // --- Forgot Password Link (Optional but standard for modern forms) ---
                        TextButton(
                          onPressed: () {
                            // Implement navigation to forgot password screen (or show a message)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ฟังก์ชันลืมรหัสผ่านยังไม่พร้อมใช้งาน')),
                            );
                          },
                          child: Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(color: kPrimaryColor.withOpacity(0.8), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
