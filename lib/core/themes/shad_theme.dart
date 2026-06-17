import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 根据颜色方案名和亮度创建 ShadThemeData
///
/// 使用 [ShadColorScheme.fromName] 动态选择内置方案。
ShadThemeData createShadTheme(String colorSchemeName, Brightness brightness) {
  final colorScheme = ShadColorScheme.fromName(
    colorSchemeName,
    brightness: brightness,
  );

  return ShadThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
  );
}
