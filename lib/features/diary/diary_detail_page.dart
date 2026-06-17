import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes/app_router.dart';
import '../../data/models/enums.dart';
import 'diary_notifier.dart';

/// 日记详情页（查看模式，Markdown 渲染）
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
    final scheme = ShadTheme.of(context).colorScheme;
    final textTheme = ShadTheme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          diaryAsync.whenOrNull(data: (diary) {
                if (diary == null) return null;
                return ShadIconButton.ghost(
                  icon: const Icon(LucideIcons.pencil, size: 20),
                  onPressed: () => context.push(
                    AppRoutes.diaryEdit.replaceFirst(':id', diaryId),
                  ),
                );
              }),
          diaryAsync.whenOrNull(data: (diary) {
                if (diary == null) return null;
                return ShadIconButton.ghost(
                  icon: const Icon(LucideIcons.trash2, size: 20),
                  onPressed: () => _confirmDelete(context, ref, diaryId),
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
              Icon(LucideIcons.alertCircle, size: 48, color: scheme.destructive),
              const SizedBox(height: 12),
              Text('加载失败', style: textTheme.p),
              const SizedBox(height: 4),
              Text(
                err.toString(),
                style: textTheme.small.copyWith(color: scheme.mutedForeground),
              ),
              const SizedBox(height: 16),
              ShadButton.outline(
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
                  Icon(LucideIcons.bookOpen, size: 48, color: scheme.mutedForeground),
                  const SizedBox(height: 12),
                  Text('日记不存在或已被删除', style: textTheme.p),
                ],
              ),
            );
          }
          return _DiaryContent(diary: diary);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showShadDialog(
      context: context,
      builder: (ctx) => ShadDialog.alert(
        title: const Text('删除日记'),
        description: const Text('确定要删除这篇日记吗？'),
        actions: [
          ShadButton.outline(
            child: const Text('取消'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ShadButton.destructive(
            child: const Text('删除'),
            onPressed: () async {
              final ok =
                  await ref.read(diaryListProvider.notifier).deleteDiary(id);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (ok && context.mounted) context.go(AppRoutes.home);
            },
          ),
        ],
      ),
    );
  }
}

class _DiaryContent extends StatelessWidget {
  final dynamic diary;

  const _DiaryContent({required this.diary});

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
    final mood = diary.mood as Mood;
    final weather = diary.weather as Weather?;
    final tags = diary.tags as List<String>;
    final date = diary.createdAt as DateTime;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    // Build a ThemeData wrapper for MarkdownStyleSheet
    final themeData = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(diary.entryType.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Text(
                diary.entryType.label,
                style: textTheme.large.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(mood.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 4),
              if (weather != null) ...[
                const SizedBox(width: 12),
                Text(weather.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  weather.label,
                  style: textTheme.small.copyWith(color: scheme.mutedForeground),
                ),
              ],
              const Spacer(),
              Text(
                dateStr,
                style: textTheme.small.copyWith(color: scheme.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            diary.title.isEmpty ? '（无标题）' : diary.title,
            style: textTheme.h3,
          ),
          const SizedBox(height: 16),
          MarkdownBody(
            data: diary.content.isEmpty ? '（暂无内容）' : diary.content,
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
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((tag) {
                return ShadBadge.secondary(
                  child: Text('#$tag', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
