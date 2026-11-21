import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dates.dart';
import '../core/scoring_config.dart';
import '../core/theme.dart';
import '../data/growth_store.dart';
import '../models/growth_record.dart';
import '../widgets/paper_card.dart';
import '../widgets/section_title.dart';

/// 维度明细（分析页 -> 点击维度进入）
class DimensionDetailScreen extends StatelessWidget {
  const DimensionDetailScreen({super.key, required this.dimensionKey});

  final String dimensionKey;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GrowthStore>();
    final dimension = store.config.dimension(dimensionKey);
    final records = store.recordsOf(dimensionKey);
    final accent = dimension?.color ?? AppColors.accent;

    return Scaffold(
      appBar: AppBar(title: Text(dimension?.name ?? '维度明细')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _SummaryHeader(
            dimension: dimension,
            totalScore: store.scoreOf(dimensionKey),
            recordCount: records.length,
            highCount: store.highLevelCount(dimensionKey),
          ),
          const SizedBox(height: 20),
          SectionTitle(
            title: '历史记录',
            accent: accent,
            trailing: Text(
              '${records.length} 条',
              style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            PaperCard(
              padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 26, color: AppColors.muted.withOpacity(0.7)),
                  const SizedBox(height: 10),
                  const Text(
                    '这个维度还没有记录',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            )
          else
            for (final record in records) ...[
              _RecordTile(record: record, dimension: dimension),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.dimension,
    required this.totalScore,
    required this.recordCount,
    required this.highCount,
  });

  final DimensionConfig? dimension;
  final int totalScore;
  final int recordCount;
  final int highCount;

  @override
  Widget build(BuildContext context) {
    final accent = dimension?.color ?? AppColors.accent;
    return PaperCard(
      color: AppColors.cardWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(dimension?.icon ?? Icons.circle_outlined, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                dimension?.name ?? '',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(value: '$totalScore', label: '累计得分', color: accent),
              _Stat(value: '$recordCount', label: '记录条数'),
              _Stat(value: '$highCount', label: '高光记录'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTheme.display(size: 22, color: color ?? AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.muted, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.dimension});

  final GrowthRecord record;
  final DimensionConfig? dimension;

  @override
  Widget build(BuildContext context) {
    final accent = dimension?.color ?? AppColors.accent;
    final time = record.createdTime;
    final levelLabel = context.read<GrowthStore>().config.levelLabel(record.levelKey);

    return PaperCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                Dates.monthDayLabel(time),
                style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, letterSpacing: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                Dates.clockLabel(time),
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  levelLabel,
                  style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${record.totalPoints}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            record.text,
            style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.ink),
          ),
          if (record.bonus > 0) ...[
            const SizedBox(height: 6),
            Text(
              '含连续打卡奖励 +${record.bonus}',
              style: const TextStyle(fontSize: 10, color: AppColors.gold),
            ),
          ],
          if (record.imagePath != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(record.imagePath!),
                height: 132,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '凭证图片已丢失',
                    style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
