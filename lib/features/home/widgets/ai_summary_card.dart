import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_notifier.dart';

/// AI 近期总结卡片。
///
/// 展示自然语言风格的一周写作总结。
/// 支持 4 种状态：加载中、数据不足、错误、就绪。
/// 当前为 Mock 数据展示，后续接入真实 AI。
class AiSummaryCard extends ConsumerWidget {
  const AiSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
            left: BorderSide(
              color: scheme.primary,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Text('✨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'AI 周报总结',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (aiSummary is AiSummaryReady)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () =>
                          ref.read(homeProvider.notifier).regenerateAiSummary(),
                      tooltip: '刷新总结',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 内容区
              _buildContent(context, aiSummary, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AiSummaryState state, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return switch (state) {
      AiSummaryLoading() => _ShimmerPlaceholder(theme: theme),
      AiSummaryInsufficient(currentCount: final cur, requiredCount: final req) =>
        Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.auto_awesome, size: 32, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              '📝  记录太少啦',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '再写几篇日记，AI 就能为你生成专属总结\n至少需要 $req 篇记录（当前 $cur 篇）',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.outline,
              ),
            ),
          ],
        ),
      AiSummaryError(message: final msg) => Column(
          children: [
            Icon(Icons.error_outline, size: 32, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              '😵  $msg',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
              onPressed: () =>
                  ref.read(homeProvider.notifier).regenerateAiSummary(),
            ),
          ],
        ),
      AiSummaryReady(title: final t, body: final b) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              b,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: scheme.outline),
                const SizedBox(width: 4),
                Text(
                  'AI 生成 · 仅供参考',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Text(
                  '基于近 7 天记录',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
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
  final ThemeData theme;
  const _ShimmerPlaceholder({required this.theme});

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
    final scheme = widget.theme.colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final opacity = 0.3 + (_ctrl.value * 0.4);
        final color = scheme.onSurface.withValues(alpha: opacity);

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
