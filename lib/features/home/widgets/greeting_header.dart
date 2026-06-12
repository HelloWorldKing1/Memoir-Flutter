import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

/// 问候头部组件。
///
/// 左侧：头像 + 时段问候 + 用户名称 + 日期
/// 右侧：嵌入组件（快速记录等）
class GreetingHeader extends ConsumerWidget {
  final Widget? trailing;

  const GreetingHeader({super.key, this.trailing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileVersionProvider); // 资料变更时重建
    final pb = ref.read(pbClientProvider);
    final user = pb.authStore.record;
    final userName = user?.getStringValue('name') ?? '';
    final avatar = user?.getStringValue('avatar') ?? '';
    final hasAvatar = avatar.isNotEmpty;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    final hour = now.hour;
    final (greeting, emoji) = switch (hour) {
      >= 5 && < 12 => ('早上好', '🌅'),
      >= 12 && < 18 => ('下午好', '☀️'),
      _ => ('晚上好', '🌙'),
    };

    final weekDays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final dateStr =
        '${now.year}年${now.month}月${now.day}日 ${weekDays[now.weekday - 1]}';
    final displayName = userName.isNotEmpty ? userName : '你好';

    // 头像 widget（复用桌面/移动端）
    final avatarWidget = CircleAvatar(
      radius: isDesktop ? 24 : 20,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: hasAvatar
          ? NetworkImage(pb.files.getUrl(user!, avatar).toString())
          : null,
      child: hasAvatar
          ? null
          : Text(
              (displayName.isNotEmpty ? displayName[0] : '你').toUpperCase(),
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                color: scheme.onPrimaryContainer,
              ),
            ),
    );

    if (isDesktop) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.only(left: 20, top: 16, bottom: 16, right: 16),
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
            // 头像
            avatarWidget,
            const SizedBox(width: 14),
            // 问候文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            ?trailing,
          ],
        ),
      );
    }

    // 移动 / 平板：头像 + 问候横向排列，快速记录在下方
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatarWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$emoji $greeting，$displayName！',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}
