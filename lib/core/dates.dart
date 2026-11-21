/// 日期工具：统一以「自然日 00:00」为一天的分界，避免跨天判断出错。
class Dates {
  Dates._();

  static const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  /// 2026-11-21
  static String ymd(DateTime date) => '${date.year}-${two(date.month)}-${two(date.day)}';

  static String two(int value) => value.toString().padLeft(2, '0');

  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  /// 加减天数，依赖 DateTime 构造器的自动进位
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 11月21日
  static String headerLabel(DateTime date) => '${date.year}年${date.month}月${date.day}日';

  /// 11月21日
  static String monthDayLabel(DateTime date) => '${date.month}月${date.day}日';

  /// 11/21
  static String shortDayLabel(DateTime date) => '${date.month}/${date.day}';

  /// 星期一
  static String weekdayLabel(DateTime date) => '星期${_weekdays[date.weekday - 1]}';

  /// 09:05
  static String clockLabel(DateTime date) => '${two(date.hour)}:${two(date.minute)}';

  /// 从 end 往前取 count 个自然日（含 end），按时间升序返回
  static List<DateTime> recentDays(int count, {DateTime? end}) {
    final last = startOfDay(end ?? DateTime.now());
    return List<DateTime>.generate(count, (i) => addDays(last, -(count - 1 - i)));
  }

  /// 连续打卡天数：从今天（若今天没记录则从昨天）往前数
  static int currentStreak(Set<String> activeDayKeys, {DateTime? today}) {
    if (activeDayKeys.isEmpty) return 0;
    var cursor = startOfDay(today ?? DateTime.now());
    if (!activeDayKeys.contains(ymd(cursor))) {
      cursor = addDays(cursor, -1);
      if (!activeDayKeys.contains(ymd(cursor))) return 0;
    }
    var streak = 0;
    while (activeDayKeys.contains(ymd(cursor))) {
      streak++;
      cursor = addDays(cursor, -1);
    }
    return streak;
  }
}
