import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/models/enums.dart';

/// 统计页面
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  Map<Mood, int> _moodCounts = {};
  int _totalDiaries = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final pb = ref.read(pbClientProvider);
      final userId = pb.authStore.record?.id;
      if (userId == null) return;

      final result = await pb.collection('diaries').getList(
            page: 1,
            perPage: 1,
            filter: 'user = "$userId" && isDeleted != true',
            skipTotal: false,
          );

      setState(() {
        _totalDiaries = result.totalItems;
      });

      // 按心情统计
      final counts = <Mood, int>{};
      for (final mood in Mood.values) {
        final moodResult = await pb.collection('diaries').getList(
              page: 1,
              perPage: 1,
              filter: 'user = "$userId" && mood = "${mood.value}" && isDeleted != true',
              skipTotal: false,
            );
        counts[mood] = moodResult.totalItems;
      }

      if (mounted) {
        setState(() {
          _moodCounts = counts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 总日记数
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.auto_stories,
                              size: 40, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_totalDiaries',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '日记总数',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 心情分布
                  Text('心情分布', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...Mood.values.map((mood) {
                    final count = _moodCounts[mood] ?? 0;
                    final maxCount =
                        _moodCounts.values.fold<int>(0, (a, b) => a > b ? a : b);
                    final ratio = maxCount > 0 ? count / maxCount : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(mood.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: Text(
                              mood.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 20,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
