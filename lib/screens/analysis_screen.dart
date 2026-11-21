import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/scoring_config.dart';
import '../core/theme.dart';
import '../data/growth_store.dart';
import '../services/analytics.dart';
import '../widgets/growth_chart.dart';
import '../widgets/paper_card.dart';
import '../widgets/section_title.dart';
import 'dimension_detail_screen.dart';

/// 分析页：近 7 天 / 30 天曲线 + 维度排行榜
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GrowthStore>();
    final config = store.config;
    final scores = store.dimensionScores;

    final days = Analytics.window(_range);
    final series = Analytics.cumulativeSeries(
      records: store.records,
      dimensions: config.dimensions,
      days: days,
    );

    final ranking = [...config.dimensions]
      ..sort((a, b) => (scores[b.key] ?? 0).compareTo(scores[a.key] ?? 0));
    final maxScore = ranking.isEmpty ? 0 : (scores[ranking.first.key] ?? 0);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ANALYSIS', style: AppTheme.overline),
                      const SizedBox(height: 6),
                      Text('成长分析', style: AppTheme.display(size: 26)),
                    ],
                  ),
                ),
                _RangeToggle(
                  value: _range,
                  onChanged: (value) => setState(() => _range = value),
                ),
              ],
            ),
            const SizedBox(height: 18),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '各维度累计曲线',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '近 $_range 天 · 单位：分',
                        style: const TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 210,
                    child: GrowthChart(
                      key: ValueKey<int>(_range),
                      dimensions: config.dimensions,
                      series: series,
                      days: days,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final dimension in config.dimensions)
                        _LegendDot(dimension: dimension),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(
              title: '维度排行榜',
              trailing: const Text(
                '按累计分排序',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 10),
            PaperCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < ranking.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 26, endIndent: 4),
                    _RankRow(
                      index: i,
                      dimension: ranking[i],
                      score: scores[ranking[i].key] ?? 0,
                      maxScore: maxScore,
                      onTap: () => _openDetail(context, ranking[i].key),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                '点击任意维度，查看它的历史明细',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted, letterSpacing: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String dimensionKey) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DimensionDetailScreen(dimensionKey: dimensionKey),
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill('7 天', 7),
          _pill('30 天', 30),
        ],
      ),
    );
  }

  Widget _pill(String label, int days) {
    final selected = value == days;
    return GestureDetector(
      onTap: () => onChanged(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.dimension});

  final DimensionConfig dimension;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dimension.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          dimension.name,
          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.index,
    required this.dimension,
    required this.score,
    required this.maxScore,
    required this.onTap,
  });

  final int index;
  final DimensionConfig dimension;
  final int score;
  final int maxScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0).toDouble();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${index + 1}'.padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dimension.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  dimension.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text('$score', style: AppTheme.display(size: 19)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 3,
                backgroundColor: AppColors.line.withOpacity(0.55),
                valueColor: AlwaysStoppedAnimation<Color>(dimension.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
