/// 应用全局常量
class AppConstants {
  AppConstants._();

  /// PocketBase 服务地址
  static const String pocketBaseUrl = 'http://127.0.0.1:8090';

  /// 日记列表分页大小
  static const int diaryPageSize = 20;

  /// 图片缩略图最大宽度（像素）
  static const int thumbnailMaxWidth = 200;

  /// 同步重试最大间隔（秒）
  static const int syncMaxRetryIntervalSeconds = 60;

  /// 同步重试初始间隔（秒）
  static const int syncInitialRetryIntervalSeconds = 1;

  /// 日记标题最大长度
  static const int diaryTitleMaxLength = 200;

  /// 应用名称
  static const String appName = 'Memoir';
}
