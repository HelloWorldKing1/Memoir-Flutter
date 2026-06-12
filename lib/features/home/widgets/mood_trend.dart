import 'package:flutter/material.dart';

import '../../../data/models/enums.dart';

/// 心情趋势组件。
///
/// 展示近 7 天心情分布条形图 + 智能建议。
class MoodTrend extends StatelessWidget {
  /// 近 7 天心情分布计数
  final Map<Mood, int> moodDistribution;

  const MoodTrend({
    super.key,
    required this.moodDistribution,
  });

  /// 心情颜色映射
  static const _moodColors = {
    Mood.happy: Color(0xFF4CAF50),
    Mood.neutral: Color(0xFF9E9E9E),
    Mood.sad: Color(0xFF2196F3),
    Mood.angry: Color(0xFFF44336),
    Mood.love: Color(0xFFE91E63),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = moodDistribution.values.fold<int>(0, (a, b) => a + b);
    final topMood = _topMood();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(Icons.insights, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  '心情趋势（近7天）',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 心情分布条形图
            if (total == 0)
              _buildEmpty(theme)
            else
              _buildDistribution(theme, scheme, total),
            // 建议
            if (total > 0) ...[
              const Divider(height: 24),
              _buildSuggestion(theme, topMood, total),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          '暂无心情数据\n写几篇日记后这里会展示心情分布',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildDistribution(ThemeData theme, ColorScheme scheme, int total) {
    return Column(
      children: Mood.values.map((mood) {
        final count = moodDistribution[mood] ?? 0;
        final ratio = total > 0 ? count / total : 0.0;
        final color = _moodColors[mood]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              SizedBox(
                width: 40,
                child: Text(
                  mood.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 14,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      ratio > 0 ? color : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${(ratio * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestion(ThemeData theme, Mood? topMood, int total) {
    final scheme = theme.colorScheme;
    final (emoji, text) = _suggestionFor(topMood, total);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('💬', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  (String emoji, String text) _suggestionFor(Mood? topMood, int total) {
    if (topMood == null) {
      return ('💬', '本周还没有记录心情，开始写第一篇吧 ✨');
    }

    return switch (topMood) {
      Mood.happy => (
          '💬',
          '这周以 😊 开心为主，状态很棒！\n'
              '试着回顾那些让你快乐的瞬间，把它们记录下来，未来翻看时会是珍贵的能量来源。'
        ),
      Mood.neutral => (
          '💬',
          '心情平稳的一周，一切都在掌控之中。\n'
              '不妨尝试写一篇「灵感」或「感悟」，给日常生活增添一点新鲜感。'
        ),
      Mood.sad => (
          '💬',
          '这周有些低落，但写作本身就是一种疗愈。\n'
              '不必强求积极，真实地记录你的感受——文字会帮你慢慢消化这些情绪 🌱'
        ),
      Mood.angry => (
          '💬',
          '情绪起伏在所难免，把烦恼写下来反而会轻松很多。\n'
              '试试用文字梳理一下让你生气的事情，写完之后你可能会发现视角不同了。'
        ),
      Mood.love => (
          '💬',
          '充满爱和温暖的一周！\n'
              '把这些动人的瞬间记录下来吧，它们是生命中最值得珍藏的部分 💕'
        ),
    };
  }

  Mood? _topMood() {
    if (moodDistribution.isEmpty) return null;
    return moodDistribution.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}
