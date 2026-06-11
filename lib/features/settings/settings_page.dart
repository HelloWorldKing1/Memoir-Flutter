import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pb = ref.read(pbClientProvider);
    final user = pb.authStore.record;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      (user?.getStringValue('name') ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.getStringValue('name') ?? '未设置昵称',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.getStringValue('email') ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 外观
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('深色模式'),
                  subtitle: Text(
                    '跟随系统设置，手动切换需在系统设置中调整',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (_) {
                    // TODO: 手动主题切换
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请在系统设置中切换主题模式')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 数据
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('导出数据'),
                  subtitle: const Text('导出所有日记为 JSON 文件'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('导出功能开发中')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('导入数据'),
                  subtitle: const Text('从 JSON 文件导入日记'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('导入功能开发中')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 关于
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于 Memoir'),
                  subtitle: const Text('v1.0.0 · Flutter 多端互通版'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 登出
          OutlinedButton.icon(
            onPressed: () {
              pb.authStore.clear();
            },
            icon: const Icon(Icons.logout),
            label: const Text('退出登录'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
