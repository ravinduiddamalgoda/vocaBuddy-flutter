import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocabuddy/pages/ActivityStart/activity_start_screen.dart';

// ===================================================================
// COLORS
// ===================================================================
const Color _kAccentColor = Color(0xFFFF9500);
const Color _kAccentSoft = Color(0xFFFFE8CC);
const Color _kTextDark = Color(0xFF2D3748);
const Color _kTextMuted = Color(0xFF718096);
const Color _kBg = Color(0xFFFFFBF5);
const Color _kCard = Colors.white;

// ===================================================================
// DATA MODELS
// ===================================================================
class _SessionActivity {
  final String title;
  final String description;
  final bool isPrimary;
  _SessionActivity(this.title, this.description, {this.isPrimary = false});
}

class _ActivityData {
  final String childName;
  final int totalSessions;

  _ActivityData({
    required this.childName,
    required this.totalSessions,
  });

  static _ActivityData dummy = _ActivityData(
    childName: 'චමල්',
    totalSessions: 24,
  );
}

// ===================================================================
// SCREEN
// ===================================================================
class ActivitySummaryScreen extends StatefulWidget {
  const ActivitySummaryScreen({Key? key}) : super(key: key);

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  bool _isPreviousExpanded = true;
  bool _isTodayExpanded = true;

  final _ActivityData _data = _ActivityData.dummy;

  final List<_SessionActivity> _todayActivities = [
    _SessionActivity(
      'ප්‍රධාන වචන පුහුණු කිරීම',
      '“ක, ග, ත, ද, ප, බ” වැනි සරල ශබ්ද මත අවධානය යොමු කර පැහැදිලි උච්චාරණය 5–8 වාරයකින් පුහුණු කරන්න.',
      isPrimary: true,
    ),
    _SessionActivity(
      'දෘශ්‍ය පද හඳුනාගැනීම',
      'රූප/අයිකන 3–5 පෙන්වා, බබා කියන වචන සටහන් කර නිවැරදි බව සටහන් කරන්න.',
    ),
    _SessionActivity(
      'නැවත බලන්න වචන',
      'පසුගිය සැසි වල වැරදි වූ වචනවලින් 5ක් තෝරා අද යළි පුහුණු කරන්න.',
    ),
    _SessionActivity(
      'කෙටි වාක්‍ය භාවිතය',
      'සරල වාක්‍ය 2–3ක් හරහා සම්බන්ධ වචන හා නාද සංගතය පරීක්ෂා කරන්න.',
    ),
  ];

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

        // ✅ AppBar with Back button
        appBar: AppBar(
          elevation: 0.6,
          shadowColor: Colors.black.withOpacity(0.06),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kTextDark),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            "Activity Summary",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: _kTextDark,
            ),
          ),
        ),

        body: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isSmall = w < 360;
            final isTablet = w >= 600;

            final horizontal = isTablet ? 32.0 : (isSmall ? 16.0 : 22.0);
            final vertical = isTablet ? 22.0 : 18.0;
            final scale = (w / 390).clamp(0.90, 1.18);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderCard(
                        childName: _data.childName,
                        scale: scale,
                      ),
                      SizedBox(height: 18 * scale),

                      // ✅ Only Total Sessions Card (accuracy removed)
                      _SessionStatsCard(
                        totalSessions: _data.totalSessions,
                        scale: scale,
                      ),

                      SizedBox(height: 14 * scale),

                      _CollapsibleCard(
                        isExpanded: _isPreviousExpanded,
                        onToggle: () => setState(() => _isPreviousExpanded = !_isPreviousExpanded),
                        themeColor: _kTextMuted,
                        icon: Icons.history_edu_rounded,
                        title: 'පසුගිය ක්‍රියාකාරකම් සාරාංශය',
                        subtitle: 'පසුගිය සැසි වල ප්‍රගතිය හා වෘත්තීය සටහන් බලන්න.',
                        child: const _PreviousSummaryContent(),
                        scale: scale,
                      ),

                      SizedBox(height: 12 * scale),

                      _CollapsibleCard(
                        isExpanded: _isTodayExpanded,
                        onToggle: () => setState(() => _isTodayExpanded = !_isTodayExpanded),
                        themeColor: _kAccentColor,
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'අද කළ යුතු නිර්දේශිත ක්‍රියාකාරකම්',
                        subtitle: 'අද සෙෂන් සඳහා වෘත්තීය පුහුණු නිර්දේශ.',
                        child: _TodayPlanContent(activities: _todayActivities),
                        scale: scale,
                      ),

                      SizedBox(height: 18 * scale),

                      _PrimaryButton(
                        label: 'ආරම්භ කරන්න',
                        scale: scale,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AntLearningActivity()),
                          );
                        },
                      ),

                      SizedBox(height: 10 * scale),
                    ],
                  ),
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
// WIDGETS
// ===================================================================

class _HeaderCard extends StatelessWidget {
  final String childName;
  final double scale;

  const _HeaderCard({required this.childName, required this.scale});

  @override
  Widget build(BuildContext context) {
    final iconSize = 26.0 * scale;
    final boxSize = 54.0 * scale;

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
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Icon(Icons.bar_chart_rounded, color: Colors.white, size: iconSize),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Child Activity Summary",
                  style: GoogleFonts.poppins(
                    fontSize: 16.5 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  "$childName ගේ කථන පුහුණු ප්‍රගතිය මෙහිදී නිරීක්ෂණය කළ හැක.",
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

class _SessionStatsCard extends StatelessWidget {
  final int totalSessions;
  final double scale;

  const _SessionStatsCard({
    required this.totalSessions,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: _kAccentSoft, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18 * scale,
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
              color: _kAccentSoft,
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Icon(Icons.event_note_rounded,
                color: _kAccentColor, size: 26 * scale),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "මුළු සැසි",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5 * scale,
                    fontWeight: FontWeight.w600,
                    color: _kTextMuted,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  "$totalSessions",
                  style: GoogleFonts.poppins(
                    fontSize: 30 * scale,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
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

class _CollapsibleCard extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color themeColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final double scale;

  const _CollapsibleCard({
    required this.isExpanded,
    required this.onToggle,
    required this.themeColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          InkWell(
            borderRadius: BorderRadius.circular(18 * scale),
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.all(14 * scale),
              child: Row(
                children: [
                  Container(
                    width: 44 * scale,
                    height: 44 * scale,
                    decoration: BoxDecoration(
                      color: _kAccentSoft,
                      borderRadius: BorderRadius.circular(14 * scale),
                    ),
                    child: Icon(icon, color: themeColor, size: 22 * scale),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.2 * scale,
                            color: _kTextDark,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: 12 * scale,
                            color: _kTextMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: themeColor,
                      size: 28 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
              padding: EdgeInsets.fromLTRB(14 * scale, 0, 14 * scale, 14 * scale),
              child: child,
            )
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;

  const _KVRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12.5, color: _kTextMuted),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kAccentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousSummaryContent extends StatelessWidget {
  const _PreviousSummaryContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _KVRow('අවසාන සැසියේ වචන සංඛ්‍යාව', '28'),
        const _KVRow('නිවැරදි උච්චාරණ අනුපාතය', '82%'),
        const _KVRow('නැවත පුහුණු කළ යුතු වචන', '5'),
        const SizedBox(height: 14),
        Text(
          "වෘත්තීය සටහන (Therapist Note)",
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.black.withOpacity(0.06), height: 16),
        Text(
          '“ර”, “ස”, “ශ” සම්බන්ධ නාද සඳහා තවදුරටත් මෘදු මගපෙන්වීම් අවශ්‍යයි. '
              'සෙනෙහසින් යුත් පුහුණු පරිසරයක් තුළ පියවරෙන් පියවර ඉදිරියට යන්න.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: _kTextMuted,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _TodoItem extends StatelessWidget {
  final _SessionActivity activity;
  const _TodoItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final bg = activity.isPrimary ? _kAccentSoft : Colors.transparent;
    final border = activity.isPrimary ? _kAccentColor : _kAccentSoft;
    final icon =
    activity.isPrimary ? Icons.star_rounded : Icons.check_circle_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kAccentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _kTextMuted,
                    height: 1.5,
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

class _TodayPlanContent extends StatelessWidget {
  final List<_SessionActivity> activities;
  const _TodayPlanContent({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: activities.map((a) => _TodoItem(activity: a)).toList(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double scale;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kAccentColor,
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15.3 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 10 * scale),
            Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20 * scale),
          ],
        ),
      ),
    );
  }
}
