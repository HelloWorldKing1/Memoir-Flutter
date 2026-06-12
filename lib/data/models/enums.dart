/// 记录类型
///
/// 与 PocketBase `diaries.entryType` Select 字段值一一对应。
enum EntryType {
  inspiration('inspiration', '灵感', '💡'),
  reflection('reflection', '感悟', '🤔'),
  diary('diary', '日记', '📔'),
  summary('summary', '总结', '📋'),
  article('article', '文章', '📝');

  const EntryType(this.value, this.label, this.emoji);

  final String value;
  final String label;
  final String emoji;

  static EntryType fromValue(String? value) {
    if (value == null) return EntryType.diary;
    return EntryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EntryType.diary,
    );
  }
}

/// 心情枚举
///
/// 与 PocketBase `diaries.mood` Select 字段值一一对应。
enum Mood {
  happy('happy', '开心', '😊'),
  neutral('neutral', '平淡', '😐'),
  sad('sad', '难过', '😢'),
  angry('angry', '生气', '😡'),
  love('love', '热爱', '🥰');

  const Mood(this.value, this.label, this.emoji);

  /// PocketBase 存储值
  final String value;

  /// 中文展示名
  final String label;

  /// 展示用 emoji
  final String emoji;

  /// 从 PocketBase 值反序列化
  static Mood fromValue(String value) {
    return Mood.values.firstWhere(
      (m) => m.value == value,
      orElse: () => Mood.neutral,
    );
  }
}

/// 天气枚举
///
/// 与 PocketBase `diaries.weather` Select 字段值一一对应。
enum Weather {
  sunny('sunny', '晴朗', '☀️'),
  cloudy('cloudy', '多云', '☁️'),
  rainy('rainy', '下雨', '🌧️'),
  snowy('snowy', '下雪', '❄️'),
  foggy('foggy', '起雾', '🌫️'),
  windy('windy', '大风', '💨'),
  stormy('stormy', '暴风雨', '⛈️'),
  rainbow('rainbow', '彩虹', '🌈');

  const Weather(this.value, this.label, this.emoji);

  /// PocketBase 存储值
  final String value;

  /// 中文展示名
  final String label;

  /// 展示用 emoji
  final String emoji;

  static Weather fromValue(String? value) {
    if (value == null) return Weather.sunny;
    return Weather.values.firstWhere(
      (w) => w.value == value,
      orElse: () => Weather.sunny,
    );
  }
}
