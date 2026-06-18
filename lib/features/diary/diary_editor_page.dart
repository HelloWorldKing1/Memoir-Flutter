import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import '../../core/routes/app_router.dart';
import '../../data/models/enums.dart';
import 'diary_notifier.dart';

/// 日记编辑器（新建 + 编辑）
///
/// 基于 AppFlowyEditor 提供完整的所见即所得富文本编辑体验：
/// - 固定工具栏（段落 / 标题 / 加粗斜体 / 列表 / 引用 / 链接）
/// - Markdown 快捷键原生支持（# → 标题, ** → 加粗, - → 列表等）
/// - / 斜杠命令选择菜单
/// - 浮动选区工具栏
/// - 内容以 Markdown 格式存储，与 PocketBase 完全兼容
class DiaryEditorPage extends ConsumerStatefulWidget {
  final String? diaryId;
  final EntryType? initialEntryType;

  const DiaryEditorPage({super.key, this.diaryId, this.initialEntryType});

  @override
  ConsumerState<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends ConsumerState<DiaryEditorPage> {
  final _titleCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  /// AppFlowyEditor 核心状态 — 持有文档节点树
  late EditorState _editorState;

  /// 编辑器滚动控制器（供工具栏使用）
  late EditorScrollController _editorScrollController;

  EntryType _entryType = EntryType.diary;
  Mood _mood = Mood.neutral;
  Weather? _weather;
  final List<String> _tags = [];
  bool _isSaving = false;
  bool _isEditMode = false;
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.diaryId != null;

    // 新建模式：直接创建空白编辑器
    // 编辑模式：先创建空白占位，等数据加载后再替换
    _editorState = EditorState.blank(withInitialText: true);
    _editorScrollController =
        EditorScrollController(editorState: _editorState);

    // 监听选区变化以刷新工具栏高亮状态
    _editorState.selectionNotifier.addListener(_onSelectionChanged);

    if (_isEditMode) {
      _isLoadingContent = true;
      Future.microtask(() => _loadDiary());
    } else if (widget.initialEntryType != null) {
      _entryType = widget.initialEntryType!;
    }
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDiary() async {
    final diary = await ref.read(diaryProvider(widget.diaryId!).future);
    if (diary == null || !mounted) return;

    setState(() {
      _titleCtrl.text = diary.title;
      _entryType = diary.entryType;
      _mood = diary.mood;
      _weather = diary.weather;
      _tags.addAll(diary.tags);

      // 从 Markdown 还原为富文本文档
      final oldEditorState = _editorState;
      if (diary.content.isNotEmpty) {
        try {
          final document = markdownToDocument(diary.content);
          _editorState = EditorState(document: document);
        } catch (_) {
          // Markdown 解析失败时回退到原始文本
          _editorState = EditorState.blank(withInitialText: true);
          _editorState.insertTextAtPosition(diary.content);
        }
      } else {
        _editorState = EditorState.blank(withInitialText: true);
      }

      // 迁移监听器到新的 editorState
      oldEditorState.selectionNotifier.removeListener(_onSelectionChanged);
      _editorState.selectionNotifier.addListener(_onSelectionChanged);

      // 重建滚动控制器以关联新的 editorState
      _editorScrollController.dispose();
      _editorScrollController =
          EditorScrollController(editorState: _editorState);

      _isLoadingContent = false;
    });
  }

  @override
  void dispose() {
    _editorState.selectionNotifier.removeListener(_onSelectionChanged);
    _titleCtrl.dispose();
    _tagCtrl.dispose();
    _editorState.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 标签
  // ---------------------------------------------------------------------------

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  // ---------------------------------------------------------------------------
  // 保存
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = documentToMarkdown(_editorState.document).trim();

    if (title.isEmpty && content.isEmpty) {
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('标题或内容至少填写一项'),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(diaryListProvider.notifier);

    if (_isEditMode) {
      final diary = await ref.read(diaryProvider(widget.diaryId!).future);
      if (diary == null) return;

      final updated = diary.copyWith(
        title: title,
        content: content,
        entryType: _entryType,
        mood: _mood,
        weather: _weather,
        tags: _tags,
      );

      final ok = await notifier.updateDiary(widget.diaryId!, updated);
      if (mounted) {
        setState(() => _isSaving = false);
        if (ok) context.go(AppRoutes.home);
      }
    } else {
      final diary = await notifier.createDiary(
        title: title,
        content: content,
        entryType: _entryType,
        mood: _mood,
        weather: _weather,
        tags: _tags,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (diary != null) context.go(AppRoutes.home);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_isEditMode ? '编辑记录' : '写记录'),
        actions: [
          ShadButton(
            onPressed: _isSaving ? null : _save,
            leading: _isSaving
                ? SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primaryForeground,
                    ),
                  )
                : null,
            child: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop ? _buildWideLayout(scheme) : _buildNarrowLayout(scheme),
    );
  }

  Widget _buildWideLayout(ShadColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildEditor(scheme),
        ),
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: _buildMetaPanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(ShadColorScheme scheme) {
    final screenHeight = MediaQuery.of(context).size.height;
    final editorMinHeight = (screenHeight * 0.45).clamp(200.0, 500.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetaPanel(),
          const SizedBox(height: 16),
          SizedBox(
            height: editorMinHeight,
            child: _buildEditor(scheme),
          ),
        ],
      ),
    );
  }

  /// 构建完整的富文本编辑器（含工具栏 + 编辑区）
  Widget _buildEditor(ShadColorScheme scheme) {
    final textTheme = ShadTheme.of(context).textTheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (_isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── 编辑器主题配置 ──
    final editorStyle = EditorStyle.desktop(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.25),
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          height: 1.8,
          fontSize: 15,
          color: scheme.foreground,
        ),
        bold: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: scheme.foreground,
        ),
        italic: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 15,
          color: scheme.foreground,
        ),
        underline: TextStyle(
          decoration: TextDecoration.underline,
          fontSize: 15,
          color: scheme.foreground,
        ),
        strikethrough: TextStyle(
          decoration: TextDecoration.lineThrough,
          fontSize: 15,
          color: scheme.mutedForeground,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: scheme.primary,
          backgroundColor: scheme.primary.withValues(alpha: 0.08),
        ),
        href: TextStyle(
          color: scheme.primary,
          decoration: TextDecoration.underline,
          fontSize: 15,
        ),
        lineHeight: 1.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 标题输入框 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: TextFormField(
            controller: _titleCtrl,
            style: textTheme.h3.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '标题',
              border: InputBorder.none,
              hintStyle: textTheme.h3.copyWith(
                color: scheme.mutedForeground,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),

        // ── 固定工具栏（桌面端） ──
        if (isDesktop) _buildDesktopToolbar(scheme),

        const ShadSeparator.horizontal(),

        // ── 富文本编辑区 ──
        Expanded(
          child: AppFlowyEditor(
            editorState: _editorState,
            editorStyle: editorStyle,
            editorScrollController: _editorScrollController,
            blockComponentBuilders: standardBlockComponentBuilderMap,
            characterShortcutEvents: [
              ...standardCharacterShortcutEvents,
              ...markdownSyntaxShortcutEvents,
            ],
            commandShortcutEvents: [
              ...standardCommandShortcutEvents,
              ...toggleMarkdownCommands,
            ],
            autoFocus: !_isEditMode,
          ),
        ),
      ],
    );
  }

  /// 桌面端固定工具栏
  ///
  /// 使用 ListenableBuilder 监听 EditorState 变化（选区、格式状态）。
  /// 按钮由 EditorState API 驱动，不依赖内置 ToolbarItem（避免空指针）。
  Widget _buildDesktopToolbar(ShadColorScheme scheme) {
    final selection = _editorState.selection;
    final hasSelection = selection != null;

    return Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: scheme.background,
            border: Border(bottom: BorderSide(color: scheme.border)),
          ),
          child: Row(
            children: [
              // ═══ 块级类型 ═══
              _ToolIconButton(
                icon: LucideIcons.pilcrow,
                tooltip: '正文',
                active: _isBlockType(ParagraphBlockKeys.type),
                enabled: hasSelection,
                onTap: () => _convertBlock(() => paragraphNode()),
              ),
              _ToolIconButton(
                icon: LucideIcons.heading1,
                tooltip: '标题 1',
                active: _isBlockType(HeadingBlockKeys.type, level: 1),
                enabled: hasSelection,
                onTap: () => _convertBlock(() => headingNode(level: 1)),
              ),
              _ToolIconButton(
                icon: LucideIcons.heading2,
                tooltip: '标题 2',
                active: _isBlockType(HeadingBlockKeys.type, level: 2),
                enabled: hasSelection,
                onTap: () => _convertBlock(() => headingNode(level: 2)),
              ),
              _ToolIconButton(
                icon: LucideIcons.heading3,
                tooltip: '标题 3',
                active: _isBlockType(HeadingBlockKeys.type, level: 3),
                enabled: hasSelection,
                onTap: () => _convertBlock(() => headingNode(level: 3)),
              ),
              _ToolSeparator(scheme),
              // ═══ 内联格式 ═══
              _ToolIconButton(
                icon: LucideIcons.bold,
                tooltip: '加粗 (Ctrl+B)',
                active: _isToggled(AppFlowyRichTextKeys.bold),
                enabled: hasSelection,
                onTap: () =>
                    _editorState.toggleAttribute(AppFlowyRichTextKeys.bold),
              ),
              _ToolIconButton(
                icon: LucideIcons.italic,
                tooltip: '斜体 (Ctrl+I)',
                active: _isToggled(AppFlowyRichTextKeys.italic),
                enabled: hasSelection,
                onTap: () =>
                    _editorState.toggleAttribute(AppFlowyRichTextKeys.italic),
              ),
              _ToolIconButton(
                icon: LucideIcons.strikethrough,
                tooltip: '删除线',
                active: _isToggled(AppFlowyRichTextKeys.strikethrough),
                enabled: hasSelection,
                onTap: () => _editorState
                    .toggleAttribute(AppFlowyRichTextKeys.strikethrough),
              ),
              _ToolIconButton(
                icon: LucideIcons.code2,
                tooltip: '行内代码',
                active: _isToggled(AppFlowyRichTextKeys.code),
                enabled: hasSelection,
                onTap: () =>
                    _editorState.toggleAttribute(AppFlowyRichTextKeys.code),
              ),
              _ToolSeparator(scheme),
              // ═══ 列表 / 引用 ═══
              _ToolIconButton(
                icon: LucideIcons.list,
                tooltip: '无序列表',
                active: _isBlockType(BulletedListBlockKeys.type),
                enabled: hasSelection,
                onTap: () => _convertBlock(() => bulletedListNode()),
              ),
              _ToolIconButton(
                icon: LucideIcons.listOrdered,
                tooltip: '有序列表',
                active: _isBlockType(NumberedListBlockKeys.type),
                enabled: hasSelection,
                onTap: () => _convertBlock(() => numberedListNode()),
              ),
              _ToolIconButton(
                icon: LucideIcons.quote,
                tooltip: '引用块',
                active: _isBlockType(QuoteBlockKeys.type),
                enabled: hasSelection,
                onTap: () => _convertBlock(() => quoteNode()),
              ),
              _ToolIconButton(
                icon: LucideIcons.minus,
                tooltip: '分割线',
                enabled: true,
                active: false,
                onTap: () {
                  final sel = _editorState.selection;
                  if (sel != null) {
                    _editorState.formatNode(sel, (_) => dividerNode());
                  }
                },
              ),
            ],
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // 工具栏辅助方法
  // ---------------------------------------------------------------------------

  /// 判断选区所在节点的类型
  bool _isBlockType(String type, {int? level}) {
    final selection = _editorState.selection;
    if (selection == null) return false;
    final node = _editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    if (node.type != type) return false;
    if (level != null && node.attributes[HeadingBlockKeys.level] != level) {
      return false;
    }
    return true;
  }

  /// 判断当前选区是否有指定属性（加粗/斜体/等）
  bool _isToggled(String key) {
    final selection = _editorState.selection;
    if (selection == null) return false;
    final nodes = _editorState.getNodesInSelection(selection);
    return nodes.every((node) {
      final delta = node.delta;
      if (delta == null || delta.isEmpty) return false;
      return delta.everyAttributes((attr) => attr[key] == true);
    });
  }

  /// 将当前节点转换为指定块类型
  void _convertBlock(Node Function() nodeBuilder) {
    final selection = _editorState.selection;
    if (selection == null) return;
    _editorState.formatNode(selection, (_) => nodeBuilder());
  }

  // ---------------------------------------------------------------------------
  // 元数据面板（类型 / 心情 / 天气 / 标签）
  // ---------------------------------------------------------------------------

  Widget _buildMetaPanel() {
    final textTheme = ShadTheme.of(context).textTheme;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('类型', style: textTheme.small),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: EntryType.values.map((type) {
                final selected = _entryType == type;
                return _SelectableBadge(
                  selected: selected,
                  onTap: () => setState(() => _entryType = type),
                  child: Text('${type.emoji} ${type.label}',
                      style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('心情', style: textTheme.small),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: Mood.values.map((mood) {
                final selected = _mood == mood;
                return _SelectableBadge(
                  selected: selected,
                  onTap: () => setState(() => _mood = mood),
                  child: Text('${mood.emoji} ${mood.label}',
                      style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('天气（可选）', style: textTheme.small),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: Weather.values.map((weather) {
                final selected = _weather == weather;
                return _SelectableBadge(
                  selected: selected,
                  onTap: () =>
                      setState(() => _weather = selected ? null : weather),
                  child: Text('${weather.emoji} ${weather.label}',
                      style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('标签', style: textTheme.small),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _tagCtrl,
                    placeholder: const Text('输入标签'),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ShadIconButton.ghost(
                  icon: const Icon(LucideIcons.plusCircle, size: 20),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags.map((tag) {
                  return ShadBadge.secondary(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$tag', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeTag(tag),
                          child: const Icon(LucideIcons.x, size: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 工具栏组件
// =============================================================================

/// 工具栏图标按钮
class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _ToolIconButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final effectiveColor = !enabled
        ? scheme.mutedForeground.withValues(alpha: 0.35)
        : active
            ? scheme.primary
            : scheme.foreground;
    final bgColor = active ? scheme.primary.withValues(alpha: 0.12) : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16, color: effectiveColor),
        ),
      ),
    );
  }
}

/// 工具栏分隔线
class _ToolSeparator extends StatelessWidget {
  final ShadColorScheme scheme;
  const _ToolSeparator(this.scheme);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: scheme.border,
    );
  }
}

// =============================================================================
// 元数据 Badge
// =============================================================================

/// 可选择的 Badge（替代 ChoiceChip）
class _SelectableBadge extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableBadge({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? ShadBadge(child: InkWell(onTap: onTap, child: child))
        : ShadBadge.secondary(
            child: InkWell(onTap: onTap, child: child),
          );
  }
}
