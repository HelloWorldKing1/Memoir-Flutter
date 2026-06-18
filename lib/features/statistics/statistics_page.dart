import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'statistics_notifier.dart';
import 'widgets/distribution_bars.dart';
import 'widgets/monthly_trend_chart.dart';
import 'widgets/summary_cards.dart';
import 'widgets/tag_cloud.dart';
import 'widgets/writing_habits.dart';

/// 统计页面 — 聚合展示日记数据的多维度分析
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(diaryStatsProvider);
    final scheme = ShadTheme.of(context).colorScheme;
    final textTheme = ShadTheme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => ref.invalidate(diaryStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: scheme.destructive),
              const SizedBox(height: 12),
              Text('加载失败', style: textTheme.p),
              const SizedBox(height: 8),
              Text(err.toString(),
                  style: textTheme.small.copyWith(color: scheme.mutedForeground)),
              const SizedBox(height: 16),
              ShadButton.outline(
                onPressed: () => ref.invalidate(diaryStatsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (stats) {
          if (stats.totalCount == 0) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.barChart3, size: 48, color: scheme.mutedForeground),
                  const SizedBox(height: 12),
                  Text('还没有记录，开始写点什么吧 ✍️', style: textTheme.p),
                ],
              ),
            );
          }

          return _buildContent(context, stats);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DiaryStats stats) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ 概览卡片 ═══
          SummaryCards(stats: stats),
          const SizedBox(height: 24),

          // ═══ 月度趋势图 ═══
          ShadCard(
            padding: const EdgeInsets.all(20),
            child: MonthlyTrendChart(monthlyTrend: stats.monthlyTrend),
          ),
          const SizedBox(height: 24),

          // ═══ 类型 + 心情分布 ═══
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ShadCard(
                    padding: const EdgeInsets.all(20),
                    child: TypeDistributionBars(distribution: stats.typeDistribution),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ShadCard(
                    padding: const EdgeInsets.all(20),
                    child: MoodDistributionBars(distribution: stats.moodDistribution),
                  ),
                ),
              ],
            )
          else ...[
            ShadCard(
              padding: const EdgeInsets.all(20),
              child: TypeDistributionBars(distribution: stats.typeDistribution),
            ),
            const SizedBox(height: 16),
            ShadCard(
              padding: const EdgeInsets.all(20),
              child: MoodDistributionBars(distribution: stats.moodDistribution),
            ),
          ],
          const SizedBox(height: 24),

          // ═══ 标签云 ═══
          ShadCard(
            padding: const EdgeInsets.all(20),
            child: TagCloud(tags: stats.topTags),
          ),
          const SizedBox(height: 24),

          // ═══ 写作习惯 ═══
          ShadCard(
            padding: const EdgeInsets.all(20),
            child: WritingHabits(
              weekdayDistribution: stats.weekdayDistribution,
              avgContentLength: stats.avgContentLength,
              avgDailyCount: stats.avgDailyCount,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
