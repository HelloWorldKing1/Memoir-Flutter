import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_router.dart';
import '../../data/models/diary.dart';
import '../../data/models/enums.dart';
import 'diary_notifier.dart';

/// 日记列表页
class DiaryListPage extends ConsumerStatefulWidget {
  const DiaryListPage({super.key});

  @override
  ConsumerState<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends ConsumerState<DiaryListPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(diaryListProvider.notifier).loadDiaries(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(diaryListProvider.notifier).loadDiaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(diaryListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoir ✨'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.diaryNew),
            tooltip: '写日记',
          ),
        ],
      ),
      body: Column(
        children: [
          // 心情筛选栏
          _MoodFilterBar(
            selected: listState.filterMood,
            onChanged: (mood) {
              ref.read(diaryListProvider.notifier).setMoodFilter(mood);
            },
          ),
          // 日记列表
          Expanded(
            child: _buildList(listState, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildList(DiaryListState state, ThemeData theme) {
    if (state.isLoading && state.diaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.diaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  ref.read(diaryListProvider.notifier).loadDiaries(refresh: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.diaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              '还没有日记',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角 + 开始书写',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(diaryListProvider.notifier).loadDiaries(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.diaries.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.diaries.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _DiaryCard(diary: state.diaries[index]);
        },
      ),
    );
  }
}

/// 心情筛选栏
class _MoodFilterBar extends StatelessWidget {
  final Mood? selected;
  final ValueChanged<Mood?> onChanged;

  const _MoodFilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _MoodChip(
            label: '全部',
            emoji: '📋',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...Mood.values.map(
            (m) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MoodChip(
                label: m.value,
                emoji: m.emoji,
                isSelected: selected == m,
                onTap: () => onChanged(selected == m ? null : m),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 心情 chip
class _MoodChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      label: Text('$emoji $label'),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.primary,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// 日记卡片
class _DiaryCard extends ConsumerWidget {
  final Diary diary;

  const _DiaryCard({required this.diary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final date = diary.createdAt;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.diaryDetail.replaceFirst(':id', diary.id ?? ''),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(diary.mood.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      diary.title.isEmpty ? '（无标题）' : diary.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              if (diary.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  diary.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (diary.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: diary.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
