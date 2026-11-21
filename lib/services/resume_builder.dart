import '../core/dates.dart';
import '../core/scoring_config.dart';
import '../data/growth_store.dart';
import 'analytics.dart';

/// 一条「高光成就」，如：证书 × 3
class Achievement {
  const Achievement({
    required this.dimension,
    required this.count,
    required this.score,
  });

  final DimensionConfig dimension;

  /// 高重要程度记录条数
  final int count;

  /// 该维度累计分
  final int score;
}

/// 简历页需要的全部数据快照。
/// 单独抽出来是为了让海报可以脱离 Provider 树被离线渲染成图片。
class ResumeData {
  const ResumeData({
    required this.nickname,
    required this.activeDays,
    required this.recordCount,
    required this.totalScore,
    required this.streak,
    required this.dimensions,
    required this.scores,
    required this.achievements,
    required this.days,
    required this.curve,
    required this.generatedLabel,
  });

  final String nickname;
  final int activeDays;
  final int recordCount;
  final int totalScore;
  final int streak;
  final List<DimensionConfig> dimensions;
  final Map<String, int> scores;
  final List<Achievement> achievements;
  final List<DateTime> days;
  final List<double> curve;
  final String generatedLabel;

  factory ResumeData.fromStore(GrowthStore store) {
    final scores = store.dimensionScores;
    final days = Analytics.window(30);

    final achievements = <Achievement>[];
    for (final dimension in store.config.dimensions) {
      final count = store.highLevelCount(dimension.key);
      if (count == 0) continue;
      achievements.add(
        Achievement(
          dimension: dimension,
          count: count,
          score: scores[dimension.key] ?? 0,
        ),
      );
    }
    achievements.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : b.score.compareTo(a.score);
    });

    return ResumeData(
      nickname: store.nickname,
      activeDays: store.activeDays,
      recordCount: store.recordCount,
      totalScore: store.totalScore,
      streak: store.currentStreak,
      dimensions: store.config.dimensions,
      scores: scores,
      achievements: achievements,
      days: days,
      curve: Analytics.totalSeries(records: store.records, days: days),
      generatedLabel: '生成于 ${Dates.ymd(DateTime.now())}',
    );
  }
}
