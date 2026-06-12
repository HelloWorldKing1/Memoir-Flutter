import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';

/// 数据概览卡片组。
///
/// 横向排列 4 张统计卡片（总记录数 / 本周新增 / 连续天数 / 本周心情）。
/// 桌面 4 列 → 平板/手机 2×2 网格。
class StatsOverview extends StatelessWidget {
  final int totalCount;
  final int weekCount;
  final int streak;
  final Mood? weekTopMood;

  const StatsOverview({
    super.key,
    required this.totalCount,
    required this.weekCount,
    required this.streak,
    this.weekTopMood,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    final cards = [
      _StatCard(
        icon: Icons.auto_stories,
        value: '$totalCount',
        label: '总记录数',
        color: Colors.deepPurple,
      ),
      _StatCard(
        icon: Icons.date_range,
        value: '$weekCount',
        label: '本周新增',
        color: Colors.teal,
      ),
      _StatCard(
        icon: Icons.local_fire_department,
        value: '$streak',
        label: '连续天数',
        color: Colors.orange,
      ),
      _StatCard(
        icon: Icons.sentiment_satisfied,
        value: weekTopMood?.emoji ?? '—',
        label: '本周心情',
        color: Colors.green,
        isEmoji: weekTopMood != null,
        subtitle: weekTopMood?.value,
      ),
    ];

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: cards.map((card) => Expanded(child: card)).toList(),
        ),
      );
    }

    // 平板 / 手机：2×2 网格
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: cards
            .map((card) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 50) / 2,
                  child: card,
                ))
            .toList(),
      ),
    );
  }
}

/// 单张统计卡片
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isEmoji;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isEmoji = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isEmoji
                  ? Center(
                      child: Text(value, style: const TextStyle(fontSize: 22)),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEmoji ? (subtitle ?? label) : value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEmoji ? null : color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
