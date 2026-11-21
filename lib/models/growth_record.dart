import '../core/dates.dart';

/// 一条成长记录。
/// 直接以 Map（JSON）形式存入 Hive，省去 TypeAdapter 代码生成步骤。
class GrowthRecord {
  const GrowthRecord({
    required this.id,
    required this.dimensionKey,
    required this.text,
    required this.levelKey,
    required this.points,
    required this.bonus,
    required this.createdAt,
    this.imagePath,
  });

  final String id;
  final String dimensionKey;
  final String text;

  /// low / medium / high
  final String levelKey;

  /// 基础分（由配置文件决定）
  final int points;

  /// 额外分（学习连续打卡奖励等）
  final int bonus;

  /// 毫秒时间戳
  final int createdAt;

  /// 凭证图片在应用私有目录下的路径
  final String? imagePath;

  int get totalPoints => points + bonus;

  DateTime get createdTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// 用于按自然日聚合的 key
  String get dayKey => Dates.ymd(createdTime);

  Map<String, dynamic> toMap() => {
        'id': id,
        'dimensionKey': dimensionKey,
        'text': text,
        'levelKey': levelKey,
        'points': points,
        'bonus': bonus,
        'createdAt': createdAt,
        'imagePath': imagePath,
      };

  factory GrowthRecord.fromMap(Map<dynamic, dynamic> map) => GrowthRecord(
        id: map['id'] as String,
        dimensionKey: map['dimensionKey'] as String,
        text: map['text'] as String? ?? '',
        levelKey: map['levelKey'] as String? ?? 'medium',
        points: (map['points'] as num?)?.toInt() ?? 0,
        bonus: (map['bonus'] as num?)?.toInt() ?? 0,
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
        imagePath: map['imagePath'] as String?,
      );
}
