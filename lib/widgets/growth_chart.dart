import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../core/scoring_config.dart';
import '../core/theme.dart';

/// 各维度「逐日累计分」折线图
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.dimensions,
    required this.series,
    required this.days,
    this.animate = true,
  });

  final List<DimensionConfig> dimensions;

  /// 维度 key -> 每天一个累计分
  final Map<String, List<double>> series;

  final List<DateTime> days;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final bars = <LineChartBarData>[];
    var peak = 0.0;

    for (final dimension in dimensions) {
      final values = series[dimension.key];
      if (values == null || values.length < 2) continue;
      // 全为 0 的维度不画，避免所有线贴在地轴上
      if (!values.any((value) => value > 0)) continue;

      peak = math.max(peak, values.reduce((a, b) => a > b ? a : b));
      bars.add(
        LineChartBarData(
          spots: [
            for (var i = 0; i < values.length; i++)
              FlSpot(i.toDouble(), values[i]),
          ],
          isCurved: true,
          curveSmoothness: 0.22,
          color: dimension.color,
          barWidth: 2.1,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (bars.isEmpty) {
      return Center(
        child: Text(
          '记录之后，这里会长出曲线',
          style: TextStyle(fontSize: 12, color: AppColors.muted.withOpacity(0.9)),
        ),
      );
    }

    final maxY = peak <= 4 ? 4.0 : peak * 1.18;
    final yInterval = _niceInterval(maxY);
    final labelEvery = days.length <= 7 ? 1 : 5;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (days.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.line,
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
        ),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY + 0.001) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.round().toString(),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                final isLast = index == days.length - 1;
                if (!isLast && index % labelEvery != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    Dates.shortDayLabel(days[index]),
                    style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: bars,
      ),
      duration: animate ? const Duration(milliseconds: 420) : Duration.zero,
    );
  }

  /// 让 Y 轴刻度保持「整数且不密集」
  static double _niceInterval(double maxY) {
    if (maxY <= 4) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 25) return 5;
    if (maxY <= 60) return 10;
    return 20;
  }
}
