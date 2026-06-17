import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/di/providers.dart';
import '../../core/themes/theme_notifier.dart';

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

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final pb = ref.read(pbClientProvider);
      final userId = pb.authStore.record?.id;
      if (userId == null) return;

      await pb.collection('users').update(userId, body: {'name': name});
      await pb.collection('users').authRefresh();
      ref.read(profileVersionProvider.notifier).increment();

      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSaving = false;
        });
        ShadToaster.of(context).show(
          const ShadToast(title: Text('昵称已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(title: Text('保存失败：$e')),
        );
      }
    }
  }

  Future<void> _changeAvatar() async {
    final pb = ref.read(pbClientProvider);
    final userId = pb.authStore.record?.id;
    if (userId == null) return;

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
      final bytes = await picked.readAsBytes();
      final file = http.MultipartFile.fromBytes('avatar', bytes,
          filename: picked.name);
      await pb.collection('users').update(userId, files: [file]);
      await pb.collection('users').authRefresh();
      ref.read(profileVersionProvider.notifier).increment();

      if (mounted) {
        setState(() => _isSaving = false);
        ShadToaster.of(context).show(
          const ShadToast(title: Text('头像已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(title: Text('上传失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
    final pb = ref.watch(pbClientProvider);
    final user = pb.authStore.record;
    final userName = user?.getStringValue('name') ?? '';
    final userEmail = user?.getStringValue('email') ?? '';
    final avatarUrl = _avatarUrl(pb, user);
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 用户信息 ──
          ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _isSaving ? null : _changeAvatar,
                        child: ShadAvatar(
                          avatarUrl ?? '',
                          placeholder: Text(
                            (userName.isNotEmpty ? userName[0] : 'U')
                                .toUpperCase(),
                          ),
                          size: const Size.square(80),
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
                              border: Border.all(
                                  color: scheme.background, width: 2),
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
                                : const Icon(LucideIcons.camera,
                                    size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _isEditingName
                      ? Row(
                          children: [
                            Expanded(
                              child: ShadInput(
                                controller: _nameCtrl,
                                placeholder: const Text('昵称'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ShadIconButton.ghost(
                              icon: const Icon(LucideIcons.check,
                                  size: 18, color: Colors.green),
                              onPressed: _isSaving ? null : _saveName,
                            ),
                            ShadIconButton.ghost(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                setState(() => _isEditingName = false);
                                _nameCtrl.text = userName;
                              },
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
                                  style: textTheme.p.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(LucideIcons.pencil,
                                  size: 16, color: scheme.mutedForeground),
                            ],
                          ),
                        ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: textTheme.small.copyWith(
                      color: scheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 外观 ──
          ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('外观', style: textTheme.small),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ThemeModeOption(
                        label: '亮色',
                        icon: LucideIcons.sun,
                        selected: currentThemeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 8),
                      _ThemeModeOption(
                        label: '暗色',
                        icon: LucideIcons.moon,
                        selected: currentThemeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                      const SizedBox(width: 8),
                      _ThemeModeOption(
                        label: '跟随系统',
                        icon: LucideIcons.monitor,
                        selected: currentThemeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 数据 ──
          ShadCard(
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(LucideIcons.download),
                    title: const Text('导出数据'),
                    subtitle: const Text('导出所有日记为 JSON 文件'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ShadToaster.of(context).show(
                        const ShadToast(title: Text('导出功能开发中')),
                      );
                    },
                  ),
                ),
                const ShadSeparator.horizontal(),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: const Icon(LucideIcons.upload),
                    title: const Text('导入数据'),
                    subtitle: const Text('从 JSON 文件导入日记'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ShadToaster.of(context).show(
                        const ShadToast(title: Text('导入功能开发中')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 关于 ──
          ShadCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(LucideIcons.info),
                title: const Text('关于 Memoir'),
                subtitle: const Text('v1.0.0 · Flutter 多端互通版'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── 登出 ──
          ShadButton.outline(
            onPressed: () => pb.authStore.clear(),
            leading: Icon(LucideIcons.logOut,
                size: 18, color: scheme.destructive),
            width: double.infinity,
            child: Text(
              '退出登录',
              style: TextStyle(color: scheme.destructive),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String? _avatarUrl(PocketBase pb, RecordModel? user) {
    if (user == null) return null;
    final avatar = user.getStringValue('avatar');
    if (avatar.isEmpty) return null;
    return pb.files.getUrl(user, avatar).toString();
  }
}

/// 主题模式选项按钮
class _ThemeModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: selected
          ? ShadButton(
              onPressed: onTap,
              leading: Icon(icon, size: 16),
              child: Text(label, style: const TextStyle(fontSize: 12)),
            )
          : ShadButton.outline(
              onPressed: onTap,
              leading: Icon(icon, size: 16),
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
    );
  }
}
