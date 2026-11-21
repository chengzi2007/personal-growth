import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// 无坐标轴的迷你曲线，用于简历海报里的成长缩略图
class SparkChart extends StatelessWidget {
  const SparkChart({
    super.key,
    required this.values,
    required this.color,
    this.animate = true,
  });

  final List<double> values;
  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return const SizedBox.shrink();
    }

    final peak = values.reduce((a, b) => a > b ? a : b);
    final maxY = peak <= 1 ? 1.0 : peak * 1.12;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.26),
                  color.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: animate ? const Duration(milliseconds: 420) : Duration.zero,
    );
  }
}
