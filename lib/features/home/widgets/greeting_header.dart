import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/di/providers.dart';

/// 问候头部组件。
class GreetingHeader extends ConsumerWidget {
  final Widget? trailing;

  const GreetingHeader({super.key, this.trailing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileVersionProvider);
    final pb = ref.read(pbClientProvider);
    final user = pb.authStore.record;
    final userName = user?.getStringValue('name') ?? '';
    final avatar = user?.getStringValue('avatar') ?? '';
    final hasAvatar = avatar.isNotEmpty;

    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
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

    final avatarWidget = ShadAvatar(
      hasAvatar ? pb.files.getUrl(user!, avatar).toString() : '',
      placeholder: Text(
        (displayName.isNotEmpty ? displayName[0] : '你').toUpperCase(),
      ),
      size: Size.square(isDesktop ? 56 : 48),
    );

    if (isDesktop) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.only(left: 24, top: 28, bottom: 28, right: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.08),
              scheme.secondary.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            avatarWidget,
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$emoji $greeting，$displayName！',
                    style: textTheme.h3,
                  ),
                  const SizedBox(height: 6),
                  Text(dateStr, style: textTheme.muted),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (trailing != null) trailing!,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      style: textTheme.h4,
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr, style: textTheme.muted),
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
