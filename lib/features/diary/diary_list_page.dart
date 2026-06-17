import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(diaryListProvider.notifier).loadDiaries();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(diaryListProvider.notifier).setSearchQuery(value.trim());
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearchChanged('');
    setState(() => _showSearch = false);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(diaryListProvider);

    return Scaffold(
      appBar: _showSearch
          ? AppBar(
              leading: BackButton(
                onPressed: _clearSearch,
              ),
              title: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索标题、内容、标签…',
                  border: InputBorder.none,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            )
          : AppBar(
              title: const Text('全部记录'),
              actions: [
                ShadIconButton.ghost(
                  icon: const Icon(LucideIcons.search),
                  onPressed: () => setState(() => _showSearch = true),
                ),
                ShadIconButton.ghost(
                  icon: const Icon(LucideIcons.plus),
                  onPressed: () => context.push(AppRoutes.diaryNew),
                ),
              ],
            ),
      body: Column(
        children: [
          if (listState.isSearching && !_showSearch)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ShadBadge.secondary(
                    child: InkWell(
                      onTap: _clearSearch,
                      child: Text('🔍 ${listState.searchQuery} ✕'),
                    ),
                  ),
                ],
              ),
            ),
          _MoodFilterBar(
            selected: listState.filterMood,
            onChanged: (mood) {
              ref.read(diaryListProvider.notifier).setMoodFilter(mood);
            },
          ),
          Expanded(child: _buildList(listState)),
        ],
      ),
    );
  }

  Widget _buildList(DiaryListState state) {
    final scheme = ShadTheme.of(context).colorScheme;
    final textTheme = ShadTheme.of(context).textTheme;

    if (state.isLoading && state.diaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.diaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.cloudOff, size: 48, color: scheme.destructive),
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: scheme.destructive),
            ),
            const SizedBox(height: 12),
            ShadButton.outline(
              onPressed: () =>
                  ref.read(diaryListProvider.notifier).loadDiaries(refresh: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.diaries.isEmpty) {
      final isSearching = state.isSearching;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? LucideIcons.searchX : LucideIcons.bookOpen,
              size: 64,
              color: scheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? '未找到匹配的记录' : '还没有记录',
              style: textTheme.p.copyWith(color: scheme.mutedForeground),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching ? '试试其他关键词' : '点击右上角 + 开始书写',
              style: textTheme.small.copyWith(color: scheme.mutedForeground),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '找到 ${state.diaries.length} 条结果',
              style: textTheme.small.copyWith(color: scheme.mutedForeground),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(diaryListProvider.notifier)
                  .loadDiaries(refresh: true);
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
          ),
        ),
      ],
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
                label: m.label,
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
    return isSelected
        ? ShadBadge(
            child: InkWell(
              onTap: onTap,
              child: Text('$emoji $label', style: const TextStyle(fontSize: 13)),
            ),
          )
        : ShadBadge.secondary(
            child: InkWell(
              onTap: onTap,
              child: Text('$emoji $label', style: const TextStyle(fontSize: 13)),
            ),
          );
  }
}

/// 日记卡片
class _DiaryCard extends ConsumerWidget {
  final Diary diary;

  const _DiaryCard({required this.diary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
    final date = diary.createdAt;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
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
                    Text(diary.entryType.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(diary.mood.emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        diary.title.isEmpty ? '（无标题）' : diary.title,
                        style: textTheme.p.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: textTheme.small.copyWith(
                        color: scheme.mutedForeground,
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
                    style: textTheme.small.copyWith(
                      color: scheme.mutedForeground,
                    ),
                  ),
                ],
                if (diary.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: diary.tags.map((tag) {
                      return ShadBadge.secondary(
                        child: Text('#$tag', style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
