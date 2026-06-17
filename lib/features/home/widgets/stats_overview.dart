import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../data/models/enums.dart';

/// 数据概览卡片组。
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
        icon: LucideIcons.bookOpen,
        value: '$totalCount',
        label: '总记录数',
        color: const Color(0xFF7C3AED),
      ),
      _StatCard(
        icon: LucideIcons.calendarRange,
        value: '$weekCount',
        label: '本周新增',
        color: const Color(0xFF0D9488),
      ),
      _StatCard(
        icon: LucideIcons.flame,
        value: '$streak',
        label: '连续天数',
        color: const Color(0xFFEA580C),
      ),
      _StatCard(
        icon: LucideIcons.smile,
        value: weekTopMood?.emoji ?? '—',
        label: '本周心情',
        color: const Color(0xFF16A34A),
        isEmoji: weekTopMood != null,
        subtitle: weekTopMood?.label,
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
    final textTheme = ShadTheme.of(context).textTheme;

    return ShadCard(
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
                    style: textTheme.p.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEmoji ? null : color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: textTheme.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
