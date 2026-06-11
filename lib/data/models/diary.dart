import 'enums.dart';

/// 记录实体
///
/// 与 PocketBase `diaries` 集合字段对应。
/// 支持灵感、感悟、日记、总结、文章等多种场景。
/// 同时用于 Hive 本地缓存和 JSON 序列化。
class Diary {
  final String? id;
  final String title;
  final String content;
  final EntryType entryType;
  final Mood mood;
  final Weather? weather;
  final List<String> tags;
  final List<String> pictures;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isSynced;

  const Diary({
    this.id,
    required this.title,
    required this.content,
    this.entryType = EntryType.diary,
    this.mood = Mood.neutral,
    this.weather,
    this.tags = const [],
    this.pictures = const [],
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
  });

  /// 从 PocketBase RecordModel 创建
  factory Diary.fromRecord(Map<String, dynamic> record) {
    final tagsRaw = record['tags'];
    final picturesRaw = record['pictures'];

    return Diary(
      id: record['id'] as String?,
      title: record['title'] as String? ?? '',
      content: record['content'] as String? ?? '',
      entryType: EntryType.fromValue(record['entryType'] as String?),
      mood: Mood.fromValue(record['mood'] as String? ?? 'neutral'),
      weather: record['weather'] != null
          ? Weather.fromValue(record['weather'] as String?)
          : null,
      tags: tagsRaw is List ? tagsRaw.cast<String>() : [],
      pictures: picturesRaw is List ? picturesRaw.cast<String>() : [],
      userId: record['user'] as String?,
      createdAt: DateTime.tryParse(record['created'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(record['updated'] as String? ?? '') ??
          DateTime.now(),
      isDeleted: record['isDeleted'] as bool? ?? false,
    );
  }

  /// 转换为 PocketBase API 请求体
  Map<String, dynamic> toApiJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'entryType': entryType.value,
      'mood': mood.value,
      if (weather != null) 'weather': weather!.value,
      'tags': tags,
      'isDeleted': isDeleted,
    };
  }

  /// 完整 JSON 序列化（用于 Hive 存储 / 导出备份）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'entryType': entryType.value,
      'mood': mood.value,
      'weather': weather?.value,
      'tags': tags,
      'pictures': pictures,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'isSynced': isSynced,
    };
  }

  /// 从 JSON 反序列化
  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      entryType: EntryType.fromValue(json['entryType'] as String?),
      mood: Mood.fromValue(json['mood'] as String? ?? 'neutral'),
      weather: json['weather'] != null
          ? Weather.fromValue(json['weather'] as String?)
          : null,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      pictures: (json['pictures'] as List?)?.cast<String>() ?? [],
      userId: json['userId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  /// 创建副本（不可变模式）
  Diary copyWith({
    String? id,
    String? title,
    String? content,
    EntryType? entryType,
    Mood? mood,
    Weather? weather,
    List<String>? tags,
    List<String>? pictures,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isSynced,
  }) {
    return Diary(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      entryType: entryType ?? this.entryType,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      tags: tags ?? this.tags,
      pictures: pictures ?? this.pictures,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
