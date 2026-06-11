import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/di/providers.dart';
import '../../data/models/diary.dart';
import '../../data/models/enums.dart';

/// 日记列表状态
class DiaryListState {
  final List<Diary> diaries;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final Mood? filterMood;

  const DiaryListState({
    this.diaries = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.filterMood,
  });

  DiaryListState copyWith({
    List<Diary>? diaries,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    Mood? filterMood,
  }) {
    return DiaryListState(
      diaries: diaries ?? this.diaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      filterMood: filterMood ?? this.filterMood,
    );
  }
}

/// 日记列表控制器
class DiaryListNotifier extends Notifier<DiaryListState> {
  PocketBase get _pb => ref.read(pbClientProvider);

  @override
  DiaryListState build() => const DiaryListState();

  /// 加载日记列表
  Future<void> loadDiaries({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = refresh ? 1 : state.page;
      final userId = _pb.authStore.record?.id;
      if (userId == null) return;

      final filter = [
        'user = "$userId"',
        'isDeleted != true',
        if (state.filterMood != null) 'mood = "${state.filterMood!.value}"',
      ].join(' && ');

      final result = await _pb.collection('diaries').getList(
            page: page,
            perPage: 20,
            filter: filter,
            sort: '-created',
          );

      final newDiaries = result.items
          .map((r) => Diary.fromRecord(r.toJson()))
          .toList();

      state = state.copyWith(
        diaries: refresh ? newDiaries : [...state.diaries, ...newDiaries],
        isLoading: false,
        page: page + 1,
        hasMore: result.items.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载失败：${e.toString()}',
      );
    }
  }

  /// 设置心情筛选
  void setMoodFilter(Mood? mood) {
    state = state.copyWith(filterMood: mood, error: null);
    loadDiaries(refresh: true);
  }

  /// 删除日记（软删除）
  Future<bool> deleteDiary(String diaryId) async {
    try {
      await _pb.collection('diaries').update(diaryId, body: {'isDeleted': true});
      state = state.copyWith(
        diaries: state.diaries.where((d) => d.id != diaryId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 创建日记
  Future<Diary?> createDiary({
    required String title,
    required String content,
    required Mood mood,
    Weather? weather,
    List<String> tags = const [],
  }) async {
    final userId = _pb.authStore.record?.id;
    if (userId == null) return null;

    try {
      final record = await _pb.collection('diaries').create(body: {
        'title': title,
        'content': content,
        'mood': mood.value,
        if (weather != null) 'weather': weather.value,
        'tags': tags,
        'user': userId,
      });

      final diary = Diary.fromRecord(record.toJson());
      state = state.copyWith(
        diaries: [diary, ...state.diaries],
      );
      return diary;
    } catch (_) {
      return null;
    }
  }

  /// 更新日记
  Future<bool> updateDiary(String diaryId, Diary diary) async {
    try {
      await _pb.collection('diaries').update(diaryId, body: diary.toApiJson());
      state = state.copyWith(
        diaries: state.diaries.map((d) => d.id == diaryId ? diary : d).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// DiaryListNotifier Provider
final diaryListProvider =
    NotifierProvider<DiaryListNotifier, DiaryListState>(DiaryListNotifier.new);

/// 单篇日记 Provider
///
/// 优先从已加载的列表中查找（零网络开销），
/// 列表中没有时才请求 PocketBase API。
final diaryProvider = FutureProvider.family<Diary?, String>((ref, diaryId) async {
  // 优先从已加载的列表中查找
  final listState = ref.read(diaryListProvider);
  for (final d in listState.diaries) {
    if (d.id == diaryId) return d;
  }

  // 列表中没有，从 API 获取
  final pb = ref.read(pbClientProvider);
  try {
    final record = await pb.collection('diaries').getOne(diaryId);
    return Diary.fromRecord(record.toJson());
  } catch (_) {
    return null;
  }
});
