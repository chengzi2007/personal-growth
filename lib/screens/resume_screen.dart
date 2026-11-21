import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../core/scoring_config.dart';
import '../core/theme.dart';
import '../data/growth_store.dart';
import '../services/media_service.dart';
import '../services/resume_builder.dart';
import '../widgets/spark_chart.dart';

/// 简历页：把成长数据排成一张可分享的长图
class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final ScreenshotController _screenshot = ScreenshotController();
  bool _saving = false;

  Future<void> _editNickname() async {
    final store = context.read<GrowthStore>();
    final controller = TextEditingController(text: store.nickname);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '设置昵称',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
          decoration: const InputDecoration(hintText: '例如：林小满', counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('保存', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result != null && result.isNotEmpty) {
      await store.setNickname(result);
    }
  }

  /// 用 screenshot 的 captureFromWidget 离屏渲染整页海报，
  /// 得到一张不受屏幕高度限制的长图，再写入系统相册。
  Future<void> _saveLongImage() async {
    if (_saving) return;

    final store = context.read<GrowthStore>();
    final data = ResumeData.fromStore(store);
    final messenger = ScaffoldMessenger.of(context);
    final mediaQuery = MediaQuery.of(context);

    setState(() => _saving = true);
    try {
      final bytes = await _screenshot.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: mediaQuery,
            child: Material(
              color: AppColors.paper,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: SizedBox(
                  width: 375,
                  child: ResumePoster(data: data, animate: false),
                ),
              ),
            ),
          ),
        ),
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 300),
        context: context,
      );

      await MediaService.saveImageToGallery(bytes);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('长图已保存到相册「个人成长」')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(MediaService.describeError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GrowthStore>();
    final data = ResumeData.fromStore(store);

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
                      const Text('RESUME', style: AppTheme.overline),
                      const SizedBox(height: 6),
                      Text('成长简历', style: AppTheme.display(size: 26)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _editNickname,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: const Text('昵称', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ResumePoster(data: data),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveLongImage,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.accent.withOpacity(0.55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded, size: 19),
                label: Text(
                  _saving ? '正在生成长图…' : '保存截图',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                '整页长图会保存到系统相册的「个人成长」中',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 海报本体：屏幕预览与离屏截图共用同一套布局
class ResumePoster extends StatelessWidget {
  const ResumePoster({super.key, required this.data, this.animate = true});

  final ResumeData data;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final maxScore = data.scores.values.fold<int>(0, (max, value) => value > max ? value : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWarm,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PERSONAL GROWTH',
                style: TextStyle(
                  fontSize: 8.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              const Text(
                '成长简历',
                style: TextStyle(fontSize: 9.5, letterSpacing: 2, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.nickname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.display(size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            '记录 ${data.activeDays} 天 · ${data.recordCount} 条成长足迹',
            style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 0.3),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 16),
          Row(
            children: [
              _PosterStat(value: '${data.totalScore}', label: '累计成长值', emphasize: true),
              _PosterStat(value: '${data.activeDays}', label: '记录天数'),
              _PosterStat(value: '${data.streak}', label: '连续天数'),
            ],
          ),
          const SizedBox(height: 20),
          const _PosterTitle('价值版图'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              for (final dimension in data.dimensions)
                _PosterTag(
                  dimension: dimension,
                  score: data.scores[dimension.key] ?? 0,
                  maxScore: maxScore,
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _PosterTitle('高光成就'),
          const SizedBox(height: 10),
          if (data.achievements.isEmpty)
            const Text(
              '还没有高光时刻，去记录第一条吧。',
              style: TextStyle(fontSize: 11.5, color: AppColors.muted),
            )
          else
            for (final item in data.achievements)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: item.dimension.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.dimension.name} × ${item.count}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${item.score} 分',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          const _PosterTitle('成长曲线'),
          const SizedBox(height: 8),
          if (data.totalScore == 0)
            Container(
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '记下第一笔，曲线就会开始生长',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            )
          else
            SizedBox(
              height: 76,
              child: SparkChart(
                values: data.curve,
                color: AppColors.accent,
                animate: animate,
              ),
            ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                data.generatedLabel,
                style: const TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 0.4),
              ),
              const Spacer(),
              const Text(
                '个人成长分析 · 本地生成',
                style: TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PosterTitle extends StatelessWidget {
  const _PosterTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 11,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _PosterStat extends StatelessWidget {
  const _PosterStat({
    required this.value,
    required this.label,
    this.emphasize = false,
  });

  final String value;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.display(
              size: emphasize ? 26 : 20,
              color: emphasize ? AppColors.accent : AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _PosterTag extends StatelessWidget {
  const _PosterTag({
    required this.dimension,
    required this.score,
    required this.maxScore,
  });

  final DimensionConfig dimension;
  final int score;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0).toDouble();
    final fontSize = 11.0 + ratio * 9;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: dimension.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dimension.color.withOpacity(0.22)),
      ),
      child: Text(
        '${dimension.name} $score',
        style: TextStyle(
          fontSize: fontSize,
          color: dimension.color,
          fontWeight: ratio > 0.6 ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
