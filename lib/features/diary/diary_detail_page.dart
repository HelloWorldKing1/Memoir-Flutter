import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_router.dart';
import '../../data/models/enums.dart';
import 'diary_notifier.dart';

/// 日记详情页（查看模式）
class DiaryDetailPage extends ConsumerWidget {
  final String diaryId;

  const DiaryDetailPage({super.key, required this.diaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (diaryId.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('无效的日记 ID')),
      );
    }

    final diaryAsync = ref.watch(diaryProvider(diaryId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          diaryAsync.whenOrNull(data: (diary) {
                if (diary == null) return null;
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(
                    AppRoutes.diaryEdit.replaceFirst(':id', diaryId),
                  ),
                  tooltip: '编辑',
                );
              }),
          diaryAsync.whenOrNull(data: (diary) {
                if (diary == null) return null;
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, diaryId),
                  tooltip: '删除',
                );
              }),
        ].whereType<Widget>().toList(),
      ),
      body: diaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('加载失败', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                err.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(diaryProvider(diaryId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (diary) {
          if (diary == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('日记不存在或已被删除', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return _DiaryContent(diary: diary, theme: theme);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除日记'),
        content: const Text('确定要删除这篇日记吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final ok = await ref.read(diaryListProvider.notifier).deleteDiary(id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (ok && context.mounted) context.go(AppRoutes.home);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _DiaryContent extends StatelessWidget {
  final dynamic diary;
  final ThemeData theme;

  const _DiaryContent({required this.diary, required this.theme});

  @override
  Widget build(BuildContext context) {
    final mood = diary.mood as Mood;
    final weather = diary.weather as Weather?;
    final tags = diary.tags as List<String>;
    final date = diary.createdAt as DateTime;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                mood.value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (weather != null) ...[
                const SizedBox(width: 12),
                Text(weather.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  weather.value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            diary.title.isEmpty ? '（无标题）' : diary.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            diary.content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((tag) {
                return Chip(
                  label: Text('#$tag'),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
