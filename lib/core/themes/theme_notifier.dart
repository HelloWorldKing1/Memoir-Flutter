import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// 可用的 shadcn 颜色方案名称列表
const availableColorSchemes = [
  'blue',
  'gray',
  'green',
  'neutral',
  'orange',
  'red',
  'rose',
  'slate',
  'stone',
  'violet',
  'yellow',
  'zinc',
];

/// 颜色方案中文名映射
const colorSchemeLabels = <String, String>{
  'blue': '蓝色',
  'gray': '灰色',
  'green': '绿色',
  'neutral': '中性',
  'orange': '橙色',
  'red': '红色',
  'rose': '玫瑰',
  'slate': '石板灰',
  'stone': '石色',
  'violet': '紫罗兰',
  'yellow': '黄色',
  'zinc': '锌灰',
};

/// 颜色方案对应的色相展示色
const colorSchemePreviewColors = <String, Color>{
  'blue': Color(0xFF3B82F6),
  'gray': Color(0xFF6B7280),
  'green': Color(0xFF22C55E),
  'neutral': Color(0xFF737373),
  'orange': Color(0xFFF97316),
  'red': Color(0xFFEF4444),
  'rose': Color(0xFFF43F5E),
  'slate': Color(0xFF64748B),
  'stone': Color(0xFF78716C),
  'violet': Color(0xFF8B5CF6),
  'yellow': Color(0xFFEAB308),
  'zinc': Color(0xFF71717A),
};

const _boxName = 'app_settings';
const _themeModeKey = 'themeMode';
const _colorSchemeKey = 'colorScheme';

Box _box(String boxName) => Hive.box(boxName);

/// 确保 Hive box 已打开（在 main 中调用一次）
Future<void> initSettingsBox() async {
  if (!Hive.isBoxOpen(_boxName)) {
    await Hive.openBox(_boxName);
  }
}

/// 主题模式 Notifier
///
/// 持久化到 Hive，默认跟随系统。
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = _box(_boxName).get(_themeModeKey) as String?;
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setThemeMode(ThemeMode mode) {
    _box(_boxName).put(_themeModeKey, mode.name);
    state = mode;
  }
}

/// 颜色方案 Notifier
///
/// 持久化到 Hive，默认 slate（石板灰）。
final colorSchemeProvider =
    NotifierProvider<ColorSchemeNotifier, String>(ColorSchemeNotifier.new);

class ColorSchemeNotifier extends Notifier<String> {
  @override
  String build() {
    final saved = _box(_boxName).get(_colorSchemeKey) as String?;
    return (saved != null && availableColorSchemes.contains(saved))
        ? saved
        : 'slate';
  }

  void setColorScheme(String name) {
    _box(_boxName).put(_colorSchemeKey, name);
    state = name;
  }
}
