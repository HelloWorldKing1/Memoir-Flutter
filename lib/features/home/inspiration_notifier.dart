import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/models/inspiration.dart';

/// 本地 fallback 灵感 —— 网络失败或数据库无数据时使用
final _fallbackInspirations = [
  Inspiration(
    emoji: '✍️',
    quote: '写作是灵魂的呼吸，每一个字都是你与自己的对话。',
    author: '未知',
    category: InspirationCategory.writing,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '💡',
    quote: '灵感不会主动上门，它在你开始动笔的那一刻才会降临。',
    author: '杰克·伦敦',
    category: InspirationCategory.creativity,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '🌱',
    quote: '每天记录一件小事，一年后你会有 365 个故事。',
    author: '格蕾塔·鲁宾',
    category: InspirationCategory.persistence,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '🎯',
    quote: '不需要完美的第一稿，只需要被写下来的第一稿。',
    author: '乔迪·皮考特',
    category: InspirationCategory.writing,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '🔥',
    quote: '最好的时间就是现在。拿起笔，让思绪流淌。',
    author: '村上春树',
    category: InspirationCategory.writing,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '🌟',
    quote: '生活不是我们活过的日子，而是我们记住的日子。',
    author: '马尔克斯',
    category: InspirationCategory.wisdom,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '📖',
    quote: '每一个伟大的故事，都始于一个简单的记录。',
    author: '史蒂芬·金',
    category: InspirationCategory.literature,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '🧠',
    quote: '写作是思考的终极形式——它把模糊的感受变成清晰的洞见。',
    author: '保罗·格雷厄姆',
    category: InspirationCategory.wisdom,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '🕯️',
    quote: '在你内心最深处，有一个声音值得被听见。写下来吧。',
    author: '弗吉尼亚·伍尔夫',
    category: InspirationCategory.mindfulness,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
  Inspiration(
    emoji: '🌈',
    quote: '文字是时间的容器，把一瞬的感动封存为永恒。',
    author: '泰戈尔',
    category: InspirationCategory.literature,
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
];

final _epoch = DateTime(2024, 1, 1);

/// 灵感列表 FutureProvider
///
/// 从 PocketBase `inspirations` 集合拉取所有启用的灵感。
/// 网络失败时自动降级到本地 fallback（10 条经典文案）。
final inspirationListProvider = FutureProvider<List<Inspiration>>((ref) async {
  final pb = ref.watch(pbClientProvider);

  try {
    final result = await pb.collection('inspirations').getList(
          page: 1,
          perPage: 200,
          filter: 'isActive = true',
          sort: '-priority,-created',
        );

    final inspirations =
        result.items.map((r) => Inspiration.fromRecord(r.toJson())).toList();

    if (inspirations.isNotEmpty) return inspirations;
  } catch (_) {
    // 网络错误，降级到 fallback
  }

  // 数据库无数据或网络失败 → 使用本地 fallback
  return _fallbackInspirations;
});
