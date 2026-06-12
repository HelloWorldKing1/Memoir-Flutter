import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../core/di/providers.dart';
import '../../data/models/diary.dart';
import '../../data/models/enums.dart';
import '../home/home_notifier.dart';

/// 日记列表状态
class DiaryListState {
  final List<Diary> diaries;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final Mood? filterMood;
  final String searchQuery;

  const DiaryListState({
    this.diaries = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.filterMood,
    this.searchQuery = '',
  });

  bool get isSearching => searchQuery.isNotEmpty;

  DiaryListState copyWith({
    List<Diary>? diaries,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    Mood? filterMood,
    String? searchQuery,
  }) {
    return DiaryListState(
      diaries: diaries ?? this.diaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      filterMood: filterMood ?? this.filterMood,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// 日记列表控制器
class DiaryListNotifier extends Notifier<DiaryListState> {
  PocketBase get _pb => ref.read(pbClientProvider);
  int _requestSeq = 0;

  @override
  DiaryListState build() => const DiaryListState();

  /// 加载日记列表（初始加载 / 滚动分页 / 下拉刷新）
  Future<void> loadDiaries({bool refresh = false}) async {
    if (!refresh && state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final seq = ++_requestSeq;
    // 捕获当前条件
    final mood = state.filterMood;
    final search = state.searchQuery;
    final page = refresh ? 1 : state.page;
    final userId = _pb.authStore.record?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final filters = <String>[
        'user = "$userId"',
        'isDeleted != true',
        if (mood != null) 'mood = "${mood.value}"',
      ];

      if (search.isNotEmpty) {
        final q = search.replaceAll('"', '\\"');
        filters.add('(title ~ "$q" || content ~ "$q" || tags ~ "$q")');
      }

      final filter = filters.join(' && ');
      // ignore: avoid_print
      print('[diary_list] filter=$filter');

      final result = await _pb.collection('diaries').getList(
            page: page,
            perPage: 20,
            filter: filter,
            sort: '-created',
          );

      if (seq != _requestSeq) return;

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
      if (seq != _requestSeq) return;
      state = state.copyWith(
        isLoading: false,
        error: '加载失败：${e.toString()}',
      );
    }
  }

  /// 设置心情筛选
  void setMoodFilter(Mood? mood) {
    // ignore: avoid_print
    print('[diary_list] setMoodFilter $mood (was ${state.filterMood})');
    if (state.filterMood == mood && state.diaries.isNotEmpty) return;
    state = state.copyWith(
      filterMood: mood,
      diaries: [],
      page: 1,
      hasMore: true,
      error: null,
    );
    _load(mood: mood, search: state.searchQuery);
  }

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    final q = query.trim();
    if (state.searchQuery == q && state.diaries.isNotEmpty) return;
    state = state.copyWith(
      searchQuery: q,
      diaries: [],
      page: 1,
      hasMore: true,
      error: null,
    );
    _load(mood: state.filterMood, search: q);
  }

  /// 执行加载（参数明确传入，不读 state.filterMood/searchQuery）
  Future<void> _load({required Mood? mood, required String search}) async {
    final seq = ++_requestSeq;
    final userId = _pb.authStore.record?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final filters = <String>[
        'user = "$userId"',
        'isDeleted != true',
        if (mood != null) 'mood = "${mood.value}"',
      ];

      if (search.isNotEmpty) {
        final q = search.replaceAll('"', '\\"');
        filters.add('(title ~ "$q" || content ~ "$q" || tags ~ "$q")');
      }

      final filter = filters.join(' && ');
      // ignore: avoid_print
      print('[diary_list] filter=$filter');

      final result = await _pb.collection('diaries').getList(
            page: 1,
            perPage: 20,
            filter: filter,
            sort: '-created',
          );

      if (seq != _requestSeq) return;

      final newDiaries = result.items
          .map((r) => Diary.fromRecord(r.toJson()))
          .toList();

      state = state.copyWith(
        diaries: newDiaries,
        isLoading: false,
        page: 2,
        hasMore: result.items.length >= 20,
      );
    } catch (e) {
      if (seq != _requestSeq) return;
      state = state.copyWith(
        isLoading: false,
        error: '加载失败：${e.toString()}',
      );
    }
  }

  /// 删除日记（软删除）
  Future<bool> deleteDiary(String diaryId) async {
    try {
      await _pb.collection('diaries').update(diaryId, body: {'isDeleted': true});
      state = state.copyWith(
        diaries: state.diaries.where((d) => d.id != diaryId).toList(),
      );
      ref.invalidate(homeProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 创建记录
  Future<Diary?> createDiary({
    required String title,
    required String content,
    required EntryType entryType,
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
        'entryType': entryType.value,
        'mood': mood.value,
        if (weather != null) 'weather': weather.value,
        'tags': tags,
        'user': userId,
      });

      final diary = Diary.fromRecord(record.toJson());
      state = state.copyWith(
        diaries: [diary, ...state.diaries],
      );
      ref.invalidate(homeProvider);
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
      ref.invalidate(homeProvider);
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
  } catch (e) {
    // ignore: avoid_print
    print('[diaryProvider] 获取日记 $diaryId 失败: $e');
    return null;
  }
});
