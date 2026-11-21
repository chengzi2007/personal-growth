import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../core/scoring_config.dart';
import '../core/theme.dart';
import '../data/growth_store.dart';
import '../widgets/paper_card.dart';
import '../widgets/section_title.dart';
import 'dimension_detail_screen.dart';
import 'record_editor_screen.dart';

/// 首页仪表盘：日期寄语 + 六维总分网格 + 记一笔
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GrowthStore>();
    final config = store.config;
    final now = DateTime.now();
    final scores = store.dimensionScores;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    now: now,
                    totalScore: store.totalScore,
                    streak: store.currentStreak,
                  ),
                  const SizedBox(height: 20),
                  _QuoteCard(quote: config.quoteFor(now)),
                  const SizedBox(height: 22),
                  SectionTitle(
                    title: '价值维度',
                    trailing: Text(
                      '今日 +${store.todayScore}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: config.dimensions.length,
                    itemBuilder: (context, index) {
                      final dimension = config.dimensions[index];
                      return _DimensionTile(
                        dimension: dimension,
                        score: scores[dimension.key] ?? 0,
                        todayGain: store.todayScoreOf(dimension.key),
                        onTap: () => _openDimension(context, dimension.key),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 15, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        store.todayCount == 0
                            ? '今天还没有记录，从第一笔开始'
                            : '今天已记录 ${store.todayCount} 笔 · 连续 ${store.currentStreak} 天',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _AddRecordButton(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RecordEditorScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDimension(BuildContext context, String dimensionKey) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DimensionDetailScreen(dimensionKey: dimensionKey),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.now,
    required this.totalScore,
    required this.streak,
  });

  final DateTime now;
  final int totalScore;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${now.year} · ${Dates.monthDayLabel(now)} · ${Dates.weekdayLabel(now)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.overline.copyWith(letterSpacing: 1.4),
              ),
              const SizedBox(height: 8),
              Text('个人成长', style: AppTheme.display(size: 30)),
              const SizedBox(height: 6),
              const Text(
                '每一次记录，都是一次累积',
                style: TextStyle(fontSize: 12, color: AppColors.muted, letterSpacing: 0.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 3),
                Text(
                  '$streak 天',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$totalScore',
              style: AppTheme.display(size: 32, color: AppColors.accent),
            ),
            const Text(
              '累计成长值',
              style: TextStyle(fontSize: 9.5, color: AppColors.muted, letterSpacing: 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      color: AppColors.cardWarm,
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2.5,
            height: 44,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今日寄语', style: AppTheme.overline),
                const SizedBox(height: 8),
                Text(
                  quote,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontFamilyFallback: ['Noto Serif', 'Source Han Serif SC', 'Songti SC'],
                    fontSize: 15,
                    height: 1.65,
                    color: AppColors.inkSoft,
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

class _DimensionTile extends StatelessWidget {
  const _DimensionTile({
    required this.dimension,
    required this.score,
    required this.todayGain,
    required this.onTap,
  });

  final DimensionConfig dimension;
  final int score;
  final int todayGain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: dimension.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(dimension.icon, size: 14, color: dimension.color),
              ),
              const Spacer(),
              if (todayGain > 0)
                Text(
                  '+$todayGain',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: dimension.color,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            dimension.name,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text('$score', style: AppTheme.display(size: 24)),
        ],
      ),
    );
  }
}

class _AddRecordButton extends StatelessWidget {
  const _AddRecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              '记一笔',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
