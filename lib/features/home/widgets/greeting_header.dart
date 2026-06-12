import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

/// 问候头部组件。
///
/// 根据当前时间显示不同的问候语，并展示用户名称与当前日期。
/// 桌面端附带装饰性渐变背景 + 右侧可嵌入快速记录等组件；
/// 平板/移动端为纯文字 + 下方紧凑快录入口。
class GreetingHeader extends ConsumerWidget {
  /// 右侧嵌入的组件（桌面端显示在问候语右侧，平板/移动端显示在下方）。
  final Widget? trailing;

  const GreetingHeader({super.key, this.trailing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pb = ref.watch(pbClientProvider);
    final user = pb.authStore.record;
    final userName = user?.getStringValue('name') ?? '';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    // 时段化问候
    final hour = now.hour;
    final (greeting, emoji) = switch (hour) {
      >= 5 && < 12 => ('早上好', '🌅'),
      >= 12 && < 18 => ('下午好', '☀️'),
      _ => ('晚上好', '🌙'),
    };

    // 日期格式化（中文习惯）
    final weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final dateStr =
        '${now.year}年${now.month}月${now.day}日 ${weekDays[now.weekday - 1]}';

    final displayName = userName.isNotEmpty ? userName : '你好';

    if (isDesktop) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.4),
              scheme.secondaryContainer.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 左侧：问候文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$emoji $greeting，$displayName！',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 右侧：嵌入组件（快速记录）
            ?trailing,
          ],
        ),
      );
    }

    // 移动 / 平板：问候文字在上，trailing 在下
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $greeting，$displayName！',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
