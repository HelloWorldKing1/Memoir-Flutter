import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/routes/app_router.dart';
import '../../../data/models/diary.dart';

/// 最近记录组件 — 横向卡片，用户手动滚动浏览。
class RecentEntries extends ConsumerWidget {
  final List<Diary> diaries;

  const RecentEntries({super.key, required this.diaries});

  static const _cardWidth = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    if (diaries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ShadCard(
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
                        Icon(LucideIcons.bookOpen,
                            size: 36, color: scheme.mutedForeground),
                        const SizedBox(height: 8),
                        Text(
                          '📝 还没有记录\n点击「快速记录」开始写点什么吧！',
                          textAlign: TextAlign.center,
                          style: textTheme.small
                              .copyWith(color: scheme.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ShadCard(
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    return Row(
      children: [
        Icon(LucideIcons.history, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          '最近记录',
          style: textTheme.p.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        ShadButton.ghost(
          child: const Text('查看全部'),
          trailing: const Icon(LucideIcons.arrowRight, size: 16),
          onPressed: () => context.go(AppRoutes.diaryList),
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
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
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
          color: scheme.border.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.border.withValues(alpha: 0.4),
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
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(diary.entryType.emoji,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const Spacer(),
                Text(diary.mood.emoji, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              diary.title.isEmpty ? '（无标题）' : diary.title,
              style: textTheme.small.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                diary.content.isEmpty ? '（暂无内容）' : diary.content,
                style: textTheme.small.copyWith(
                  color: scheme.mutedForeground,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  dateStr,
                  style: textTheme.small
                      .copyWith(color: scheme.mutedForeground),
                ),
                const Spacer(),
                if (diary.tags.isNotEmpty)
                  ShadBadge.secondary(
                    child: Text(
                      '#${diary.tags.first}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
