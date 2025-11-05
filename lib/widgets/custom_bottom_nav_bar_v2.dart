import 'package:flutter/material.dart';
import 'package:yasothon_travel_app/main.dart';

class CustomBottomNavBarV2 extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBarV2({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.sync, 'label': 'ข่าวสาร'},
      {'icon': Icons.location_on_outlined, 'label': 'ใกล้ฉัน'},
      {'icon': Icons.home_rounded, 'label': 'หน้าหลัก'},
      {'icon': Icons.call_outlined, 'label': 'โทรฉุกเฉิน'}, // Changed label for clarity
      {'icon': Icons.menu, 'label': 'อื่นๆ'},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = screenWidth / navItems.length;
    const double indicatorSize = 64.0;
    const double navBarHeight = 75.0;
    const double overflowAmount = 12.0;

    final double indicatorLeftPosition = (itemWidth * currentIndex) + (itemWidth / 2) - (indicatorSize / 2);

    return Container(
      height: navBarHeight + overflowAmount,
      width: screenWidth,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: navBarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.translucent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'],
                          color: isSelected ? Colors.transparent : kPrimaryColor,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: kPrimaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: indicatorLeftPosition,
            top: -overflowAmount,
            child: Container(
              width: indicatorSize,
              height: indicatorSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor.withOpacity(0.25),
              ),
              child: Center(
                child: Container(
                  width: indicatorSize * 0.75,
                  height: indicatorSize * 0.75,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor,
                  ),
                  child: Center(
                    child: Icon(
                      navItems[currentIndex]['icon'],
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
