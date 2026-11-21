import '../core/dates.dart';
import '../core/scoring_config.dart';
import '../models/growth_record.dart';

/// 分析页的数据计算：按日累计形成成长曲线。
class Analytics {
  Analytics._();

  /// 近 [days] 天的自然日列表（升序，含今天）
  static List<DateTime> window(int days) => Dates.recentDays(days);

  /// 每个维度逐日累计分。
  ///
  /// 累计值包含区间之前的历史记录，所以曲线是「一直往上走」的成长曲线，
  /// 而不是只有区间内的增量。
  static Map<String, List<double>> cumulativeSeries({
    required List<GrowthRecord> records,
    required List<DimensionConfig> dimensions,
    required List<DateTime> days,
  }) {
    final result = <String, List<double>>{};
    for (final dimension in dimensions) {
      final own = records.where((r) => r.dimensionKey == dimension.key).toList();
      final values = <double>[];
      for (final day in days) {
        final end = Dates.addDays(day, 1);
        var sum = 0;
        for (final record in own) {
          if (record.createdTime.isBefore(end)) {
            sum += record.totalPoints;
          }
        }
        values.add(sum.toDouble());
      }
      result[dimension.key] = values;
    }
    return result;
  }

  /// 全部维度的逐日累计总分（简历页缩略图用）
  static List<double> totalSeries({
    required List<GrowthRecord> records,
    required List<DateTime> days,
  }) {
    return List<double>.generate(days.length, (index) {
      final end = Dates.addDays(days[index], 1);
      var sum = 0;
      for (final record in records) {
        if (record.createdTime.isBefore(end)) {
          sum += record.totalPoints;
        }
      }
      return sum.toDouble();
    });
  }

  /// 某天的记录条数
  static int countOnDay(List<GrowthRecord> records, DateTime day) {
    final key = Dates.ymd(day);
    return records.where((r) => r.dayKey == key).length;
  }
}
