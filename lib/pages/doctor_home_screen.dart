import 'package:flutter/material.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                            Text(
                              "Assign Now  📅",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6D00),
                              ),
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
                          Icons.person_outline,
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                              "View Reports",
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
                                  Icons.arrow_right_alt_rounded,
                                  size: 20,
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
                          color: const Color.fromRGBO(255, 255, 255, 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Assign Activities card
              GestureDetector(
                onTap: () => _go(context, '/attempt-session'),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                              "Complete today’s assigned\nactivities at your own pace",
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Color(0xFF8A6E5A),
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              "Start Now  ▶",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6D00),
                              ),
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
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              const Spacer(),
            ],
          ),
        ),
      ),

      // bottomNavigationBar: Container(
      //   padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      //   decoration: const BoxDecoration(
      //     color: Colors.white,
      //     borderRadius: BorderRadius.only(
      //       topLeft: Radius.circular(26),
      //       topRight: Radius.circular(26),
      //     ),
      //     boxShadow: [
      //       BoxShadow(
      //         blurRadius: 10,
      //         offset: Offset(0, -2),
      //         color: Color(0x1A000000),
      //       ),
      //     ],
      //   ),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       _NavItem(
      //         icon: Icons.home_filled,
      //         isActive: true,
      //         onTap: () {},
      //       ),
      //       _NavItem(
      //         icon: Icons.video_call_rounded,
      //         onTap: () => _go(context, '/sessions'),
      //       ),
      //       _NavItem(
      //         icon: Icons.chat_bubble_outline_rounded,
      //         onTap: () => _go(context, '/chat'),
      //       ),
      //       _NavItem(
      //         icon: Icons.person_outline_rounded,
      //         onTap: () => _go(context, '/account'),
      //       ),
      //     ],
      //   ),
      // ),
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
