import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 维度图标名 -> Material 图标（JSON 里只写字符串，方便非开发者调整）
const Map<String, IconData> _iconMap = {
  'auto_stories': Icons.auto_stories_rounded,
  'architecture': Icons.architecture_rounded,
  'workspace_premium': Icons.workspace_premium_rounded,
  'local_florist': Icons.local_florist_rounded,
  'favorite': Icons.favorite_rounded,
  'groups': Icons.groups_rounded,
};

/// 单个价值维度配置
class DimensionConfig {
  const DimensionConfig({
    required this.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.points,
  });

  final String key;
  final String name;
  final Color color;
  final IconData icon;

  /// 重要程度 key -> 加分
  final Map<String, int> points;

  factory DimensionConfig.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as Map?) ?? const <String, dynamic>{};
    return DimensionConfig(
      key: json['key'] as String,
      name: json['name'] as String? ?? json['key'] as String,
      color: _parseColor(json['color'] as String?),
      icon: _iconMap[json['icon']] ?? Icons.circle_outlined,
      points: rawPoints.map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
    );
  }

  int pointsFor(String levelKey) => points[levelKey] ?? 0;

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF2F6F5E);
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }
}

/// 重要程度配置（低 / 中 / 高）
class LevelConfig {
  const LevelConfig({required this.key, required this.label, required this.caption});

  final String key;
  final String label;
  final String caption;

  factory LevelConfig.fromJson(Map<String, dynamic> json) => LevelConfig(
        key: json['key'] as String,
        label: json['label'] as String? ?? json['key'] as String,
        caption: json['caption'] as String? ?? '',
      );
}

/// 全局配置：全部来自 assets/config/app_config.json，改文件即可调整打分规则
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.dimensions,
    required this.levels,
    required this.streakDimension,
    required this.streakBonusPerDay,
    required this.quotes,
  });

  static const String assetPath = 'assets/config/app_config.json';

  final String appName;
  final List<DimensionConfig> dimensions;
  final List<LevelConfig> levels;

  /// 连续打卡奖励只作用于该维度（默认「学习」）
  final String streakDimension;

  /// 连续打卡每天额外加多少分
  final int streakBonusPerDay;

  final List<String> quotes;

  /// 读取配置；任何异常都退回内置默认值，保证 App 一定能启动
  static Future<AppConfig> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppConfig.fromJson(json);
    } catch (error) {
      debugPrint('读取 $assetPath 失败，使用内置默认配置：$error');
      return AppConfig.fallback();
    }
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final rules = (json['rules'] as Map?) ?? const <String, dynamic>{};
    return AppConfig(
      appName: json['appName'] as String? ?? '个人成长分析',
      dimensions: ((json['dimensions'] as List?) ?? const [])
          .map((e) => DimensionConfig.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      levels: ((json['levels'] as List?) ?? const [])
          .map((e) => LevelConfig.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      streakDimension: rules['streakDimension'] as String? ?? 'study',
      streakBonusPerDay: (rules['streakBonusPerDay'] as num?)?.toInt() ?? 1,
      quotes: ((json['quotes'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }

  /// 内置兜底配置（与 assets/config/app_config.json 保持一致）
  factory AppConfig.fallback() => const AppConfig(
        appName: '个人成长分析',
        dimensions: [
          DimensionConfig(
            key: 'study',
            name: '学习',
            color: Color(0xFF2F6F5E),
            icon: Icons.auto_stories_rounded,
            points: {'low': 1, 'medium': 2, 'high': 3},
          ),
          DimensionConfig(
            key: 'skill',
            name: '技能',
            color: Color(0xFF3F5B8B),
            icon: Icons.architecture_rounded,
            points: {'low': 1, 'medium': 2, 'high': 3},
          ),
          DimensionConfig(
            key: 'certificate',
            name: '证书',
            color: Color(0xFFB07B2A),
            icon: Icons.workspace_premium_rounded,
            points: {'low': 5, 'medium': 8, 'high': 10},
          ),
          DimensionConfig(
            key: 'life',
            name: '生活',
            color: Color(0xFFA8633F),
            icon: Icons.local_florist_rounded,
            points: {'low': 1, 'medium': 2, 'high': 3},
          ),
          DimensionConfig(
            key: 'health',
            name: '健康',
            color: Color(0xFFA64B4B),
            icon: Icons.favorite_rounded,
            points: {'low': 1, 'medium': 2, 'high': 3},
          ),
          DimensionConfig(
            key: 'social',
            name: '社交',
            color: Color(0xFF4A7C86),
            icon: Icons.groups_rounded,
            points: {'low': 1, 'medium': 2, 'high': 3},
          ),
        ],
        levels: [
          LevelConfig(key: 'low', label: '低', caption: '轻量积累'),
          LevelConfig(key: 'medium', label: '中', caption: '稳定推进'),
          LevelConfig(key: 'high', label: '高', caption: '高光时刻'),
        ],
        streakDimension: 'study',
        streakBonusPerDay: 1,
        quotes: [
          '日拱一卒，功不唐捐。',
          '把今天记下来，明天就看得见变化。',
          '成长不是一次跃迁，而是许多个微小的今天。',
        ],
      );

  DimensionConfig? dimension(String key) {
    for (final item in dimensions) {
      if (item.key == key) return item;
    }
    return null;
  }

  LevelConfig? level(String key) {
    for (final item in levels) {
      if (item.key == key) return item;
    }
    return null;
  }

  String levelLabel(String key) => level(key)?.label ?? key;

  /// 按自然日取一句寄语，同一天内保持不变
  String quoteFor(DateTime day) {
    if (quotes.isEmpty) return '日拱一卒，功不唐捐。';
    final index = day.difference(DateTime(2020)).inDays.abs() % quotes.length;
    return quotes[index];
  }
}
