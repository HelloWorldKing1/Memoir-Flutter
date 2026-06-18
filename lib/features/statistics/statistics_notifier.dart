import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../data/models/diary.dart';
import '../../data/models/enums.dart';

// =============================================================================
// 统计模型
// =============================================================================

/// 标签及其出现次数
class TagCount {
  final String tag;
  final int count;
  const TagCount(this.tag, this.count);
}

/// 月度记录数
class MonthCount {
  final int year;
  final int month;
  final int count;
  const MonthCount(this.year, this.month, this.count);

  String get label => '$month月';
}

/// 聚合统计结果 — 一次拉取全量数据后本地计算
class DiaryStats {
  final int totalCount;
  final int thisMonthCount;
  final int streakDays;
  final Map<EntryType, int> typeDistribution;
  final Map<Mood, int> moodDistribution;
  final Map<Weather, int> weatherDistribution;
  final List<TagCount> topTags; // 频次降序
  final List<MonthCount> monthlyTrend; // 最近 12 个月
  final Map<int, double> weekdayDistribution; // 1=Mon..7=Sun → ratio
  final double avgContentLength;
  final double avgDailyCount;

  const DiaryStats({
    required this.totalCount,
    required this.thisMonthCount,
    required this.streakDays,
    required this.typeDistribution,
    required this.moodDistribution,
    required this.weatherDistribution,
    required this.topTags,
    required this.monthlyTrend,
    required this.weekdayDistribution,
    required this.avgContentLength,
    required this.avgDailyCount,
  });

  /// 从日记列表聚合所有统计维度
  factory DiaryStats.aggregate(List<Diary> diaries) {
    if (diaries.isEmpty) {
      return DiaryStats.empty();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ── 基础计数 ──
    final totalCount = diaries.length;

    // ── 本月新增 ──
    final thisMonthCount = diaries
        .where((d) =>
            d.createdAt.year == now.year && d.createdAt.month == now.month)
        .length;

    // ── 连续记录天数 ──
    final streakDays = _calcStreak(diaries, today);

    // ── 类型分布 ──
    final typeDistribution = <EntryType, int>{};
    for (final type in EntryType.values) {
      typeDistribution[type] = 0;
    }
    for (final d in diaries) {
      typeDistribution[d.entryType] =
          (typeDistribution[d.entryType] ?? 0) + 1;
    }

    // ── 心情分布 ──
    final moodDistribution = <Mood, int>{};
    for (final mood in Mood.values) {
      moodDistribution[mood] = 0;
    }
    for (final d in diaries) {
      moodDistribution[d.mood] = (moodDistribution[d.mood] ?? 0) + 1;
    }

    // ── 天气分布 ──
    final weatherDistribution = <Weather, int>{};
    for (final w in Weather.values) {
      weatherDistribution[w] = 0;
    }
    for (final d in diaries) {
      final w = d.weather;
      if (w != null) {
        weatherDistribution[w] = (weatherDistribution[w] ?? 0) + 1;
      }
    }

    // ── 标签频次 ──
    final tagCountMap = <String, int>{};
    for (final d in diaries) {
      for (final tag in d.tags) {
        tagCountMap[tag] = (tagCountMap[tag] ?? 0) + 1;
      }
    }
    final topTags = tagCountMap.entries
        .map((e) => TagCount(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // ── 月度趋势（最近 12 个月） ──
    final monthlyTrend = <MonthCount>[];
    for (int i = 11; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final count = diaries.where((d) {
        return d.createdAt.year == target.year &&
            d.createdAt.month == target.month;
      }).length;
      monthlyTrend.add(MonthCount(target.year, target.month, count));
    }

    // ── 星期分布 ──
    final weekdayCounts = <int, int>{};
    for (int i = 1; i <= 7; i++) {
      weekdayCounts[i] = 0;
    }
    for (final d in diaries) {
      weekdayCounts[d.createdAt.weekday] =
          (weekdayCounts[d.createdAt.weekday] ?? 0) + 1;
    }
    final weekdayDistribution = <int, double>{};
    for (final entry in weekdayCounts.entries) {
      weekdayDistribution[entry.key] =
          totalCount > 0 ? entry.value / totalCount : 0.0;
    }

    // ── 平均篇幅 ──
    final totalLength =
        diaries.fold<int>(0, (sum, d) => sum + d.content.length);
    final avgContentLength = totalCount > 0 ? totalLength / totalCount : 0.0;

    // ── 日均记录 ──
    final dates = diaries.map((d) {
      final dt = d.createdAt;
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();
    final activeDays = dates.length;
    final avgDailyCount =
        activeDays > 0 ? totalCount / activeDays : 0.0;

    return DiaryStats(
      totalCount: totalCount,
      thisMonthCount: thisMonthCount,
      streakDays: streakDays,
      typeDistribution: typeDistribution,
      moodDistribution: moodDistribution,
      weatherDistribution: weatherDistribution,
      topTags: topTags,
      monthlyTrend: monthlyTrend,
      weekdayDistribution: weekdayDistribution,
      avgContentLength: avgContentLength,
      avgDailyCount: avgDailyCount,
    );
  }

  factory DiaryStats.empty() {
    return DiaryStats(
      totalCount: 0,
      thisMonthCount: 0,
      streakDays: 0,
      typeDistribution: {for (final t in EntryType.values) t: 0},
      moodDistribution: {for (final m in Mood.values) m: 0},
      weatherDistribution: {for (final w in Weather.values) w: 0},
      topTags: const [],
      monthlyTrend: const [],
      weekdayDistribution: {for (int i = 1; i <= 7; i++) i: 0.0},
      avgContentLength: 0,
      avgDailyCount: 0,
    );
  }

  /// 计算从今天往回数的连续记录天数
  static int _calcStreak(List<Diary> diaries, DateTime today) {
    final dateSet = <int>{};
    for (final d in diaries) {
      final dt = d.createdAt;
      dateSet.add(DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch);
    }

    int streak = 0;
    var cursor = today;
    while (true) {
      if (dateSet.contains(cursor.millisecondsSinceEpoch)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

// =============================================================================
// Provider
// =============================================================================

/// 聚合统计结果
final diaryStatsProvider =
    FutureProvider<DiaryStats>((ref) async {
  final pb = ref.read(pbClientProvider);
  final userId = pb.authStore.record?.id;
  if (userId == null) return DiaryStats.empty();

  final records = await pb.collection('diaries').getFullList(
        filter: 'user = "$userId" && isDeleted != true',
        sort: '-created',
      );

  final diaries = records.map((r) => Diary.fromRecord(r.toJson())).toList();
  return DiaryStats.aggregate(diaries);
});
