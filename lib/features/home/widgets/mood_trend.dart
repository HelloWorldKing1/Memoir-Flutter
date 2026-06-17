import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../data/models/enums.dart';

/// 心情趋势组件。
class MoodTrend extends StatelessWidget {
  final Map<Mood, int> moodDistribution;

  const MoodTrend({super.key, required this.moodDistribution});

  static const _moodColors = {
    Mood.happy: Color(0xFF4CAF50),
    Mood.neutral: Color(0xFF9E9E9E),
    Mood.sad: Color(0xFF2196F3),
    Mood.angry: Color(0xFFF44336),
    Mood.love: Color(0xFFE91E63),
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = ShadTheme.of(context).textTheme;
    final scheme = ShadTheme.of(context).colorScheme;
    final total = moodDistribution.values.fold<int>(0, (a, b) => a + b);
    final topMood = _topMood();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.trendingUp, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  '心情趋势（近7天）',
                  style: textTheme.p.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (total == 0)
              _buildEmpty(textTheme, scheme)
            else
              _buildDistribution(textTheme, scheme, total),
            if (total > 0) ...[
              const SizedBox(height: 8),
              const ShadSeparator.horizontal(),
              const SizedBox(height: 8),
              _buildSuggestion(context, textTheme, topMood, total),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEmpty(ShadTextTheme textTheme, ShadColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          '暂无心情数据\n写几篇日记后这里会展示心情分布',
          textAlign: TextAlign.center,
          style: textTheme.small.copyWith(color: scheme.mutedForeground),
        ),
      ),
    );
  }

  Widget _buildDistribution(
      ShadTextTheme textTheme, ShadColorScheme scheme, int total) {
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
                  style: textTheme.small.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 28,
                child: Text(
                  '$count',
                  style: textTheme.small.copyWith(color: scheme.mutedForeground),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProgressBar(ratio, color),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${(ratio * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestion(BuildContext context,
      ShadTextTheme textTheme, Mood? topMood, int total) {
    final scheme = ShadTheme.of(context).colorScheme;
    final (_, text) = _suggestionFor(topMood, total);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💬', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.small.copyWith(
              color: scheme.mutedForeground,
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

  Widget _buildProgressBar(double value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ShadProgress(value: value),
    );
  }

  Mood? _topMood() {
    if (moodDistribution.isEmpty) return null;
    return moodDistribution.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}
