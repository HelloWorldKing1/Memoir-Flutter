import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/routes/app_router.dart';

/// 响应式应用外壳
///
/// 桌面 (>=1200)：左侧常驻侧边栏 + 主内容
/// 平板 (600~1199)：抽屉式侧边栏
/// 移动 (<600)：底部导航栏
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1200;
    final isMobile = width < 600;

    if (isMobile) return _MobileShell(child: child);

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            const _DesktopSidebar()
          else
            const SizedBox.shrink(),
          Expanded(child: child),
        ],
      ),
      drawer: isDesktop ? null : const _DrawerSidebar(),
    );
  }
}

/// 桌面常驻侧边栏
class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          _SidebarHeader(),
          const Divider(height: 1),
          const Spacer(),
          _SidebarUserInfo(),
        ],
      ),
    );
  }
}

/// 移动端底部导航
class _MobileShell extends ConsumerWidget {
  final Widget child;

  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex;
    if (location == AppRoutes.home) {
      selectedIndex = 0;
    } else if (location == AppRoutes.diaryList) {
      selectedIndex = 1;
    } else if (location == AppRoutes.statistics) {
      selectedIndex = 2;
    } else if (location == AppRoutes.settings) {
      selectedIndex = 3;
    } else {
      selectedIndex = -1;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.diaryList);
            case 2:
              context.go(AppRoutes.statistics);
            case 3:
              context.go(AppRoutes.settings);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: '全部'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: '统计'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '设置'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.diaryNew),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 抽屉侧边栏
class _DrawerSidebar extends ConsumerWidget {
  const _DrawerSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          _SidebarHeader(),
          const Divider(height: 1),
          const Spacer(),
          _SidebarUserInfo(),
        ],
      ),
    );
  }
}

/// 侧边栏顶部标题 + 导航
class _SidebarHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memoir ✨',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _NavItem(
            icon: Icons.home_outlined,
            label: '首页',
            selected: location == AppRoutes.home,
            onTap: () => context.go(AppRoutes.home),
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: Icons.book_outlined,
            label: '全部',
            selected: location == AppRoutes.diaryList,
            onTap: () => context.go(AppRoutes.diaryList),
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            label: '统计',
            selected: location == AppRoutes.statistics,
            onTap: () => context.go(AppRoutes.statistics),
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: Icons.settings_outlined,
            label: '设置',
            selected: location == AppRoutes.settings,
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

/// 导航项
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.4) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? scheme.primary : null),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 侧边栏底部用户信息 + 登出
class _SidebarUserInfo extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileVersionProvider); // 资料变更时重建
    final pb = ref.read(pbClientProvider);
    final user = pb.authStore.record;
    final userName = user?.getStringValue('name') ?? '';
    final userEmail = user?.getStringValue('email') ?? '';
    final avatar = user?.getStringValue('avatar') ?? '';
    final hasAvatar = avatar.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: hasAvatar
                ? NetworkImage(pb.files.getUrl(user!, avatar).toString())
                : null,
            child: hasAvatar
                ? null
                : Text(
                    (userName.isNotEmpty ? userName[0] : 'U').toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              userName.isNotEmpty ? userName : (userEmail.isNotEmpty ? userEmail : '未登录'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18),
            onPressed: () {
              pb.authStore.clear();
            },
            tooltip: '登出',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
