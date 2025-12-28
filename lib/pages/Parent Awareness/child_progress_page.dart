// child_progress_page.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ChildProgressPage extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildProgressPage({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildProgressPage> createState() => _ChildProgressPageState();
}

class _ChildProgressPageState extends State<ChildProgressPage>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;
  AnimationController? _donutAnimationController;
  Animation<double>? _donutAnimation;
  bool _hasAnimated = false;
  final GlobalKey _barChartKey = GlobalKey();

  // Sample data for charts
  final List<Map<String, dynamic>> progressData = [
    {'week': 'සතිය 1', 'accuracy': 60},
    {'week': 'සතිය 2', 'accuracy': 65},
    {'week': 'සතිය 3', 'accuracy': 72},
    {'week': 'සතිය 4', 'accuracy': 78},
  ];

  final List<Map<String, dynamic>> categoryData = [
    {'category': 'S ශබ්ද', 'score': 85, 'color': Color(0xFF22C55E), 'level': 'විශිෂ්ටයි'},
    {'category': 'R ශබ්ද', 'score': 75, 'color': Color(0xFF3B82F6), 'level': 'හොඳයි'},
    {'category': 'T ශබ්ද', 'score': 60, 'color': Color(0xFFFF9800), 'level': 'සාමාන්‍යයි'},
    {'category': 'K ශබ්ද', 'score': 45, 'color': Color(0xFFEF4444), 'level': 'පුහුණුවීම අවශ්‍යයි'},
    {'category': 'N ශබ්ද', 'score': 78, 'color': Color(0xFF3B82F6), 'level': 'හොඳයි'},
  ];

  @override
  void initState() {
    super.initState();

    // Animation for donut chart - starts immediately
    _donutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _donutAnimation = CurvedAnimation(
      parent: _donutAnimationController!,
      curve: Curves.easeInOutCubic,
    );
    _donutAnimationController!.forward();

    // Animation for bar chart - triggered on scroll
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic,
    );

    // Check visibility after a short delay to ensure layout is complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _checkBarChartVisibility();
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _donutAnimationController?.dispose();
    super.dispose();
  }

  void _checkBarChartVisibility() {
    if (_hasAnimated || !mounted) return;

    try {
      final RenderBox? renderBox = _barChartKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      final chartHeight = renderBox.size.height;

      // Check if at least 30% of the chart is visible
      final visibleTop = math.max(0.0, position.dy);
      final visibleBottom = math.min(screenHeight, position.dy + chartHeight);
      final visibleHeight = visibleBottom - visibleTop;

      if (visibleHeight > chartHeight * 0.3) {
        setState(() {
          _hasAnimated = true;
        });
        _animationController!.forward();
      }
    } catch (e) {
      // Ignore errors during layout
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.childData;
    final double completionRate = (child['sessions'] / child['totalSessions']) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B), size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            _checkBarChartVisibility();
          }
          return false;
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with child info
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF9800), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          child['name'][0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child['name'],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'වයස ${child['age']} • ප්‍රගති විශ්ලේෂණ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Session Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDonutStatCard(
                        'පාඩම් සම්පූර්ණ කිරීම',
                        completionRate,
                        '${child['sessions']}/${child['totalSessions']} සම්පූර්ණයි',
                        Icons.check_circle_outline,
                        const Color(0xFF64748B),
                        Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'සාමාන්‍ය ලකුණු',
                        '${child['accuracy']}%',
                        'සමස්ත නිවැරදි බව',
                        Icons.star_outline,
                        const Color(0xFF64748B),
                        Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Over Time Chart
                _buildChartCard(
                  title: 'කාලයත් සමග ප්‍රගතිය',
                  subtitle: 'උච්චාරණ නිවැරදි බව වැඩි දියුණුව',
                  icon: Icons.show_chart,
                  child: _buildLineChart(),
                ),
                const SizedBox(height: 16),

                // Word Category Performance
                Container(
                  key: _barChartKey,
                  child: _buildChartCard(
                    title: 'වචන කාණ්ඩ ප්‍රගතිය',
                    subtitle: 'ශබ්ද කණ්ඩායම් අනුව කාර්ය සාධනය',
                    icon: Icons.bar_chart,
                    child: _buildBarChart(),
                  ),
                ),
                const SizedBox(height: 16),

                // Insights Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF64748B),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ප්‍රධාන කරුණු',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInsightItem(
                        Icons.trending_up,
                        'විශිෂ්ට ප්‍රගතියක්!',
                        'සති 4 කින් නිවැරදි බව 18% කින් වැඩි වී ඇත.',
                      ),
                      const SizedBox(height: 12),
                      _buildInsightItem(
                        Icons.check_circle,
                        'හොඳම ක්ෂේත්‍රය',
                        'S ශබ්ද 85% ක විශිෂ්ට ප්‍රගතියක් පෙන්වයි.',
                      ),
                      const SizedBox(height: 12),
                      _buildInsightItem(
                        Icons.flag,
                        'අවධානය යොමු කරන්න',
                        'K ශබ්දවලට වැඩි පුහුණුවීමක් අවශ්‍යයි.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF64748B),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: _LineChartPainter(progressData),
        child: Container(),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxScore = 100; // Use 100 as max for percentage-based display

    return Column(
      children: [
        ...categoryData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final score = data['score'] as int;
          final width = score.toDouble(); // Direct percentage

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['category'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    _animation != null
                        ? AnimatedBuilder(
                      animation: _animation!,
                      builder: (context, child) {
                        final delay = index * 0.15;
                        final adjustedProgress = math.max(
                          0.0,
                          math.min(1.0, (_animation!.value - delay) / (1.0 - delay)),
                        );
                        return Text(
                          '${(score * adjustedProgress).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: data['color'],
                          ),
                        );
                      },
                    )
                        : Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: data['color'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    _animation != null
                        ? AnimatedBuilder(
                      animation: _animation!,
                      builder: (context, child) {
                        final delay = index * 0.15;
                        final adjustedProgress = math.max(
                          0.0,
                          math.min(1.0, (_animation!.value - delay) / (1.0 - delay)),
                        );
                        return FractionallySizedBox(
                          widthFactor: (width / 100) * adjustedProgress,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  data['color'].withOpacity(0.7),
                                  data['color'],
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: data['color'].withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                        : FractionallySizedBox(
                      widthFactor: width / 100,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              data['color'].withOpacity(0.7),
                              data['color'],
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: data['color'].withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'කාර්ය සාධන මට්ටම්',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildLegendItem('විශිෂ්ටයි', const Color(0xFF22C55E), '80-100%'),
                  _buildLegendItem('හොඳයි', const Color(0xFF3B82F6), '70-79%'),
                  _buildLegendItem('සාමාන්‍යයි', const Color(0xFFFF9800), '50-69%'),
                  _buildLegendItem('පුහුණුවීම අවශ්‍යයි', const Color(0xFFEF4444), '0-49%'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($range)',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutStatCard(
      String title,
      double percentage,
      String subtitle,
      IconData icon,
      Color iconColor,
      Color bgColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: _donutAnimation != null
                ? AnimatedBuilder(
              animation: _donutAnimation!,
              builder: (context, child) {
                return SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      percentage: percentage * _donutAnimation!.value,
                      color: iconColor,
                      backgroundColor: const Color(0xFFF8FAFC),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(percentage * _donutAnimation!.value).toInt()}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'සම්පූර්ණයි',
                            style: TextStyle(
                              fontSize: 11,
                              color: iconColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
                : const SizedBox(
              width: 120,
              height: 120,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color iconColor,
      Color bgColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'සාමාන්‍ය',
                  style: TextStyle(
                    fontSize: 11,
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF64748B),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAccuracy = data.map((d) => d['accuracy'] as int).reduce(math.max);
    final minAccuracy = data.map((d) => d['accuracy'] as int).reduce(math.min);
    final range = maxAccuracy - minAccuracy;

    final chartHeight = size.height - 50;
    final chartWidth = size.width - 40;
    final leftPadding = 20.0;
    final topPadding = 30.0;

    final linePaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );
    }

    final linePath = Path();
    final stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + i * stepX;
      final normalizedValue = range > 0
          ? (data[i]['accuracy'] - minAccuracy) / range
          : 0.5;
      final y = topPadding + chartHeight - (normalizedValue * chartHeight);

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    canvas.drawPath(linePath, linePaint);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + i * stepX;
      final normalizedValue = range > 0
          ? (data[i]['accuracy'] - minAccuracy) / range
          : 0.5;
      final y = topPadding + chartHeight - (normalizedValue * chartHeight);

      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = const Color(0xFFFF9800)
          ..style = PaintingStyle.fill,
      );

      textPainter.text = TextSpan(
        text: '${data[i]['accuracy']}%',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFF9800),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - 22),
      );

      textPainter.text = TextSpan(
        text: data[i]['week'].toString().replaceAll('සතිය ', 'ස'),
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF94A3B8),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topPadding + chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 12.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}