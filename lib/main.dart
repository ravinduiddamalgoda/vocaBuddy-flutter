import 'package:flutter/material.dart';
import 'pages/doctor_home_screen.dart';
import 'pages/therapyGenerate/SelectChildrenPage.dart';
import 'pages/Parent Awareness/parent_dashboard_main.dart';
import 'pages/inputVoices/input_new_voices.dart';
import 'pages/therapyStartScreen/therapy_start_screen.dart';
import 'pages/therapy_data_management_page.dart';
import 'services/upload_service.dart';


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
      scaffoldMessengerKey: UploadService.scaffoldMessengerKey,
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      routes: {
        '/': (context) => const DoctorHomeScreen(),
        '/assign-activities': (context) => const SelectChildrenPage(),
        '/view-reports': (context) =>  ParentDashboardMain(),
       // '/voice-therapy':(context) => VoiceRecordingApp(),
        '/attempt-session': (context) => const InstructionsScreen(),
        '/upload-voice-recordings' : (context)=> UploadVoiceRecordingsScreen(),
        '/upload-therapy-data': (context) => const TherapyDataManagementPage(),

        // '/view-reports': (context) => const ViewReportsPage(),
        // later:
        // '/sessions': (context) => const SessionsPage(),
        // '/chat': (context) => const ChatPage(),
        // '/account': (context) => const AccountPage(),
      },
    );
  }
}
