import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 写作习惯 — 星期分布 / 日均记录 / 平均篇幅
class WritingHabits extends StatelessWidget {
  final Map<int, double> weekdayDistribution; // 1=Mon..7=Sun
  final double avgContentLength;
  final double avgDailyCount;

  const WritingHabits({
    super.key,
    required this.weekdayDistribution,
    required this.avgContentLength,
    required this.avgDailyCount,
  });

  static const _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    final maxRatio = weekdayDistribution.values.fold<double>(
        0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('写作习惯', style: textTheme.h4),
        const SizedBox(height: 12),

        // ── 星期分布 ──
        Text('最活跃星期', style: textTheme.small.copyWith(color: scheme.mutedForeground)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final ratio = weekdayDistribution[i + 1] ?? 0.0;
            final barHeight = maxRatio > 0 ? (ratio / maxRatio * 80).clamp(8.0, 80.0) : 8.0;
            final isPeak = ratio == maxRatio && maxRatio > 0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: isPeak ? scheme.primary : scheme.mutedForeground,
                        fontWeight: isPeak ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isPeak
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weekdayLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: isPeak ? scheme.foreground : scheme.mutedForeground,
                        fontWeight: isPeak ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // ── 汇总指标 ──
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: LucideIcons.pencilLine,
                label: '日均记录',
                value: avgDailyCount.toStringAsFixed(1),
                unit: '篇',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: LucideIcons.text,
                label: '平均篇幅',
                value: avgContentLength.toStringAsFixed(0),
                unit: '字',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value $unit',
                style: textTheme.p.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                label,
                style: textTheme.small.copyWith(color: scheme.mutedForeground),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
