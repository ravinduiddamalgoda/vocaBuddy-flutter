// child_progress_page.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ChildProgressPage extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildProgressPage({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildProgressPage> createState() => _ChildProgressPageState();
}

class _ChildProgressPageState extends State<ChildProgressPage> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;

  // Sample data for charts
  final List<Map<String, dynamic>> progressData = [
    {'week': 'Week 1', 'accuracy': 60},
    {'week': 'Week 2', 'accuracy': 65},
    {'week': 'Week 3', 'accuracy': 72},
    {'week': 'Week 4', 'accuracy': 78},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic,
    );
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> categoryData = [
    {'category': 'S Sounds', 'score': 85, 'color': Color(0xFF22C55E), 'level': 'Excellent'},
    {'category': 'R Sounds', 'score': 75, 'color': Color(0xFF3B82F6), 'level': 'Good'},
    {'category': 'T Sounds', 'score': 60, 'color': Color(0xFFFF9800), 'level': 'Fair'},
    {'category': 'K Sounds', 'score': 45, 'color': Color(0xFFEF4444), 'level': 'Needs Practice'},
    {'category': 'N Sounds', 'score': 78, 'color': Color(0xFF3B82F6), 'level': 'Good'},
  ];

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
      body: SingleChildScrollView(
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        child['name'][0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                          'Age ${child['age']} • Progress Analytics',
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
                      'Session Completion',
                      completionRate,
                      '${child['sessions']}/${child['totalSessions']} completed',
                      Icons.check_circle_outline,
                      const Color(0xFF22C55E),
                      const Color(0xFFF0FDF4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Average Score',
                      '${child['accuracy']}%',
                      'Overall accuracy',
                      Icons.star_outline,
                      const Color(0xFFFF9800),
                      const Color(0xFFFFF4E6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Over Time Chart
              _buildChartCard(
                title: 'Progress Over Time',
                subtitle: 'Pronunciation accuracy improvement',
                icon: Icons.show_chart,
                child: _buildLineChart(),
              ),
              const SizedBox(height: 16),

              // Word Category Performance
              _buildChartCard(
                title: 'Word Category Performance',
                subtitle: 'Performance by phoneme groups',
                icon: Icons.bar_chart,
                child: _buildBarChart(),
              ),
              const SizedBox(height: 16),

              // Session Stats Row (moved below)
              const SizedBox(height: 16),

              // Insights Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFFFF9800),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Key Insights',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInsightItem(
                      '📈',
                      'Great Progress!',
                      'Pronunciation accuracy improved by 18% in 4 weeks.',
                    ),
                    const SizedBox(height: 12),
                    _buildInsightItem(
                      '🎯',
                      'Strong Area',
                      'S sounds show excellent performance at 85%.',
                    ),
                    const SizedBox(height: 12),
                    _buildInsightItem(
                      '💪',
                      'Focus Area',
                      'K sounds need more practice. Consider additional exercises.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFF9800),
                  size: 24,
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
    final maxScore = categoryData.map((d) => d['score'] as int).reduce(math.max);

    return Column(
      children: [
        ...categoryData.map((data) {
          final score = data['score'] as int;
          final width = (score / maxScore) * 100;

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
                    Text(
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
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: width / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: data['color'],
                          borderRadius: BorderRadius.circular(4),
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
        // Performance level legend
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Levels',
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
                  _buildLegendItem('Excellent', const Color(0xFF22C55E), '80-100%'),
                  _buildLegendItem('Good', const Color(0xFF3B82F6), '70-79%'),
                  _buildLegendItem('Fair', const Color(0xFFFF9800), '50-69%'),
                  _buildLegendItem('Needs Practice', const Color(0xFFEF4444), '0-49%'),
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
            child: _animation != null
                ? AnimatedBuilder(
              animation: _animation!,
              builder: (context, child) {
                return SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      percentage: percentage * _animation!.value,
                      color: iconColor,
                      backgroundColor: bgColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(percentage * _animation!.value).toInt()}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete',
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
                  'Average',
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

  Widget _buildInsightItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
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

    // Add padding to the chart
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

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );
    }

    // Draw line path
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

    // Draw points and labels
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

      // Draw outer white circle
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // Draw inner orange circle
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = const Color(0xFFFF9800)
          ..style = PaintingStyle.fill,
      );

      // Draw value label above point
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

      // Draw week label below chart
      textPainter.text = TextSpan(
        text: data[i]['week'].toString().replaceAll('Week ', 'W'),
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

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2, // Start from top
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