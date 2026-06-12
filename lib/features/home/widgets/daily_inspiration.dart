import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// 今日灵感组件。
///
/// 展示写作灵感 + 底部倒计时进度条。
/// 进度条独立管理自己的 Timer，避免每次 tick 重建整个卡片。
class DailyInspiration extends StatefulWidget {
  const DailyInspiration({super.key});

  @override
  State<DailyInspiration> createState() => _DailyInspirationState();
}

class _DailyInspirationState extends State<DailyInspiration> {
  int _currentIndex = 0;
  bool _showContent = true;
  int _refreshKey = 0; // 变化时重建 _CountdownProgress

  static const _inspirations = [
    (emoji: '✍️', quote: '写作是灵魂的呼吸，每一个字都是你与自己的对话。', author: '未知'),
    (emoji: '💡', quote: '灵感不会主动上门，它在你开始动笔的那一刻才会降临。', author: '杰克·伦敦'),
    (emoji: '🌱', quote: '每天记录一件小事，一年后你会有 365 个故事。', author: '格蕾塔·鲁宾'),
    (emoji: '🎯', quote: '不需要完美的第一稿，只需要被写下来的第一稿。', author: '乔迪·皮考特'),
    (emoji: '🔥', quote: '最好的时间就是现在。拿起笔，让思绪流淌。', author: '村上春树'),
    (emoji: '🌟', quote: '生活不是我们活过的日子，而是我们记住的日子。', author: '马尔克斯'),
    (emoji: '📖', quote: '每一个伟大的故事，都始于一个简单的记录。', author: '史蒂芬·金'),
    (emoji: '🧠', quote: '写作是思考的终极形式——它把模糊的感受变成清晰的洞见。', author: '保罗·格雷厄姆'),
    (emoji: '🕯️', quote: '在你内心最深处，有一个声音值得被听见。写下来吧。', author: '弗吉尼亚·伍尔夫'),
    (emoji: '🌈', quote: '文字是时间的容器，把一瞬的感动封存为永恒。', author: '泰戈尔'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = Random().nextInt(_inspirations.length);
  }

  void _onTimeUp() {
    _switchContent();
  }

  Future<void> _switchContent() async {
    // 淡出
    if (mounted) setState(() => _showContent = false);
    await Future.delayed(const Duration(milliseconds: 200));

    // 切换
    if (mounted) {
      setState(() {
        final rng = Random();
        int next;
        do {
          next = rng.nextInt(_inspirations.length);
        } while (next == _currentIndex && _inspirations.length > 1);
        _currentIndex = next;
        _showContent = true;
        _refreshKey++; // 通知进度条重新开始
      });
    }
  }

  void _onManualRefresh() {
    _switchContent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inspiration = _inspirations[_currentIndex];

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
                InkWell(
                  onTap: _onManualRefresh,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.refresh, size: 18, color: scheme.outline),
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
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.outline),
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
  static const _tickMs = 250; // 每秒 4 帧 — 进度条平滑，对性能影响极小

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
