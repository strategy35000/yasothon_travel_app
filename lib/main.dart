import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ADDED
import 'package:yasothon_travel_app/api/api_service.dart'; // ADDED
import 'package:yasothon_travel_app/screens/splash_screen.dart'; 

const Color kPrimaryColor = Color(0xFFF5862A);
const Color kPrimaryLightColor = Color(0xFFFDC830);
const Color kBackgroundColor = Color(0xFFFFF9F0);

void main() {
  runApp(
    // WRAPPED with ChangeNotifierProvider for AuthService
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const YasothonTravelApp(),
    ),
  );
}

class YasothonTravelApp extends StatelessWidget {
  const YasothonTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yasothon Travel',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: GoogleFonts.sarabunTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: kPrimaryLightColor),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
