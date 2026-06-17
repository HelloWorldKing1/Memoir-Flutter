import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/di/providers.dart';
import '../../core/routes/app_router.dart';
import '../../core/themes/theme_notifier.dart';

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

    if (isMobile) return _MobileShell(child: child,);

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
            color: ShadTheme.of(context).colorScheme.border,
          ),
        ),
      ),
      child: Column(
        children: [
          _SidebarHeader(),
          const ShadSeparator.horizontal(),
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
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            label: '全部',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: ShadButton(
        onPressed: () => context.push(AppRoutes.diaryNew),
        child: const Icon(LucideIcons.plus),
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
          const ShadSeparator.horizontal(),
          const Spacer(),
          _SidebarUserInfo(),
        ],
      ),
    );
  }
}

/// 侧边栏顶部标题 + 导航 + 主题按钮
class _SidebarHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final textTheme = ShadTheme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行 + 主题切换按钮
          Row(
            children: [
              Expanded(
                child: Text(
                  'Memoir ✨',
                  style: textTheme.h4,
                ),
              ),
              // 主题切换按钮（右上角）
              _ThemeToggleButton(),
            ],
          ),
          const SizedBox(height: 24),
          _NavItem(
            icon: LucideIcons.home,
            label: '首页',
            selected: location == AppRoutes.home,
            onTap: () => context.go(AppRoutes.home),
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: LucideIcons.book,
            label: '全部',
            selected: location == AppRoutes.diaryList,
            onTap: () => context.go(AppRoutes.diaryList),
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: LucideIcons.barChart3,
            label: '统计',
            selected: location == AppRoutes.statistics,
            onTap: () => context.go(AppRoutes.statistics),
          ),
          const SizedBox(height: 4),
          _NavItem(
            icon: LucideIcons.settings,
            label: '设置',
            selected: location == AppRoutes.settings,
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

/// 主题切换按钮（点击弹出 Popover 下拉选择）
class _ThemeToggleButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends ConsumerState<_ThemeToggleButton> {
  final _popoverCtrl = ShadPopoverController();

  @override
  void dispose() {
    _popoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(themeModeProvider);
    final currentScheme = ref.watch(colorSchemeProvider);

    return ShadPopover(
      controller: _popoverCtrl,
      popover: (_) => _ThemePopoverContent(
        currentMode: currentMode,
        currentScheme: currentScheme,
        onModeChanged: (mode) =>
            ref.read(themeModeProvider.notifier).setThemeMode(mode),
        onSchemeChanged: (name) =>
            ref.read(colorSchemeProvider.notifier).setColorScheme(name),
      ),
      child: ShadIconButton.ghost(
        icon: const Icon(LucideIcons.palette),
        iconSize: 20,
        onPressed: _popoverCtrl.toggle,
      ),
    );
  }
}

/// 主题 Popover 内容：主题模式按钮组 + 颜色方案网格
class _ThemePopoverContent extends StatelessWidget {
  final ThemeMode currentMode;
  final String currentScheme;
  final ValueChanged<ThemeMode> onModeChanged;
  final ValueChanged<String> onSchemeChanged;

  const _ThemePopoverContent({
    required this.currentMode,
    required this.currentScheme,
    required this.onModeChanged,
    required this.onSchemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;

    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('外观设置', style: textTheme.h4),
          // const SizedBox(height: 2),
          // Text('选择主题模式和颜色方案', style: textTheme.muted),
          // const SizedBox(height: 14),

          // 主题模式
          Text('主题模式', style: textTheme.small),
          const SizedBox(height: 6),
          Row(
            children: [
              _ModeBtn(
                label: '☀️  亮色',
                selected: currentMode == ThemeMode.light,
                onTap: () => onModeChanged(ThemeMode.light),
              ),
              const SizedBox(width: 6),
              _ModeBtn(
                label: '🌙  暗色',
                selected: currentMode == ThemeMode.dark,
                onTap: () => onModeChanged(ThemeMode.dark),
              ),
              const SizedBox(width: 6),
              _ModeBtn(
                label: '💻  系统',
                selected: currentMode == ThemeMode.system,
                onTap: () => onModeChanged(ThemeMode.system),
              ),
            ],
          ),

          const SizedBox(height: 16),
          ShadSeparator.horizontal(),
          const SizedBox(height: 12),

          // 颜色方案
          Text('颜色方案', style: textTheme.small),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableColorSchemes.map((name) {
              final label = colorSchemeLabels[name] ?? name;
              final color = colorSchemePreviewColors[name]!;
              final selected = name == currentScheme;
              return _ColorBtn(
                label: label,
                color: color,
                selected: selected,
                onTap: () => onSchemeChanged(name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 主题模式按钮
class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: selected
          ? ShadButton(
              onPressed: onTap,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            )
          : ShadButton.outline(
              onPressed: onTap,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
    );
  }
}

/// 颜色方案按钮
class _ColorBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorBtn({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.foreground : scheme.border,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
              : null,
        ),
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
    final scheme = ShadTheme.of(context).colorScheme;

    return ShadButton.ghost(
      onPressed: onTap,
      leading: Icon(
        icon,
        size: 20,
        color: selected ? scheme.primary : scheme.mutedForeground,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? scheme.primary : scheme.foreground,
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
    final textTheme = ShadTheme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ShadAvatar(
            hasAvatar
                ? pb.files.getUrl(user!, avatar).toString()
                : '',
            placeholder: Text(
              (userName.isNotEmpty ? userName[0] : 'U').toUpperCase(),
            ),
            size: const Size.square(32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              userName.isNotEmpty ? userName : (userEmail.isNotEmpty ? userEmail : '未登录'),
              overflow: TextOverflow.ellipsis,
              style: textTheme.small,
            ),
          ),
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.logOut, size: 18),
            onPressed: () {
              pb.authStore.clear();
            },
          ),
        ],
      ),
    );
  }
}
