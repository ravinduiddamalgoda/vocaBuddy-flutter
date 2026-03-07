import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/splashScreen/splashScreen.dart';
import 'pages/doctor_home_screen.dart';
import 'pages/auth/login_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/therapyGenerate/SelectChildrenPage.dart';
import 'pages/Parent Awareness/parent_dashboard_main.dart';
import 'pages/inputVoices/input_new_voices.dart';
import 'pages/therapy_data_management_page.dart';
import 'pages/therapyStartScreen/therapy_start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await Firebase.initializeApp();
  }

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
      theme: ThemeData(fontFamily: 'Poppins'),
      routes: {
        '/': (context) => const SplashScreen(), // ✅ START HERE
        '/login': (context) => const LoginPage(),
        '/home': (context) => const DoctorHomeScreen(), // ✅ HOME ROUTE
        '/profile': (context) => const ProfilePage(),
        '/assign-activities': (context) => const SelectChildrenPage(),
        '/view-reports': (context) => ParentDashboardMain(),
        '/attempt-session': (context) => const InstructionsScreen(),
        '/upload-therapy-data': (context) => const TherapyDataManagementPage(),
        '/upload-voice-recordings': (context) => UploadVoiceRecordingsScreen(),
      },
    );
  }
}
