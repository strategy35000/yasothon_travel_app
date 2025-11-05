import 'package:flutter/material.dart';
import 'package:yasothon_travel_app/screens/home_screen.dart';
import 'package:yasothon_travel_app/screens/more_screen.dart';
import 'package:yasothon_travel_app/screens/nearby_screen.dart';
import 'package:yasothon_travel_app/screens/news_screen.dart';
import 'package:yasothon_travel_app/screens/phone_screen.dart';
import 'package:yasothon_travel_app/widgets/custom_bottom_nav_bar_v2.dart';
// CHANGED: ไม่ต้อง import ARScreen แล้ว
// import 'package:yasothon_travel_app/screens/ar_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // CHANGED: กำหนดให้เปิดแอปมาที่หน้า Home (index 2)
  int _selectedIndex = 2;

  // CHANGED: จัดลำดับหน้าใหม่เป็น 5 หน้า และเอา ARScreen ออก
  final List<Widget> _pages = [
    const NewsScreen(),      // 0
    const NearbyScreen(),    // 1
    const HomeScreen(),      // 2 (หน้าหลัก)
    const PhoneScreen(),     // 3
    const MoreScreen(),      // 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBarV2(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}