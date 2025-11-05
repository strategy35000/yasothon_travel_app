import 'package:flutter/material.dart';
import 'package:yasothon_travel_app/main.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key, 
    required this.title, 
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: actions,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryLightColor, kPrimaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
