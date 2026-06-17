import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/di/providers.dart';
import '../../data/models/inspiration.dart';

/// 本地 fallback 灵感（仅当网络彻底不可用时使用）
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
/// - 数据库有数据 → 直接返回
/// - 数据库有集合但无数据 → 返回空列表（提示用户运行种子脚本）
/// - 集合不存在 (404) → 抛出明确错误，引导创建集合
/// - 网络不可用 → 降级到本地 fallback
final inspirationListProvider = FutureProvider<List<Inspiration>>((ref) async {
  final pb = ref.watch(pbClientProvider);

  try {
    // 先尝试不带 filter 的请求，确认集合和字段可用
    final result = await pb.collection('inspirations').getList(
          page: 1,
          perPage: 200,
        );

    final inspirations =
        result.items.map((r) => Inspiration.fromRecord(r.toJson())).toList();

    if (inspirations.isNotEmpty) return inspirations;

    // 集合存在但无数据（尚未播种）
    debugPrint('[inspiration] inspirations 集合为空，请运行 seed_inspirations 脚本导入数据');
    return [];
  } on ClientException catch (e) {
    final statusCode = e.statusCode;

    // 打印完整响应体，方便排查
    debugPrint('[inspiration] ClientException: status=$statusCode, '
        'response=${e.response}, originalError=${e.originalError}');

    if (statusCode == 404) {
      throw Exception(
        'PocketBase 中缺少 inspirations 集合。'
        '请在 Admin UI 创建集合（字段参考 data/models/inspiration.dart），'
        '然后运行 scripts/seed_inspirations.ps1 导入种子数据。',
      );
    }

    if (statusCode == 400) {
      throw Exception(
        '请求格式错误 (400): ${e.response['message'] ?? "未知"}。'
        '请检查 inspirations 集合的字段名和 API 规则是否正确。',
      );
    }

    final detail = e.response['message'] ?? e.originalError ?? '未知错误';
    throw Exception('服务器错误 ($statusCode): $detail');
  } catch (e) {
    // 判断是否为网络层面的不可达（如 SocketException、超时等）
    // PocketBase SDK 在无网时可能抛 ClientException 或其他异常
    final msg = e.toString().toLowerCase();
    final isNetworkError =
        msg.contains('socket') ||
        msg.contains('host') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('network') ||
        msg.contains('internet');

    if (isNetworkError) {
      debugPrint('[inspiration] 网络不可达，降级到本地 fallback: $e');
      return _fallbackInspirations;
    }

    // 其他错误（包括我们上面抛出的 Exception）→ 继续抛出
    rethrow;
  }
});
