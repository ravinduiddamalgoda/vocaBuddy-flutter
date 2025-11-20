import 'package:flutter/material.dart';
import 'pages/doctor_home_screen.dart';
import 'pages/therapyGenerate/createActivity.dart';

import 'pages/therapyStartScreen/therapy_start_screen.dart';
import 'pages/ActivityStart/activity_start_screen.dart';
import 'pages/Parent Awareness/parent dashboard.dart';



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
        fontFamily: 'Poppins', // since you added Poppins font
      ),
      routes: {
        '/': (context) => const DoctorHomeScreen(),
       // '/assign-activities': (context) => const CreateActivityPage(),
        '/assign-activities': (context) => const SpeechBuddyApp()
      //  '/assign-activities': (context) => const AntLearningActivity()
        '/assign-activities': (context) => const CreateActivityPage(),
        '/view-reports': (context) =>  ParentDashboard(),
        // '/view-reports': (context) => const ViewReportsPage(),
        // later:
        // '/sessions': (context) => const SessionsPage(),
        // '/chat': (context) => const ChatPage(),
        // '/account': (context) => const AccountPage(),
      },
    );
  }
}
