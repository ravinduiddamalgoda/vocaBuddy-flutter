import 'package:flutter/material.dart';
import '../api/api_client.dart';

final ApiClient api = ApiClient();

bool loadingPreview = true;
String? previewError;
List<String> previewWords = [];


class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  void _go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                    GestureDetector(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF3E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF59316B),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  "Good Afternoon,",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3B1F47),
                  ),
                ),
                const Text(
                  "Doctor!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B1F47),
                  ),
                ),
                const SizedBox(height: 28),

                // Assign Activities card
                GestureDetector(
                  onTap: () => _go(context, '/assign-activities'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Assign Activities",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5A4332),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Let's open up to the things that\nmatter the most",
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xFF8A6E5A),
                                ),
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Text(
                                    "Assign Now",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF6D00),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Color(0xFFFF6D00),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA726),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // View Reports card
                GestureDetector(
                  onTap: () => _go(context, '/view-reports'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Parent Dashboard",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Get back chat access and\nsession credits",
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Text(
                                    "View Now",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.bar_chart,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Attempt Activity card
                GestureDetector(
                  onTap: () => _go(context, '/attempt-session'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEED6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Attempt Activity",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5A4332),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Complete today's assigned\nactivities at your own pace",
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xFF8A6E5A),
                                ),
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Text(
                                    "Start Now",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF6D00),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Color(0xFFFF6D00),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA726),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Upload Therapy Data button
                GestureDetector(
                  onTap: () => _go(context, '/upload-therapy-data'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF34A853).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Upload Therapy Data",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Uploading related PDFs by\nthe therapist",
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Text(
                                    "Upload Now",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.cloud_upload,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Upload New Voice Recordings button
                GestureDetector(
                  onTap: () => _go(context, '/upload-voice-recordings'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Upload New Voice Recordings",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5A4332),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Upload voice sessions and\nrecordings for review",
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(0xFF8A6E5A),
                                ),
                              ),
                              SizedBox(height: 14),
                              Row(
                                children: [
                                  Text(
                                    "Upload Now",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF6D00),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Color(0xFFFF6D00),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA726),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    super.key,
    required this.icon,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseIcon = Icon(
      icon,
      size: 26,
      color: isActive ? Colors.white : const Color(0xFFB0B0B0),
    );

    return GestureDetector(
      onTap: onTap,
      child: isActive
          ? Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFFF6D00),
          shape: BoxShape.circle,
        ),
        child: baseIcon,
      )
          : baseIcon,
    );
  }
}
