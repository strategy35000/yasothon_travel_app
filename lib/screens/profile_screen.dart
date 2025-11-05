import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api_service.dart';
import '../main.dart'; // For kPrimaryColor

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, AuthService authService) async {
    await authService.logout();
    if (context.mounted) {
      Navigator.of(context).pop(); // Go back to Home
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ออกจากระบบเรียบร้อยแล้ว'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลส่วนตัว', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;

          if (user == null) {
            // Should not happen if accessed from AppDrawer when logged in, but safe guard
            return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: kPrimaryLightColor,
                          backgroundImage: CachedNetworkImageProvider(user.avatarUrl!),
                          child: null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // Account Details
                const Text('รายละเอียดบัญชี', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                const Divider(color: kPrimaryColor, thickness: 2),
                
                _buildInfoTile(context, Icons.verified_user_outlined, 'ชื่อผู้ใช้', user.nicename),
                _buildInfoTile(context, Icons.email_outlined, 'อีเมล', user.email),
                _buildInfoTile(context, Icons.badge_outlined, 'ชื่อที่แสดง', user.displayName),

                const SizedBox(height: 40),

                // Logout Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('ออกจากระบบ', style: TextStyle(fontSize: 18, color: Colors.white)),
                  onPressed: () => _logout(context, authService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryColor, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
