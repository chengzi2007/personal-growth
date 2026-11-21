import '../core/dates.dart';
import '../core/scoring_config.dart';
import '../models/growth_record.dart';

/// 打分引擎：把「维度 + 重要程度」换算成分数，并计算额外奖励。
///
/// 规则全部来自 AppConfig：
/// - 学习 / 技能 / 生活 / 健康 / 社交：低 1、中 2、高 3
/// - 证书：低 5、中 8、高 10
/// - 学习连续每天打卡：额外 +1/天
class ScoreEngine {
  ScoreEngine(this.config);

  final AppConfig config;

  int basePoints(String dimensionKey, String levelKey) =>
      config.dimension(dimensionKey)?.pointsFor(levelKey) ?? 0;

  /// 连续打卡奖励（只对 streakDimension 生效）。
  ///
  /// 语义：昨天存在该维度的记录，说明打卡没有中断，今天这条记录额外 +N；
  /// 同一天只奖励一次（当天已记录过则不再叠加），避免一条条刷分。
  int streakBonus(
    List<GrowthRecord> records,
    String dimensionKey,
    DateTime day,
  ) {
    if (dimensionKey != config.streakDimension) return 0;
    if (config.streakBonusPerDay <= 0) return 0;

    final todayKey = Dates.ymd(day);
    final hasToday = records.any(
      (r) => r.dimensionKey == config.streakDimension && r.dayKey == todayKey,
    );
    if (hasToday) return 0;

    final yesterdayKey = Dates.ymd(Dates.addDays(day, -1));
    final hasYesterday = records.any(
      (r) => r.dimensionKey == config.streakDimension && r.dayKey == yesterdayKey,
    );
    return hasYesterday ? config.streakBonusPerDay : 0;
  }

  /// 记录页的实时预览分
  int previewTotal(
    List<GrowthRecord> records, {
    required String dimensionKey,
    required String levelKey,
    DateTime? day,
  }) {
    final target = day ?? DateTime.now();
    return basePoints(dimensionKey, levelKey) +
        streakBonus(records, dimensionKey, target);
  }
}
