import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/dates.dart';
import '../core/scoring_config.dart';
import '../models/growth_record.dart';
import '../services/score_engine.dart';

/// 全局状态：负责 Hive 读写、分数聚合，以及通知 UI 刷新。
///
/// 使用 ChangeNotifier + provider，所有页面 watch 同一个 store，
/// 新增记录后首页 / 分析页 / 简历页会自动刷新。
class GrowthStore extends ChangeNotifier {
  GrowthStore._(this._recordsBox, this._settingsBox, this.config);

  static const String recordsBoxName = 'growth_records';
  static const String settingsBoxName = 'growth_settings';
  static const String nicknameKey = 'nickname';

  final Box<dynamic> _recordsBox;
  final Box<dynamic> _settingsBox;

  final AppConfig config;

  /// 打分引擎依赖 config，用到时再初始化
  late final ScoreEngine engine = ScoreEngine(config);

  List<GrowthRecord> _records = <GrowthRecord>[];
  String _nickname = '成长者';

  /// 启动时打开 Hive 盒子并读取配置
  static Future<GrowthStore> open() async {
    final recordsBox = await Hive.openBox<dynamic>(recordsBoxName);
    final settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    final config = await AppConfig.load();

    final store = GrowthStore._(recordsBox, settingsBox, config);
    store._reload();
    final saved = settingsBox.get(nicknameKey);
    if (saved is String && saved.trim().isNotEmpty) {
      store._nickname = saved.trim();
    }
    return store;
  }

  void _reload() {
    _records = _recordsBox.values
        .map((raw) => GrowthRecord.fromMap(Map<dynamic, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ---------- 只读聚合 ----------

  /// 全部记录，按时间倒序
  List<GrowthRecord> get records => List<GrowthRecord>.unmodifiable(_records);

  String get nickname => _nickname;

  int get recordCount => _records.length;

  int get totalScore => _records.fold(0, (sum, r) => sum + r.totalPoints);

  /// 有记录的「天数」（去重后的自然日数量）
  int get activeDays => _records.map((r) => r.dayKey).toSet().length;

  /// 连续记录天数（今天/昨天为止）
  int get currentStreak =>
      Dates.currentStreak(_records.map((r) => r.dayKey).toSet());

  /// 今日累计得分
  int get todayScore {
    final today = Dates.ymd(DateTime.now());
    return _records.where((r) => r.dayKey == today).fold(0, (sum, r) => sum + r.totalPoints);
  }

  int get todayCount {
    final today = Dates.ymd(DateTime.now());
    return _records.where((r) => r.dayKey == today).length;
  }

  /// 各维度总分
  Map<String, int> get dimensionScores {
    final map = <String, int>{for (final d in config.dimensions) d.key: 0};
    for (final record in _records) {
      map[record.dimensionKey] = (map[record.dimensionKey] ?? 0) + record.totalPoints;
    }
    return map;
  }

  int scoreOf(String dimensionKey) => dimensionScores[dimensionKey] ?? 0;

  /// 某维度今日得分
  int todayScoreOf(String dimensionKey) {
    final today = Dates.ymd(DateTime.now());
    return _records
        .where((r) => r.dimensionKey == dimensionKey && r.dayKey == today)
        .fold(0, (sum, r) => sum + r.totalPoints);
  }

  /// 某维度的全部记录（倒序）
  List<GrowthRecord> recordsOf(String dimensionKey) =>
      _records.where((r) => r.dimensionKey == dimensionKey).toList();

  /// 某维度某个重要程度的记录条数（简历页「证书 × 3」这类成就）
  int highLevelCount(String dimensionKey) =>
      _records.where((r) => r.dimensionKey == dimensionKey && r.levelKey == 'high').length;

  // ---------- 写操作 ----------

  /// 新增一条记录，返回算好分数的对象
  Future<GrowthRecord> addRecord({
    required String text,
    required String dimensionKey,
    required String levelKey,
    String? imagePath,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    final record = GrowthRecord(
      id: now.microsecondsSinceEpoch.toString(),
      dimensionKey: dimensionKey,
      text: text.trim(),
      levelKey: levelKey,
      points: engine.basePoints(dimensionKey, levelKey),
      bonus: engine.streakBonus(_records, dimensionKey, now),
      createdAt: now.millisecondsSinceEpoch,
      imagePath: imagePath,
    );

    await _recordsBox.put(record.id, record.toMap());
    _reload();
    notifyListeners();
    return record;
  }

  Future<void> setNickname(String value) async {
    final next = value.trim();
    if (next.isEmpty || next == _nickname) return;
    _nickname = next;
    await _settingsBox.put(nicknameKey, next);
    notifyListeners();
  }
}
