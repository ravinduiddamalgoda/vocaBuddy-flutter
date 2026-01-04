import 'package:flutter/material.dart';
import 'pages/splashScreen/splashScreen.dart';
import 'pages/doctor_home_screen.dart';
import 'pages/therapyGenerate/SelectChildrenPage.dart';
import 'pages/Parent Awareness/parent_dashboard_main.dart';
import 'pages/inputVoices/input_new_voices.dart';
import 'pages/therapyStartScreen/therapy_start_screen.dart';

void main() {
  runApp(const VocaBuddyApp());
}

class VocaBuddyApp extends StatelessWidget {
  const VocaBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocaBuddy',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      routes: {
        '/': (context) => const SplashScreen(), // ✅ START HERE
        '/home': (context) => const DoctorHomeScreen(), // ✅ HOME ROUTE
        '/assign-activities': (context) => const SelectChildrenPage(),
        '/view-reports': (context) => ParentDashboardMain(),
        '/attempt-session': (context) => const InstructionsScreen(),
        '/upload-voice-recordings': (context) => UploadVoiceRecordingsScreen(),
      },
    );
  }
}
