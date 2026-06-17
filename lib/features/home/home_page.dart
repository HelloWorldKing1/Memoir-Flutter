import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    final body = homeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildError(context, ref, err.toString()),
      data: (state) => ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          const GreetingHeader(
            trailing: QuickCapture(showTitle: false),
          ),
          const SizedBox(height: 20),
          StatsOverview(
            totalCount: state.totalCount,
            weekCount: state.weekCount,
            streak: state.streak,
            weekTopMood: state.weekTopMood,
          ),
          const SizedBox(height: 20),
          const AiSummaryCard(),
          const SizedBox(height: 20),
          const DailyInspiration(),
          const SizedBox(height: 20),
          if (isDesktop)
            Row(
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
            )
          else ...[
            RecentEntries(diaries: state.recentDiaries),
            const SizedBox(height: 20),
            MoodTrend(moodDistribution: state.moodDistribution),
          ],
        ],
      ),
    );

    // 桌面端 AppShell 已提供外层 Scaffold + 侧边栏，不需要再包一层
    if (isDesktop) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoir ✨'),
        actions: [
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => context.push(AppRoutes.diaryNew),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    final scheme = ShadTheme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.cloudOff, size: 48, color: scheme.destructive),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: scheme.destructive),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ShadButton.outline(
            leading: const Icon(LucideIcons.refreshCw, size: 18),
            child: const Text('重试'),
            onPressed: () => ref.read(homeProvider.notifier).refresh(),
          ),
        ],
      ),
    );
  }
}
