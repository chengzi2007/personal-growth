import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/scoring_config.dart';
import '../core/theme.dart';
import '../data/growth_store.dart';
import '../services/media_service.dart';

/// 记录页：写今天做了什么，选维度和重要程度，可选凭证图
class RecordEditorScreen extends StatefulWidget {
  const RecordEditorScreen({super.key});

  @override
  State<RecordEditorScreen> createState() => _RecordEditorScreenState();
}

class _RecordEditorScreenState extends State<RecordEditorScreen> {
  final TextEditingController _textController = TextEditingController();

  late String _dimensionKey;
  String _levelKey = 'medium';
  String? _imagePath;
  bool _saving = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    // 默认选中第一个维度（学习），减少一次点击
    _dimensionKey = context.read<GrowthStore>().config.dimensions.first.key;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final path = await MediaService.pickVoucherFromGallery();
      if (!mounted) return;
      if (path != null) {
        setState(() => _imagePath = path);
      }
    } catch (error) {
      if (!mounted) return;
      _toast('选择图片失败：$error');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _toast('先写点今天做了什么吧');
      return;
    }
    if (_saving) return;

    final store = context.read<GrowthStore>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final dimensionName = store.config.dimension(_dimensionKey)?.name ?? '';

    setState(() => _saving = true);
    try {
      final record = await store.addRecord(
        text: text,
        dimensionKey: _dimensionKey,
        levelKey: _levelKey,
        imagePath: _imagePath,
      );
      final bonusText = record.bonus > 0 ? '（含连续打卡 +${record.bonus}）' : '';
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('已记录 · $dimensionName +${record.totalPoints} 分$bonusText')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('保存失败：$error');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GrowthStore>();
    final config = store.config;
    final dimension = config.dimension(_dimensionKey) ?? config.dimensions.first;
    final preview = store.engine.previewTotal(
      store.records,
      dimensionKey: _dimensionKey,
      levelKey: _levelKey,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('记一笔'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('今天做了什么'),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14.5, height: 1.65, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: '例如：背完 60 个单词，并复习了昨天的错题',
                hintMaxLines: 2,
              ),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('归属维度'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in config.dimensions)
                  _DimensionChip(
                    dimension: item,
                    selected: item.key == _dimensionKey,
                    onTap: () => setState(() => _dimensionKey = item.key),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const _FieldLabel('重要程度'),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < config.levels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _LevelCard(
                      level: config.levels[i],
                      points: dimension.pointsFor(config.levels[i].key),
                      accent: dimension.color,
                      selected: config.levels[i].key == _levelKey,
                      onTap: () => setState(() => _levelKey = config.levels[i].key),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            const _FieldLabel('凭证（选填）'),
            const SizedBox(height: 10),
            _buildImageArea(),
            const SizedBox(height: 10),
            const Text(
              '图片只保存在本机，不会上传到任何服务器',
              style: TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      '保存 · +$preview 分',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    final path = _imagePath;
    if (path == null) {
      return InkWell(
        onTap: _picking ? null : _pickImage,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_photo_alternate_outlined, size: 20, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(
                _picking ? '正在读取相册…' : '从相册选择凭证图片',
                style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(path),
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text(
                '图片已不存在',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _imagePath = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.inkSoft,
        letterSpacing: 1,
      ),
    );
  }
}

class _DimensionChip extends StatelessWidget {
  const _DimensionChip({
    required this.dimension,
    required this.selected,
    required this.onTap,
  });

  final DimensionConfig dimension;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? dimension.color.withOpacity(0.10) : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? dimension.color : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              dimension.icon,
              size: 15,
              color: selected ? dimension.color : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              dimension.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? dimension.color : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.points,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final LevelConfig level;
  final int points;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 86,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.line,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              level.label,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              level.caption,
              style: TextStyle(
                fontSize: 9.5,
                color: selected ? Colors.white70 : AppColors.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '+$points',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.gold : accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
