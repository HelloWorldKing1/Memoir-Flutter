import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../home_notifier.dart';

/// AI 近期总结卡片。
class AiSummaryCard extends ConsumerWidget {
  const AiSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final scheme = ShadTheme.of(context).colorScheme;
    final isDark = ShadTheme.of(context).brightness == Brightness.dark;

    final aiSummary = homeAsync.value?.aiSummary ?? const AiSummaryLoading();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFFF3E5F5), const Color(0xFFEDE7F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: scheme.primary, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'AI 周报总结',
                    style: ShadTheme.of(context).textTheme.p.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (aiSummary is AiSummaryReady)
                    ShadIconButton.ghost(
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      onPressed: () =>
                          ref.read(homeProvider.notifier).regenerateAiSummary(),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildContent(context, aiSummary, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AiSummaryState state, WidgetRef ref) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    return switch (state) {
      AiSummaryLoading() => _ShimmerPlaceholder(),
      AiSummaryInsufficient(currentCount: final cur, requiredCount: final req) =>
        Column(
          children: [
            const SizedBox(height: 8),
            Icon(LucideIcons.sparkles, size: 32, color: scheme.mutedForeground),
            const SizedBox(height: 12),
            Text(
              '📝  记录太少啦',
              style: textTheme.p.copyWith(color: scheme.mutedForeground),
            ),
            const SizedBox(height: 6),
            Text(
              '再写几篇日记，AI 就能为你生成专属总结\n至少需要 $req 篇记录（当前 $cur 篇）',
              textAlign: TextAlign.center,
              style: textTheme.small.copyWith(color: scheme.mutedForeground),
            ),
          ],
        ),
      AiSummaryError(message: final msg) => Column(
          children: [
            Icon(LucideIcons.alertTriangle, size: 32, color: scheme.destructive),
            const SizedBox(height: 12),
            Text(
              '😵  $msg',
              style: textTheme.p.copyWith(color: scheme.destructive),
            ),
            const SizedBox(height: 8),
            ShadButton.outline(
              leading: const Icon(LucideIcons.refreshCw, size: 16),
              child: const Text('重试'),
              onPressed: () =>
                  ref.read(homeProvider.notifier).regenerateAiSummary(),
            ),
          ],
        ),
      AiSummaryReady(title: final t, body: final b) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: textTheme.p.copyWith(fontWeight: FontWeight.w600, height: 1.6)),
            const SizedBox(height: 8),
            Text(
              b,
              style: textTheme.small.copyWith(
                height: 1.6,
                color: scheme.foreground.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
            const ShadSeparator.horizontal(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: scheme.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  'AI 生成 · 仅供参考',
                  style: textTheme.small.copyWith(
                    color: scheme.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Text(
                  '基于近 7 天记录',
                  style: textTheme.small.copyWith(color: scheme.mutedForeground),
                ),
              ],
            ),
          ],
        ),
    };
  }
}

/// Shimmer 骨架占位
class _ShimmerPlaceholder extends StatefulWidget {
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final opacity = 0.3 + (_ctrl.value * 0.4);
        final color = scheme.foreground.withValues(alpha: opacity);

        return Column(
          children: [
            _bar(color, 0.9),
            const SizedBox(height: 10),
            _bar(color, 0.7),
            const SizedBox(height: 10),
            _bar(color, 0.5),
            const SizedBox(height: 10),
            _bar(color, 0.35),
          ],
        );
      },
    );
  }

  Widget _bar(Color color, double widthRatio) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthRatio,
        child: Container(
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }
}
