import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/inspiration.dart';
import '../inspiration_notifier.dart';

/// 今日灵感组件。
///
/// 从数据库拉取灵感内容，展示写作灵感 + 底部倒计时进度条。
/// 进度条独立管理自己的 Timer，避免每次 tick 重建整个卡片。
/// 内容每 10 秒自动切换，带淡入淡出动画。
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
      error: (e, st) => _buildSkeleton(context), // 错误展示骨架（有fallback通常不会到这）
      data: (list) => _buildCard(context, list),
    );
  }

  Widget _buildCard(BuildContext context, List<Inspiration> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    // 首次数据到达：随机选取起始位置
    if (!_initialized) {
      _initialized = true;
      _currentIndex = Random().nextInt(list.length);
    }

    // 安全索引
    final safeIndex = _currentIndex < list.length ? _currentIndex : 0;
    final inspiration = list[safeIndex];

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                const Spacer(),
                // 分类标签
                if (inspiration.category != null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      inspiration.category!.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontSize: 9,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: _onManualRefresh,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child:
                        Icon(Icons.refresh, size: 18, color: scheme.outline),
                  ),
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '—— ${inspiration.author}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 进度条（独立 StatefulWidget，内部 Timer 自行管理）
            RepaintBoundary(
              child: _CountdownProgress(
                key: ValueKey(_refreshKey),
                onTimeUp: _onTimeUp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 加载中骨架屏
  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
                  style: theme.textTheme.titleSmall?.copyWith(
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
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 200,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 倒计时进度条。
///
/// 独立管理 [Timer] 和自身状态，每次 tick 只重建这个小组件，
/// 不影响父级卡片。
class _CountdownProgress extends StatefulWidget {
  final VoidCallback onTimeUp;

  const _CountdownProgress({super.key, required this.onTimeUp});

  @override
  State<_CountdownProgress> createState() => _CountdownProgressState();
}

class _CountdownProgressState extends State<_CountdownProgress> {
  Timer? _timer;
  double _elapsed = 0;
  int _remaining = 10;

  static const _totalSeconds = 10;
  static const _tickMs = 250;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _elapsed = 0;
    _remaining = _totalSeconds;
    if (!mounted) return;

    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _elapsed += _tickMs / 1000.0;
      if (_elapsed >= _totalSeconds) {
        _elapsed = _totalSeconds.toDouble();
        _remaining = 0;
        timer.cancel();
        setState(() {});
        widget.onTimeUp();
        return;
      }
      final newRemaining = (_totalSeconds - _elapsed).ceil();
      if (newRemaining != _remaining) {
        _remaining = newRemaining;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = (_elapsed / _totalSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              scheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_remaining}s 后刷新',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.outline.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
