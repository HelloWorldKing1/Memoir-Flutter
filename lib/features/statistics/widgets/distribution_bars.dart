import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../data/models/enums.dart';

/// 类型分布柱状条
class TypeDistributionBars extends StatelessWidget {
  final Map<EntryType, int> distribution;

  const TypeDistributionBars({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('类型分布', style: textTheme.h4),
        const SizedBox(height: 12),
        ..._buildBars(context, distribution.entries.map((e) => _BarEntry(
              emoji: e.key.emoji,
              label: e.key.label,
              count: e.value,
            )).toList()),
      ],
    );
  }
}

/// 心情分布柱状条
class MoodDistributionBars extends StatelessWidget {
  final Map<Mood, int> distribution;

  const MoodDistributionBars({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('心情分布', style: textTheme.h4),
        const SizedBox(height: 12),
        ..._buildBars(context, distribution.entries.map((e) => _BarEntry(
              emoji: e.key.emoji,
              label: e.key.label,
              count: e.value,
            )).toList()),
      ],
    );
  }
}

class _BarEntry {
  final String emoji;
  final String label;
  final int count;
  const _BarEntry({required this.emoji, required this.label, required this.count});
}

List<Widget> _buildBars(BuildContext context, List<_BarEntry> entries) {
  final scheme = ShadTheme.of(context).colorScheme;
  final textTheme = ShadTheme.of(context).textTheme;
  final maxCount = entries.fold<int>(0, (max, e) => e.count > max ? e.count : max);
  final total = entries.fold<int>(0, (sum, e) => sum + e.count);

  return entries.map((entry) {
    final ratio = maxCount > 0 ? entry.count / maxCount : 0.0;
    final pct = total > 0 ? (entry.count / total * 100).toStringAsFixed(0) : '0';
    final highlight = entry.count == maxCount && maxCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(entry.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              entry.label,
              style: textTheme.p.copyWith(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: scheme.muted.withValues(alpha: 0.3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: highlight
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${entry.count}',
              style: textTheme.p.copyWith(
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: textTheme.small.copyWith(color: scheme.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }).toList();
}
