import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/di/providers.dart';

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameCtrl = TextEditingController();
  bool _isEditingName = false;
  bool _isSaving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final pb = ref.read(pbClientProvider);
    final user = pb.authStore.record;
    _nameCtrl.text = user?.getStringValue('name') ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── 保存昵称 ──────────────────────────────────────────

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final pb = ref.read(pbClientProvider);
      final userId = pb.authStore.record?.id;
      if (userId == null) return;

      await pb.collection('users').update(userId, body: {'name': name});
      // 刷新 auth store 并通知侧边栏等组件更新
      await pb.collection('users').authRefresh();
      ref.read(profileVersionProvider.notifier).increment();

      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('昵称已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    }
  }

  // ─── 修改头像 ──────────────────────────────────────────

  Future<void> _changeAvatar() async {
    final pb = ref.read(pbClientProvider);
    final userId = pb.authStore.record?.id;
    if (userId == null) return;

    // 选择来源
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // 选取图片
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      // 读取图片字节（Web/Native 通用）
      final bytes = await picked.readAsBytes();
      final file = http.MultipartFile.fromBytes('avatar', bytes,
          filename: picked.name);
      // PocketBase SDK file upload: 用 files 参数而非 body
      await pb.collection('users').update(userId, files: [file]);
      // 刷新 auth store 并通知侧边栏等组件更新
      await pb.collection('users').authRefresh();
      ref.read(profileVersionProvider.notifier).increment();

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败：$e')),
        );
      }
    }
  }

  // ─── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pb = ref.watch(pbClientProvider);
    final user = pb.authStore.record;
    final userName = user?.getStringValue('name') ?? '';
    final userEmail = user?.getStringValue('email') ?? '';
    final avatarUrl = _avatarUrl(pb, user);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 用户信息 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 头像
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _isSaving ? null : _changeAvatar,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: scheme.primaryContainer,
                          backgroundImage:
                              avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null
                              ? Text(
                                  (userName.isNotEmpty ? userName[0] : 'U').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _isSaving ? null : _changeAvatar,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: scheme.surface, width: 2),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.camera_alt,
                                    size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 昵称
                  _isEditingName
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  labelText: '昵称',
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _saveName(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: _isSaving ? null : _saveName,
                              tooltip: '保存',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() => _isEditingName = false);
                                _nameCtrl.text = userName;
                              },
                              tooltip: '取消',
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _isEditingName = true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  userName.isNotEmpty ? userName : '未设置昵称',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.edit_outlined,
                                  size: 16, color: scheme.outline),
                            ],
                          ),
                        ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 外观 ──
          Card(
            child: SwitchListTile(
              title: const Text('深色模式'),
              subtitle: Text(
                '跟随系统设置',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请在系统设置中切换主题模式')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── 数据 ──
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

          // ── 关于 ──
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于 Memoir'),
              subtitle: const Text('v1.0.0 · Flutter 多端互通版'),
            ),
          ),
          const SizedBox(height: 24),

          // ── 登出 ──
          OutlinedButton.icon(
            onPressed: () => pb.authStore.clear(),
            icon: const Icon(Icons.logout),
            label: const Text('退出登录'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 获取用户头像 URL
  String? _avatarUrl(PocketBase pb, RecordModel? user) {
    if (user == null) return null;
    final avatar = user.getStringValue('avatar');
    if (avatar.isEmpty) return null;
    return pb.files.getUrl(user, avatar).toString();
  }
}
