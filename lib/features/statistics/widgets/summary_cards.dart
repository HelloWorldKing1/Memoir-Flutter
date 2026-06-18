import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../statistics_notifier.dart';

/// 概览卡片行 — 总记录 / 本月新增 / 连续天数 / 常用标签
class SummaryCards extends StatelessWidget {
  final DiaryStats stats;

  const SummaryCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final topTag = stats.topTags.isNotEmpty ? stats.topTags.first.tag : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final cards = [
          _SummaryCard(
            icon: LucideIcons.bookOpen,
            label: '总记录',
            value: '${stats.totalCount}',
            color: scheme.primary,
          ),
          _SummaryCard(
            icon: LucideIcons.calendar,
            label: '本月新增',
            value: '+${stats.thisMonthCount}',
            color: scheme.primary,
          ),
          _SummaryCard(
            icon: LucideIcons.flame,
            label: '连续记录',
            value: '${stats.streakDays}天',
            color: scheme.primary,
          ),
          _SummaryCard(
            icon: LucideIcons.tag,
            label: '常用标签',
            value: topTag,
            color: scheme.primary,
          ),
        ];

        if (wide) {
          return Row(
            children: cards
                .map((c) => Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    )))
                .toList(),
          );
        }

        return Column(
          children: [
            Row(
              children: cards
                  .sublist(0, 2)
                  .map((c) => Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: c,
                      )))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: cards
                  .sublist(2, 4)
                  .map((c) => Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: c,
                      )))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: textTheme.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.foreground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.small.copyWith(color: scheme.mutedForeground),
          ),
        ],
      ),
    );
  }
}
