import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../data/models/diary.dart';

/// 最近记录组件 — 横向卡片，用户手动滚动浏览。
class RecentEntries extends ConsumerWidget {
  final List<Diary> diaries;

  const RecentEntries({super.key, required this.diaries});

  static const _cardWidth = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    if (diaries.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.auto_stories, size: 36, color: scheme.outline),
                      const SizedBox(height: 8),
                      Text(
                        '📝 还没有记录\n点击「快速记录」开始写点什么吧！',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            SizedBox(
              height: isDesktop ? 160 : 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: diaries.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < diaries.length - 1 ? 12 : 0,
                    ),
                    child: _DiaryCard(
                      diary: diaries[index],
                      width: _cardWidth,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          '最近记录',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('查看全部'),
          onPressed: () => context.go(AppRoutes.diaryList),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }
}

/// 横向日记卡片
class _DiaryCard extends StatelessWidget {
  final Diary diary;
  final double width;

  const _DiaryCard({required this.diary, required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = diary.createdAt;
    final dateStr =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        final id = diary.id;
        if (id == null || id.isEmpty) return;
        context.push(AppRoutes.diaryDetail.replaceFirst(':id', id));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(diary.entryType.emoji, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const Spacer(),
                Text(diary.mood.emoji, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              diary.title.isEmpty ? '（无标题）' : diary.title,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                diary.content.isEmpty ? '（暂无内容）' : diary.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(dateStr, style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
                const Spacer(),
                if (diary.tags.isNotEmpty)
                  Text(
                    '#${diary.tags.first}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
