import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/di/providers.dart';
import '../../data/models/diary.dart';
import '../../data/models/enums.dart';

// ─── AI 总结状态 ────────────────────────────────────────────

/// AI 总结的各类状态。
sealed class AiSummaryState {
  const AiSummaryState();
}

/// 总结数据就绪。
class AiSummaryReady extends AiSummaryState {
  final String title;
  final String body;
  final DateTime generatedAt;
  final int basedOnDays;
  final int entryCount;

  const AiSummaryReady({
    required this.title,
    required this.body,
    required this.generatedAt,
    required this.basedOnDays,
    required this.entryCount,
  });
}

/// 数据不足，无法生成。
class AiSummaryInsufficient extends AiSummaryState {
  /// 当前记录数。
  final int currentCount;

  /// 最少需要的记录数。
  final int requiredCount;

  const AiSummaryInsufficient({
    required this.currentCount,
    this.requiredCount = 3,
  });
}

/// 生成中。
class AiSummaryLoading extends AiSummaryState {
  const AiSummaryLoading();
}

/// 生成失败。
class AiSummaryError extends AiSummaryState {
  final String message;
  const AiSummaryError({this.message = '生成失败，请检查网络后重试'});
}

// ─── 首页状态 ───────────────────────────────────────────────

/// 首页聚合数据。
class HomeState {
  final int totalCount;
  final int weekCount;
  final int streak;
  final Mood? weekTopMood;
  final List<Diary> recentDiaries;
  final Map<Mood, int> moodDistribution;
  final AiSummaryState aiSummary;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.totalCount = 0,
    this.weekCount = 0,
    this.streak = 0,
    this.weekTopMood,
    this.recentDiaries = const [],
    this.moodDistribution = const {},
    this.aiSummary = const AiSummaryLoading(),
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    int? totalCount,
    int? weekCount,
    int? streak,
    Mood? weekTopMood,
    List<Diary>? recentDiaries,
    Map<Mood, int>? moodDistribution,
    AiSummaryState? aiSummary,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      totalCount: totalCount ?? this.totalCount,
      weekCount: weekCount ?? this.weekCount,
      streak: streak ?? this.streak,
      weekTopMood: weekTopMood ?? this.weekTopMood,
      recentDiaries: recentDiaries ?? this.recentDiaries,
      moodDistribution: moodDistribution ?? this.moodDistribution,
      aiSummary: aiSummary ?? this.aiSummary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Mock AI 总结文案 ───────────────────────────────────────

final _mockSummaries = [
  (
    title: '本周你写了 {count} 篇记录，以「{topType}」和「{secondType}」为主。',
    body: '你的心情总体偏向 {topMood}，尤其在周三达到了情绪高峰。\n'
        '你多次提到了「{keyword1}」和「{keyword2}」，看来最近在专注这方面的积累。\n\n'
        '写作时间集中在晚上 9-11 点，这是你的创作黄金时段。继续保持这个节奏！💪',
  ),
  (
    title: '平稳的一周，你在默默积累。',
    body: '本周 {count} 篇记录虽然不多，但每一篇都有深度思考。\n'
        '心情以 {topMood} 为主，整体状态稳定。\n\n'
        '试着尝试不同的记录类型，比如写一篇「灵感」或「文章」来激发新的思路 ✨',
  ),
  (
    title: '这周的情绪有些起伏，但写作是最好的出口。',
    body: '检测到你本周心情从 {firstMood} 到 {lastMood} 的转变。\n'
        '日记中频繁出现「{keyword1}」和「{keyword2}」相关的词汇。\n\n'
        '写作是一种疗愈，记录本身就是面对。你已经做得很好了 🌱',
  ),
  (
    title: '高产的一周！你正在形成稳定的写作习惯。',
    body: '连续 {streak} 天不间断写作，本周更是写了 {count} 篇。\n'
        '「{topType}」是你最常写的类型，且多次提到「{keyword1}」。\n\n'
        '这个习惯正在变成你的核心竞争力，保持住这份热情 🔥',
  ),
  (
    title: '本周的关键词是「{keyword1}」。',
    body: '你在 {count} 篇记录中围绕「{keyword1}」展开了深入思考。\n'
        '搭配 {topMood} 的心情状态，说明你对这个方向充满热情。\n\n'
        '可以考虑把这些零散的笔记整理成一篇完整的文章 📝',
  ),
];

// ─── Notifier ───────────────────────────────────────────────

/// 首页数据控制器。
///
/// 聚合日记统计数据、最近记录、心情趋势，并生成 AI 周报总结（当前为 Mock）。
class HomeNotifier extends AsyncNotifier<HomeState> {
  PocketBase get _pb => ref.read(pbClientProvider);

  @override
  Future<HomeState> build() async {
    return _loadData();
  }

  /// 刷新首页全部数据。
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadData());
  }

  /// 重新生成 AI 总结。
  Future<void> regenerateAiSummary() async {
    final current = state.value;
    if (current == null) return;

    // 先显示 loading
    state = AsyncValue.data(current.copyWith(
      aiSummary: const AiSummaryLoading(),
    ));

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = state.value;
    if (updated == null) return;

    final aiSummary = _pickMockSummary(updated);
    state = AsyncValue.data(updated.copyWith(aiSummary: aiSummary));
  }

  // ─── 数据加载 ──────────────────────────────────────────

  Future<HomeState> _loadData() async {
    final userId = _pb.authStore.record?.id;
    if (userId == null) {
      throw Exception('未登录');
    }

    // 获取总数 + 最近记录（一次查询）
    final result = await _pb.collection('diaries').getList(
          page: 1,
          perPage: 30,
          filter: 'user = "$userId" && isDeleted != true',
          sort: '-created',
          skipTotal: false, // 确保返回 totalItems
        );

    final allDiaries = result.items.map((r) => Diary.fromRecord(r.toJson())).toList();
    final totalCount = result.totalItems;

    // 计算本周范围（周一 ~ 周日）
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    // 本周记录
    final weekDiaries = allDiaries.where((d) {
      final created = d.createdAt;
      final dDate = DateTime(created.year, created.month, created.day);
      return !dDate.isBefore(weekStartDate);
    }).toList();
    final weekCount = weekDiaries.length;

    // 连续天数（从今天往前数）
    final streak = _calculateStreak(allDiaries, now);

    // 本周最多心情
    final weekMoodCounts = <Mood, int>{};
    for (final d in weekDiaries) {
      weekMoodCounts[d.mood] = (weekMoodCounts[d.mood] ?? 0) + 1;
    }
    Mood? weekTopMood;
    if (weekMoodCounts.isNotEmpty) {
      weekTopMood = weekMoodCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    // 最近 5 条
    final recentDiaries = allDiaries.take(5).toList();

    // 近 7 天心情分布（每篇日记独立计数）
    final moodDistribution = <Mood, int>{};
    for (final d in weekDiaries) {
      moodDistribution[d.mood] = (moodDistribution[d.mood] ?? 0) + 1;
    }

    final homeState = HomeState(
      totalCount: totalCount,
      weekCount: weekCount,
      streak: streak,
      weekTopMood: weekTopMood,
      recentDiaries: recentDiaries,
      moodDistribution: moodDistribution,
      isLoading: false,
    );

    // 生成 AI 总结（当前为 Mock）
    final aiSummary = _pickMockSummary(homeState);

    return homeState.copyWith(aiSummary: aiSummary);
  }

  // ─── 连续天数 ──────────────────────────────────────────

  /// 计算从今天开始向前的连续写作天数。
  ///
  /// 基于已拉取的 [diaries] 列表（最近 60 条），
  /// 若连续天数超出已拉取范围则返回基于已拉取数据的保守计算。
  int _calculateStreak(List<Diary> diaries, DateTime now) {
    if (diaries.isEmpty) return 0;

    // 按日期分组
    final daySet = <int>{};
    for (final d in diaries) {
      final created = d.createdAt;
      final dayKey = created.year * 10000 + created.month * 100 + created.day;
      daySet.add(dayKey);
    }

    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayKey = day.year * 10000 + day.month * 100 + day.day;
      if (daySet.contains(dayKey)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── Mock AI 总结 ──────────────────────────────────────

  AiSummaryState _pickMockSummary(HomeState state) {
    final weekD = state.weekCount;
    if (weekD < 3) {
      return AiSummaryInsufficient(
        currentCount: weekD,
        requiredCount: 3,
      );
    }

    final rng = Random(DateTime.now().day); // 每天固定一个随机种子
    final template = _mockSummaries[rng.nextInt(_mockSummaries.length)];

    // 简单关键词提取（从最近日记标题中拼凑）
    final keywords = <String>[];
    for (final d in state.recentDiaries) {
      for (final tag in d.tags) {
        if (!keywords.contains(tag) && keywords.length < 5) {
          keywords.add(tag);
        }
      }
    }
    final keyword1 = keywords.isNotEmpty ? keywords.first : '成长';
    final keyword2 = keywords.length > 1 ? keywords[1] : '生活';

    // 类型统计
    final typeCounts = <EntryType, int>{};
    for (final d in state.recentDiaries) {
      typeCounts[d.entryType] = (typeCounts[d.entryType] ?? 0) + 1;
    }
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topType = sortedTypes.isNotEmpty ? sortedTypes.first.key.label : '日记';
    final secondType = sortedTypes.length > 1 ? sortedTypes[1].key.label : '感悟';

    final topMood = state.weekTopMood?.label ?? '开心';
    final topMoodEmoji = state.weekTopMood?.emoji ?? '😊';

    // 本周主导心情
    final firstMoodName = state.weekTopMood?.label ?? '平淡';
    final lastMoodName = state.weekTopMood?.label ?? '开心';

    String title = template.title
        .replaceAll('{count}', '$weekD')
        .replaceAll('{topType}', topType)
        .replaceAll('{secondType}', secondType)
        .replaceAll('{topMood}', '$topMoodEmoji $topMood')
        .replaceAll('{streak}', '${state.streak}')
        .replaceAll('{keyword1}', keyword1)
        .replaceAll('{keyword2}', keyword2);

    String body = template.body
        .replaceAll('{count}', '$weekD')
        .replaceAll('{topType}', topType)
        .replaceAll('{secondType}', secondType)
        .replaceAll('{topMood}', '$topMoodEmoji $topMood')
        .replaceAll('{firstMood}', firstMoodName)
        .replaceAll('{lastMood}', lastMoodName)
        .replaceAll('{streak}', '${state.streak}')
        .replaceAll('{keyword1}', keyword1)
        .replaceAll('{keyword2}', keyword2);

    return AiSummaryReady(
      title: title,
      body: body,
      generatedAt: DateTime.now(),
      basedOnDays: 7,
      entryCount: weekD,
    );
  }
}

/// 首页 Notifier Provider
final homeProvider =
    AsyncNotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
