import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yasothon_travel_app/screens/main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/splash_bg.jpg"), // ใช้รูปภาพที่คุณบันทึกไว้
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}