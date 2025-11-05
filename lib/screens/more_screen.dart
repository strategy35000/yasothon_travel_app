import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  // Helper to create list tiles
  Widget _buildListTile(BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
  
  // Helper to launch URLs
  void _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มเติม', style: TextStyle(fontWeight: FontWeight.bold)),
         backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildListTile(
            context,
            title: 'เกี่ยวกับแอปพลิเคชัน',
            icon: Icons.info_outline,
            onTap: () {
              // You can create a dedicated 'About' page
              showAboutDialog(
                context: context,
                applicationName: 'เที่ยวยโสธร',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 สำนักงานจังหวัดยโสธร',
                children: [
                  const SizedBox(height: 16),
                  const Text('แอปพลิเคชันนี้จัดทำขึ้นเพื่อส่งเสริมการท่องเที่ยวภายในจังหวัดยโสธร'),
                ]
              );
            },
          ),
          _buildListTile(
            context,
            title: 'นโยบายความเป็นส่วนตัว (Privacy Policy)',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              // IMPORTANT: You MUST have a privacy policy. Replace with your actual URL.
              _launchURL('https://travel.yasothon.go.th/privacy-policy', context);
            },
          ),
          _buildListTile(
            context,
            title: 'ให้คะแนนแอป',
            icon: Icons.star_outline,
            onTap: () {
              // This will open the Play Store listing once the app is published
              // Replace 'com.example.yasothon_travel_app' with your actual package name
              _launchURL('https://play.google.com/store/apps/details?id=com.travel.yasothon.go.th', context);
            },
          ),
           _buildListTile(
            context,
            title: 'ติดต่อผู้พัฒนา',
            icon: Icons.email_outlined,
            onTap: () {
               _launchURL('https://www.facebook.com/j.yasothon', context);
            },
          ),
        ],
      ),
    );
  }
}
