import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_router.dart';
import '../../data/models/enums.dart';
import 'diary_notifier.dart';

/// 日记编辑器（新建 + 编辑）
///
/// [diaryId] 为 null 时是新建模式，否则是编辑模式。
class DiaryEditorPage extends ConsumerStatefulWidget {
  final String? diaryId;

  const DiaryEditorPage({super.key, this.diaryId});

  @override
  ConsumerState<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends ConsumerState<DiaryEditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Mood _mood = Mood.neutral;
  Weather? _weather;
  final List<String> _tags = [];
  bool _isSaving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.diaryId != null;
    if (_isEditMode) {
      Future.microtask(() => _loadDiary());
    }
  }

  Future<void> _loadDiary() async {
    final diary = await ref.read(diaryProvider(widget.diaryId!).future);
    if (diary == null || !mounted) return;

    setState(() {
      _titleCtrl.text = diary.title;
      _contentCtrl.text = diary.content;
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
        title: Text(_isEditMode ? '编辑日记' : '写日记'),
        actions: [
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

  /// 宽屏布局：编辑区 + 元数据侧栏
  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildEditor(theme),
        ),
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          child: _buildMetaPanel(theme),
        ),
      ],
    );
  }

  /// 窄屏布局：编辑区在上，元数据在下方
  Widget _buildNarrowLayout(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetaPanel(theme),
          const SizedBox(height: 16),
          _buildEditor(theme),
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
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
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
            // 心情
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
                  label: Text('${mood.emoji} ${mood.value}'),
                  selectedColor: scheme.primaryContainer,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // 天气
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
                  label: Text('${weather.emoji} ${weather.value}'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // 标签
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
