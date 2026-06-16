/// 灵感分类
///
/// 与 PocketBase `inspirations.category` Select 字段值一一对应。
enum InspirationCategory {
  writing('writing', '写作鼓励', '✍️'),
  creativity('creativity', '创意激发', '💡'),
  persistence('persistence', '坚持记录', '🌱'),
  wisdom('wisdom', '人生智慧', '🧠'),
  literature('literature', '文学之美', '📖'),
  mindfulness('mindfulness', '正念觉察', '🧘');

  const InspirationCategory(this.value, this.label, this.emoji);

  final String value;
  final String label;
  final String emoji;

  static InspirationCategory fromValue(String? value) {
    return InspirationCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InspirationCategory.writing,
    );
  }
}

/// 今日灵感实体
///
/// 对应 PocketBase `inspirations` 集合。
/// 用于首页「今日灵感」滚动展示，支持全局通用灵感 + 用户自定义灵感。
class Inspiration {
  final String? id;
  final String emoji;
  final String quote;
  final String author;
  final InspirationCategory? category;
  final bool isActive;
  final int priority;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Inspiration({
    this.id,
    required this.emoji,
    required this.quote,
    this.author = '未知',
    this.category,
    this.isActive = true,
    this.priority = 0,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 PocketBase RecordModel 创建
  factory Inspiration.fromRecord(Map<String, dynamic> record) {
    return Inspiration(
      id: record['id'] as String?,
      emoji: record['emoji'] as String? ?? '💡',
      quote: record['quote'] as String? ?? '',
      author: record['author'] as String? ?? '未知',
      category: InspirationCategory.fromValue(record['category'] as String?),
      isActive: record['isActive'] as bool? ?? true,
      priority: record['priority'] as int? ?? 0,
      userId: record['user'] as String?,
      createdAt: DateTime.tryParse(record['created'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(record['updated'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// 转换为 PocketBase API 请求体
  Map<String, dynamic> toApiJson() {
    return {
      if (id != null) 'id': id,
      'emoji': emoji,
      'quote': quote,
      'author': author,
      if (category != null) 'category': category!.value,
      'isActive': isActive,
      'priority': priority,
      if (userId != null) 'user': userId,
    };
  }

  /// 完整 JSON 序列化（用于 Hive 存储 / 导出备份）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'quote': quote,
      'author': author,
      'category': category?.value,
      'isActive': isActive,
      'priority': priority,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从 JSON 反序列化
  factory Inspiration.fromJson(Map<String, dynamic> json) {
    return Inspiration(
      id: json['id'] as String?,
      emoji: json['emoji'] as String? ?? '💡',
      quote: json['quote'] as String? ?? '',
      author: json['author'] as String? ?? '未知',
      category: InspirationCategory.fromValue(json['category'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      userId: json['userId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// 创建副本（不可变模式）
  Inspiration copyWith({
    String? id,
    String? emoji,
    String? quote,
    String? author,
    InspirationCategory? category,
    bool? isActive,
    int? priority,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inspiration(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      quote: quote ?? this.quote,
      author: author ?? this.author,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
