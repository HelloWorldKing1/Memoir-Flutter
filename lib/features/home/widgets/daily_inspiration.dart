import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../data/models/inspiration.dart';
import '../inspiration_notifier.dart';

/// 今日灵感组件。
class DailyInspiration extends ConsumerStatefulWidget {
  const DailyInspiration({super.key});

  @override
  ConsumerState<DailyInspiration> createState() => _DailyInspirationState();
}

class _DailyInspirationState extends ConsumerState<DailyInspiration> {
  int _currentIndex = 0;
  bool _showContent = true;
  int _refreshKey = 0;
  bool _initialized = false;

  void _onTimeUp() {
    _switchContent();
  }

  Future<void> _switchContent() async {
    if (mounted) setState(() => _showContent = false);
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    final list = ref.read(inspirationListProvider).value;
    if (list == null || list.isEmpty) return;

    setState(() {
      final rng = Random();
      int next;
      do {
        next = rng.nextInt(list.length);
      } while (next == _currentIndex && list.length > 1);
      _currentIndex = next;
      _showContent = true;
      _refreshKey++;
    });
  }

  void _onManualRefresh() {
    _switchContent();
  }

  @override
  Widget build(BuildContext context) {
    final inspirationAsync = ref.watch(inspirationListProvider);

    return inspirationAsync.when(
      loading: () => _buildSkeleton(context),
      error: (e, st) => _buildSkeleton(context),
      data: (list) => _buildCard(context, list),
    );
  }

  Widget _buildCard(BuildContext context, List<Inspiration> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    if (!_initialized) {
      _initialized = true;
      _currentIndex = Random().nextInt(list.length);
    }

    final safeIndex = _currentIndex < list.length ? _currentIndex : 0;
    final inspiration = list[safeIndex];

    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            // 标题行
            Row(
              children: [
                Text(inspiration.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '今日灵感',
                  style: textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const Spacer(),
                if (inspiration.category != null)
                  ShadBadge.secondary(
                    child: Text(
                      inspiration.category!.label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                const SizedBox(width: 4),
                ShadIconButton.ghost(
                  icon: Icon(LucideIcons.refreshCw, size: 16, color: scheme.mutedForeground),
                  onPressed: _onManualRefresh,
                  iconSize: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 内容区（带淡入淡出）
            AnimatedOpacity(
              opacity: _showContent ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Column(
                children: [
                  Text(
                    '"${inspiration.quote}"',
                    textAlign: TextAlign.center,
                    style: textTheme.p.copyWith(
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                      color: scheme.foreground.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '—— ${inspiration.author}',
                    style: textTheme.small.copyWith(color: scheme.mutedForeground),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              child: _CountdownProgress(
                key: ValueKey(_refreshKey),
                onTimeUp: _onTimeUp,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ShadCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 24, height: 24),
                const SizedBox(width: 8),
                Text(
                  '今日灵感',
                  style: textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 200,
              decoration: BoxDecoration(
                color: scheme.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: scheme.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }
}

/// 倒计时进度条（TweenAnimationBuilder 驱动，帧级丝滑）。
class _CountdownProgress extends StatelessWidget {
  final VoidCallback onTimeUp;

  const _CountdownProgress({super.key, required this.onTimeUp});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 120),
      curve: Curves.linear,
      onEnd: onTimeUp,
      builder: (context, value, _) {
        return SizedBox(
          height: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: ShadProgress(value: value),
          ),
        );
      },
    );
  }
}
