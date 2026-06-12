import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_router.dart';
import '../../data/models/enums.dart';
import 'diary_notifier.dart';

/// 日记编辑器（新建 + 编辑）
///
/// [diaryId] 为 null 时是新建模式，否则是编辑模式。
/// [initialEntryType] 新建模式下预选的记录类型（从快速记录入口传入）。
/// 支持 Markdown 编辑与实时预览切换。
class DiaryEditorPage extends ConsumerStatefulWidget {
  final String? diaryId;
  final EntryType? initialEntryType;

  const DiaryEditorPage({super.key, this.diaryId, this.initialEntryType});

  @override
  ConsumerState<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends ConsumerState<DiaryEditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  EntryType _entryType = EntryType.diary;
  Mood _mood = Mood.neutral;
  Weather? _weather;
  final List<String> _tags = [];
  bool _isSaving = false;
  bool _isEditMode = false;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.diaryId != null;
    if (_isEditMode) {
      Future.microtask(() => _loadDiary());
    } else if (widget.initialEntryType != null) {
      _entryType = widget.initialEntryType!;
    }
  }

  Future<void> _loadDiary() async {
    final diary = await ref.read(diaryProvider(widget.diaryId!).future);
    if (diary == null || !mounted) return;

    setState(() {
      _titleCtrl.text = diary.title;
      _contentCtrl.text = diary.content;
      _entryType = diary.entryType;
      _mood = diary.mood;
      _weather = diary.weather;
      _tags.addAll(diary.tags);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题或内容至少填写一项')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(diaryListProvider.notifier);

    if (_isEditMode) {
      final diary = await ref.read(diaryProvider(widget.diaryId!).future);
      if (diary == null) return;

      final updated = diary.copyWith(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
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
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_isEditMode ? '编辑记录' : '写记录'),
        actions: [
          // 编辑 / 预览切换
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('编辑'), icon: Icon(Icons.edit, size: 16)),
              ButtonSegment(value: true, label: Text('预览'), icon: Icon(Icons.visibility, size: 16)),
            ],
            selected: {_isPreview},
            onSelectionChanged: (v) => setState(() => _isPreview = v.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop ? _buildWideLayout(theme) : _buildNarrowLayout(theme),
    );
  }

  /// 宽屏布局：编辑/预览区 + 元数据侧栏
  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _isPreview ? _buildPreview(theme) : _buildEditor(theme),
        ),
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: _buildMetaPanel(theme),
        ),
      ],
    );
  }

  /// 窄屏布局：元数据在上，编辑/预览区在下
  Widget _buildNarrowLayout(ThemeData theme) {
    // 移动端给编辑器一个固定最小高度，避免 Expanded 在
    // SingleChildScrollView 中产生无界约束错误。
    final screenHeight = MediaQuery.of(context).size.height;
    final editorMinHeight = (screenHeight * 0.45).clamp(200.0, 500.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetaPanel(theme),
          const SizedBox(height: 16),
          if (_isPreview)
            _buildPreview(theme)
          else
            SizedBox(
              height: editorMinHeight,
              child: _buildEditor(theme),
            ),
        ],
      ),
    );
  }

  /// 编辑区
  Widget _buildEditor(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              style: theme.textTheme.titleLarge,
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextFormField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: '开始书写...（支持 Markdown）',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Markdown 预览区
  Widget _buildPreview(ThemeData theme) {
    final content = _contentCtrl.text.trim();
    final title = _titleCtrl.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 12),
          ],
          if (content.isEmpty)
            Text(
              '（暂无内容）',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            MarkdownBody(
              data: content,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                h1: theme.textTheme.headlineMedium,
                h2: theme.textTheme.titleLarge,
                h3: theme.textTheme.titleMedium,
                p: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                code: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  fontSize: 13,
                ),
                codeblockDecoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 元数据面板：心情、天气、标签
  Widget _buildMetaPanel(ThemeData theme) {
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 记录类型
            Text('类型', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: EntryType.values.map((type) {
                final selected = _entryType == type;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => setState(() => _entryType = type),
                  label: Text('${type.emoji} ${type.label}'),
                  selectedColor: scheme.primaryContainer,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('心情', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: Mood.values.map((mood) {
                final selected = _mood == mood;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => setState(() => _mood = mood),
                  label: Text('${mood.emoji} ${mood.label}'),
                  selectedColor: scheme.primaryContainer,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('天气（可选）', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: Weather.values.map((weather) {
                final selected = _weather == weather;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _weather = selected ? null : weather),
                  label: Text('${weather.emoji} ${weather.label}'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('标签', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: '输入标签',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_circle_outlined),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
