// child_progress_page.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ChildProgressPage extends StatefulWidget {
  final Map<String, dynamic> childData;

  const ChildProgressPage({Key? key, required this.childData}) : super(key: key);

  @override
  State<ChildProgressPage> createState() => _ChildProgressPageState();
}

class _ChildProgressPageState extends State<ChildProgressPage> {
  String selectedTimeRange = 'Last 4 Weeks';
  final List<String> timeRanges = ['Last 4 Weeks', 'Last 8 Weeks', 'Last 12 Weeks'];

  // Sample data for charts
  final List<Map<String, dynamic>> progressData = [
    {'week': 'Week 1', 'accuracy': 60},
    {'week': 'Week 2', 'accuracy': 65},
    {'week': 'Week 3', 'accuracy': 72},
    {'week': 'Week 4', 'accuracy': 78},
  ];

  final List<Map<String, dynamic>> categoryData = [
    {'category': 'Vowels', 'score': 85, 'color': Color(0xFF22C55E)},
    {'category': 'S Sounds', 'score': 75, 'color': Color(0xFFFF9800)},
    {'category': 'R Sounds', 'score': 60, 'color': Color(0xFFEF4444)},
    {'category': 'T Sounds', 'score': 80, 'color': Color(0xFF3B82F6)},
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

              // Time Range Selector
              Container(
                padding: const EdgeInsets.all(4),
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
                child: Row(
                  children: timeRanges.map((range) {
                    final isSelected = selectedTimeRange == range;
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => selectedTimeRange = range),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF4E6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            range.replaceAll('Last ', ''),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFFFF9800) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

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

              // Session Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Session Completion',
                      '${completionRate.toInt()}%',
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

              // Average Score Trend
              _buildChartCard(
                title: 'Average Score Trend',
                subtitle: 'Overall performance across activities',
                icon: Icons.trending_up,
                child: _buildAreaChart(),
              ),
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
                      'Vowel sounds show excellent performance at 85%.',
                    ),
                    const SizedBox(height: 12),
                    _buildInsightItem(
                      '💪',
                      'Focus Area',
                      'R sounds need more practice. Consider additional exercises.',
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
    final maxAccuracy = progressData.map((d) => d['accuracy'] as int).reduce(math.max);

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(progressData.length, (index) {
          final data = progressData[index];
          final accuracy = data['accuracy'] as int;
          final height = (accuracy / maxAccuracy) * 160;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$accuracy%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['week'].toString().replaceAll('Week ', 'W'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxScore = categoryData.map((d) => d['score'] as int).reduce(math.max);

    return Column(
      children: categoryData.map((data) {
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
    );
  }

  Widget _buildAreaChart() {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: AreaChartPainter(progressData),
        child: Container(),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
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

class AreaChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  AreaChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFF9800).withOpacity(0.3),
          const Color(0xFFFF9800).withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final linePath = Path();

    final maxAccuracy = data.map((d) => d['accuracy'] as int).reduce(math.max);
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height);
    linePath.moveTo(0, size.height - (data[0]['accuracy'] / maxAccuracy * size.height));

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i]['accuracy'] / maxAccuracy * size.height);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(linePath, linePaint);

    // Draw points
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i]['accuracy'] / maxAccuracy * size.height);

      canvas.drawCircle(
        Offset(x, y),
        5,
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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}