import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocabuddy/pages/activitySummaryScreen/activity_summary_page.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final AnimationController _listController;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    )..forward();

    _listController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward(from: 0.2);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF2D3748),
    );

    final subtitleStyle = GoogleFonts.poppins(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF718096),
      height: 1.6,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),

      /// ✅ Professional AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF5),
        elevation: 0.6,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.06),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Instructions",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: const Color(0xFF2D3748),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ✅ Header card (Premium)
                FadeTransition(
                  opacity: _headerController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.12),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _headerController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: _buildPremiumHeader(),
                  ),
                ),

                const SizedBox(height: 26),

                /// ✅ Title + Subtitle
                FadeTransition(
                  opacity: _listController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('එහෙනම් පටන් ගමු !', style: titleStyle),
                      const SizedBox(height: 8),
                      Text(
                        'පටන් ගන්න පහත පියවරයන් අනුගමනය කරන්න',
                        style: subtitleStyle,
                      ),
                      const SizedBox(height: 16),

                      /// ✅ Progress
                      _buildProgressIndicator(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// ✅ Steps list (Professional Cards)
                FadeTransition(
                  opacity: _listController,
                  child: Column(
                    children: const [
                      _StepCard(
                        step: "01",
                        title: "පිංතූරය හොදින් බලන්න",
                        description: "Look carefully at the picture displayed.",
                        icon: Icons.visibility_rounded,
                      ),
                      SizedBox(height: 14),
                      _StepCard(
                        step: "02",
                        title: "පටිගත කිරීම සක්‍රිය කරන්න",
                        description: "Tap the microphone when you’re ready.",
                        icon: Icons.mic_rounded,
                      ),
                      SizedBox(height: 14),
                      _StepCard(
                        step: "03",
                        title: "පැහැදිලිව කථා කරන්න",
                        description: "Pronounce the word loud and clear.",
                        icon: Icons.record_voice_over_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                /// ✅ Professional Start Button
                _buildPrimaryButton(),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9500), Color(0xFFFFAD33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9500).withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Speech Buddy",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "සිංහල Interactive Learning Platform",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8CC),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 120,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Step 1 of 3",
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFFF9500),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ActivitySummaryScreen(),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "පටන් ගන්න",
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// STEP CARD (PROFESSIONAL)
/// =======================
class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE8CC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          /// Step number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF9500),
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF718096),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF9500),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
