import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes/app_router.dart';
import '../../data/models/enums.dart';
import 'diary_notifier.dart';

/// 日记编辑器（新建 + 编辑）
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
    final scheme = ShadTheme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_isEditMode ? '编辑记录' : '写记录'),
        actions: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: false,
                  label: Text('编辑'),
                  icon: Icon(Icons.edit, size: 16)),
              ButtonSegment(
                  value: true,
                  label: Text('预览'),
                  icon: Icon(Icons.visibility, size: 16)),
            ],
            selected: {_isPreview},
            onSelectionChanged: (v) => setState(() => _isPreview = v.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
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
      body: isDesktop ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _isPreview ? _buildPreview() : _buildEditor(),
        ),
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: _buildMetaPanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final editorMinHeight = (screenHeight * 0.45).clamp(200.0, 500.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetaPanel(),
          const SizedBox(height: 16),
          if (_isPreview)
            _buildPreview()
          else
            SizedBox(height: editorMinHeight, child: _buildEditor()),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final textTheme = ShadTheme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              style: textTheme.large,
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
                style: const TextStyle(
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

  Widget _buildPreview() {
    final content = _contentCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
    final themeData = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: textTheme.h3),
            const SizedBox(height: 4),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 12),
          ],
          if (content.isEmpty)
            Text(
              '（暂无内容）',
              style: TextStyle(
                color: scheme.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            MarkdownBody(
              data: content,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(themeData).copyWith(
                h1: themeData.textTheme.headlineMedium,
                h2: themeData.textTheme.titleLarge,
                h3: themeData.textTheme.titleMedium,
                p: themeData.textTheme.bodyLarge?.copyWith(height: 1.8),
                code: themeData.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: themeData.colorScheme.surfaceContainerHighest,
                  fontSize: 13,
                ),
                codeblockDecoration: BoxDecoration(
                  color: themeData.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: scheme.primary, width: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
