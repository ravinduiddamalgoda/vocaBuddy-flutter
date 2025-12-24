import 'package:flutter/material.dart';
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
      initialRoute: '/',      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      routes: {
        '/': (context) => const DoctorHomeScreen(),
        '/assign-activities': (context) => const SelectChildrenPage(),
        '/view-reports': (context) =>  ParentDashboardMain(),
        '/voice-therapy':(context) => VoiceRecordingApp(),
        '/attempt-session': (context) => const SpeechBuddyApp(),

        // '/view-reports': (context) => const ViewReportsPage(),
        // later:
        // '/sessions': (context) => const SessionsPage(),
        // '/chat': (context) => const ChatPage(),
        // '/account': (context) => const AccountPage(),
      },
    );
  }
}
