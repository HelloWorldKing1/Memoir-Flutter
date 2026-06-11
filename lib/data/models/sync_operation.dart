/// 同步操作类型
enum SyncOperationType {
  create,
  update,
  delete,
}

/// 同步操作状态
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

/// 离线同步队列中的操作项
///
/// 存储在 Hive 中，在网络可用时按 FIFO 顺序同步到 PocketBase。
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String diaryId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final SyncStatus status;
  final int retryCount;
  final String? lastError;

  const SyncOperation({
    required this.id,
    required this.type,
    required this.diaryId,
    this.data,
    required this.createdAt,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.lastError,
  });

  /// 记录一次重试失败
  SyncOperation withRetry(String error) {
    return SyncOperation(
      id: id,
      type: type,
      diaryId: diaryId,
      data: data,
      createdAt: createdAt,
      status: SyncStatus.failed,
      retryCount: retryCount + 1,
      lastError: error,
    );
  }

  /// 标记开始同步
  SyncOperation get syncing {
    return SyncOperation(
      id: id,
      type: type,
      diaryId: diaryId,
      data: data,
      createdAt: createdAt,
      status: SyncStatus.syncing,
      retryCount: retryCount,
      lastError: lastError,
    );
  }

  /// 计算下次重试延迟（指数退避，最大 60 秒）
  Duration get retryDelay {
    const maxSeconds = 60;
    const initialSeconds = 1;
    final seconds = initialSeconds * (1 << retryCount).clamp(0, maxSeconds);
    return Duration(seconds: seconds > maxSeconds ? maxSeconds : seconds);
  }
}
