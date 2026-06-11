/// 心情枚举
///
/// 与 PocketBase `diaries.mood` Select 字段值一一对应。
enum Mood {
  happy('happy', '😊'),
  neutral('neutral', '😐'),
  sad('sad', '😢'),
  angry('angry', '😡'),
  love('love', '🥰');

  const Mood(this.value, this.emoji);

  /// PocketBase 存储值
  final String value;

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
  sunny('sunny', '☀️'),
  cloudy('cloudy', '☁️'),
  rainy('rainy', '🌧️');

  const Weather(this.value, this.emoji);

  final String value;
  final String emoji;

  static Weather fromValue(String? value) {
    if (value == null) return Weather.sunny;
    return Weather.values.firstWhere(
      (w) => w.value == value,
      orElse: () => Weather.sunny,
    );
  }
}
