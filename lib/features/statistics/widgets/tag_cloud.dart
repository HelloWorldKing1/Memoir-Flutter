import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../statistics_notifier.dart';

/// 标签云 — 字号按频次加权
class TagCloud extends StatelessWidget {
  final List<TagCount> tags;

  const TagCloud({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    if (tags.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('标签云', style: textTheme.h4),
          const SizedBox(height: 8),
          Text('暂无标签数据', style: textTheme.small.copyWith(color: scheme.mutedForeground)),
        ],
      );
    }

    final maxCount = tags.first.count;
    final displayTags = tags.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('标签云', style: textTheme.h4),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: displayTags.map((tag) {
            final ratio = maxCount > 0 ? tag.count / maxCount : 0.0;
            final fontSize = 11.0 + (ratio * 11.0);
            final opacity = 0.35 + (ratio * 0.65);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: opacity * 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${tag.tag}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: ratio > 0.6 ? FontWeight.w600 : FontWeight.w400,
                  color: scheme.primary.withValues(alpha: opacity),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
