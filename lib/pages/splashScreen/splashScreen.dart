import 'package:flutter/material.dart';
import 'package:vocabuddy/pages/doctor_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Transform.scale(
          scale: 1.15, // ✅ increase size (try 1.10 - 1.30)
          child: Image.asset(
            "assets/splashScreen/background_remove.png",
            fit: BoxFit.contain, //
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
