import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_router.dart';
import 'home_notifier.dart';
import 'widgets/greeting_header.dart';
import 'widgets/stats_overview.dart';
import 'widgets/ai_summary_card.dart';
import 'widgets/quick_capture.dart';
import 'widgets/daily_inspiration.dart';
import 'widgets/recent_entries.dart';
import 'widgets/mood_trend.dart';

/// 首页（Dashboard）。
///
/// 登陆后的默认落地页，聚合展示：
/// 1. 问候头部（时段问候 + 日期 + 右侧快速记录）
/// 2. 数据概览卡片（总记录 / 本周新增 / 连续天数 / 本周心情）
/// 3. AI 近期总结（Mock → 后续接入真实 AI）
/// 4. 今日灵感（每 10 秒自动刷新，含淡入淡出动画）
/// 5. 最近记录（缓速自动滚动，悬浮暂停）
/// 6. 心情趋势（近7天）
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      appBar: isDesktop
          ? null // 桌面端侧边栏已有标题
          : AppBar(
              title: const Text('Memoir ✨'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.push(AppRoutes.diaryNew),
                  tooltip: '写记录',
                ),
              ],
            ),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(context, ref, err.toString()),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // 区块 1: 问候头部 + 右侧快速记录
                const GreetingHeader(
                  trailing: QuickCapture(showTitle: false),
                ),
                const SizedBox(height: 20),
                // 区块 2: 统计卡片
                StatsOverview(
                  totalCount: state.totalCount,
                  weekCount: state.weekCount,
                  streak: state.streak,
                  weekTopMood: state.weekTopMood,
                ),
                const SizedBox(height: 20),
                // 区块 3: AI 近期总结
                const AiSummaryCard(),
                const SizedBox(height: 20),
                // 区块 4: 今日灵感（每10秒自动刷新）
                const DailyInspiration(),
                const SizedBox(height: 20),
                // 区块 5 + 6: 最近记录 + 心情趋势
                if (isDesktop)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RecentEntries(diaries: state.recentDiaries),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MoodTrend(
                            moodDistribution: state.moodDistribution,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  RecentEntries(diaries: state.recentDiaries),
                  const SizedBox(height: 20),
                  MoodTrend(
                    moodDistribution: state.moodDistribution,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
            onPressed: () => ref.read(homeProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}
