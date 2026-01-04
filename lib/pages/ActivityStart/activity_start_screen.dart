import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocabuddy/pages/doctor_home_screen.dart';
import 'package:audioplayers/audioplayers.dart';

// ===================================================================
// COLORS (MATCH PREVIOUS UI)
// ===================================================================
const Color _kAccentColor = Color(0xFFFF9500);
const Color _kAccentSoft = Color(0xFFFFE8CC);
const Color _kTextDark = Color(0xFF2D3748);
const Color _kTextMuted = Color(0xFF718096);
const Color _kBg = Color(0xFFFFFBF5);
const Color _kCard = Colors.white;

// ===================================================================
// MODEL FOR WORD ITEMS
// ===================================================================
class WordItem {
  final String word;      // Sinhala word text
  final String imagePath; // Full image path
  final String audioPath; // audioplayers AssetSource path (NO "assets/")

  const WordItem({
    required this.word,
    required this.imagePath,
    required this.audioPath,
  });
}

// ===================================================================
// SCREEN
// ===================================================================
class AntLearningActivity extends StatefulWidget {
  const AntLearningActivity({Key? key}) : super(key: key);

  @override
  State<AntLearningActivity> createState() => _AntLearningActivityState();
}

class _AntLearningActivityState extends State<AntLearningActivity>
    with TickerProviderStateMixin {
  bool _showCorrectFeedback = false;
  bool _showTryAgainFeedback = false;

  late final AnimationController _pulseController;
  late final AudioPlayer _player;

  // ✅ Word list (ADD MORE WORDS HERE)
  final List<WordItem> _words = const [
    WordItem(
      word: "සමනලයා",
      imagePath: "assets/photos/samanalaya.png",
      audioPath: "TestVoice/samanalaya.mp3",
    ),
    WordItem(
      word: "ඌරා",
      imagePath: "assets/photos/pig.png",
      audioPath: "TestVoice/ura.mp3",
    ),
    WordItem(
      word: "අඹ",
      imagePath: "assets/photos/mango.png",
      audioPath: "TestVoice/aba.mp3",
    ),
  ];

  int _currentIndex = 0;

  WordItem get _currentWord => _words[_currentIndex];

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ✅ Listen button plays CURRENT word audio
  Future<void> _handleAudioTap() async {
    setState(() {
      _showCorrectFeedback = false;
      _showTryAgainFeedback = false;
    });

    debugPrint("🔊 Playing audio: ${_currentWord.audioPath}");

    try {
      await _player.stop();
      await _player.play(AssetSource(_currentWord.audioPath));
    } catch (e) {
      debugPrint("❌ Audio play error: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Audio not playing. Check pubspec.yaml + asset path."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMicTap() {
    final isCorrect = DateTime.now().millisecond % 2 == 0;

    setState(() {
      _showCorrectFeedback = isCorrect;
      _showTryAgainFeedback = !isCorrect;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCorrectFeedback = false;
          _showTryAgainFeedback = false;
        });
      }
    });
  }

  // ✅ Previous word
  Future<void> _prevWord() async {
    await _player.stop();
    setState(() {
      _showCorrectFeedback = false;
      _showTryAgainFeedback = false;
      _currentIndex = (_currentIndex - 1 + _words.length) % _words.length;
    });
  }

  // ✅ Next word
  Future<void> _nextWord() async {
    await _player.stop();
    setState(() {
      _showCorrectFeedback = false;
      _showTryAgainFeedback = false;
      _currentIndex = (_currentIndex + 1) % _words.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        scaffoldBackgroundColor: _kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: _kBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          elevation: 0.6,
          shadowColor: Colors.black.withOpacity(0.06),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kTextDark),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            "Practice",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: _kTextDark,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: _kTextDark),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
                      (route) => false,
                );
              },
            )
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isSmall = w < 360;
            final isTablet = w >= 600;

            final scale = (w / 390).clamp(0.90, 1.18);
            final horizontal = isTablet ? 32.0 : (isSmall ? 16.0 : 22.0);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: 18 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(scale: scale),
                    SizedBox(height: 18 * scale),

                    // ✅ Word Image Card with side arrows
                    _WordImageCardWithArrows(
                      scale: scale,
                      imagePath: _currentWord.imagePath,
                      onPrev: _prevWord,
                      onNext: _nextWord,
                    ),

                    SizedBox(height: 18 * scale),

                    // ✅ Word Label (updates automatically)
                    Center(
                      child: _WordLabel(
                        scale: scale,
                        word: _currentWord.word,
                      ),
                    ),

                    SizedBox(height: 20 * scale),

                    _ActionButtons(
                      scale: scale,
                      pulseController: _pulseController,
                      onAudioTap: _handleAudioTap,
                      onMicTap: _handleMicTap,
                    ),

                    SizedBox(height: 18 * scale),

                    _FeedbackSection(
                      scale: scale,
                      showCorrect: _showCorrectFeedback,
                      showTryAgain: _showTryAgainFeedback,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===================================================================
// COMPONENTS
// ===================================================================

class _HeaderCard extends StatelessWidget {
  final double scale;
  const _HeaderCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAccentColor, Color(0xFFFFAD33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: _kAccentColor.withOpacity(0.20),
            blurRadius: 20 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54 * scale,
            height: 54 * scale,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Icon(Icons.mic_rounded,
                color: Colors.white, size: 26 * scale),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "එහෙනම් අපි පටන් ගමු බබා!",
                  style: GoogleFonts.poppins(
                    fontSize: 16.5 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  "වචනය හොදින් අසා නිවරිදිව කතා කරන්න උත්සහ කරන්න",
                  style: GoogleFonts.poppins(
                    fontSize: 12.2 * scale,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Image card WITH side arrows
class _WordImageCardWithArrows extends StatelessWidget {
  final double scale;
  final String imagePath;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WordImageCardWithArrows({
    required this.scale,
    required this.imagePath,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: _kAccentSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18 * scale,
            offset: Offset(0, 10 * scale),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            "පිංතූරය දෙස හොදින් බලන්ඩ",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13 * scale,
              color: _kTextMuted,
            ),
          ),
          SizedBox(height: 14 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),

              Container(
                width: 190 * scale,
                height: 190 * scale,
                decoration: BoxDecoration(
                  color: _kAccentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kAccentSoft, width: 5),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: EdgeInsets.all(18 * scale),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Center(
                          child: Text("🖼️",
                              style: TextStyle(fontSize: 55 * scale)),
                        );
                      },
                    ),
                  ),
                ),
              ),

              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordLabel extends StatelessWidget {
  final double scale;
  final String word;

  const _WordLabel({required this.scale, required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: _kAccentSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18 * scale,
            offset: Offset(0, 10 * scale),
          )
        ],
      ),
      child: Text(
        word,
        style: GoogleFonts.poppins(
          fontSize: 30 * scale, // ✅ smaller for Sinhala
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: _kTextDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final double scale;
  final AnimationController pulseController;
  final VoidCallback onAudioTap;
  final VoidCallback onMicTap;

  const _ActionButtons({
    required this.scale,
    required this.pulseController,
    required this.onAudioTap,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = 64.0 * scale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleActionButton(
          scale: scale,
          size: btnSize,
          label: "වචනය අසන්න",
          icon: Icons.volume_up_rounded,
          color: _kAccentColor,
          onTap: onAudioTap,
          pulseController: pulseController,
        ),
        SizedBox(width: 18 * scale),
        _CircleActionButton(
          scale: scale,
          size: btnSize,
          label: "කතා කරන්න",
          icon: Icons.mic_rounded,
          color: _kTextDark,
          onTap: onMicTap,
          pulseController: pulseController,
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final double scale;
  final double size;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final AnimationController pulseController;

  const _CircleActionButton({
    required this.scale,
    required this.size,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, child) {
            final s = 1 + (pulseController.value * 0.03);
            return Transform.scale(scale: s, child: child);
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.28),
                    blurRadius: 16 * scale,
                    offset: Offset(0, 10 * scale),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28 * scale),
            ),
          ),
        ),
        SizedBox(height: 10 * scale),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5 * scale,
            fontWeight: FontWeight.w600,
            color: _kTextMuted,
          ),
        ),
      ],
    );
  }
}

// ✅ Keep your feedback widgets as-is
class _FeedbackSection extends StatelessWidget {
  final double scale;
  final bool showCorrect;
  final bool showTryAgain;

  const _FeedbackSection({
    required this.scale,
    required this.showCorrect,
    required this.showTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
