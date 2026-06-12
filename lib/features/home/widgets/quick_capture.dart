import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../data/models/enums.dart';

/// 快速记录组件。
///
/// 5 种记录类型的快速创建入口，点击进入编辑器并预选类型。
///
/// 独立模式（[showTitle] = true）：带「快速记录」标题，桌面横排 / 手机横滑。
/// 嵌入模式（[showTitle] = false）：仅按钮，用于嵌入 GreetingHeader 右侧。
class QuickCapture extends StatelessWidget {
  /// 是否展示「快速记录」标题。
  final bool showTitle;

  const QuickCapture({super.key, this.showTitle = true});

  /// 每种类型的配色
  static const _typeColors = {
    EntryType.inspiration: Color(0xFFFFB300), // amber
    EntryType.reflection: Color(0xFF7C4DFF), // deepPurple
    EntryType.diary: Color(0xFF448AFF), // blue
    EntryType.summary: Color(0xFF009688), // teal
    EntryType.article: Color(0xFF607D8B), // blueGrey
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    final buttons = EntryType.values.map((type) {
      return _QuickCaptureButton(
        type: type,
        color: _typeColors[type]!,
        compact: isMobile,
      );
    }).toList();

    // 嵌入模式：仅按钮
    if (!showTitle) {
      if (isMobile) {
        return SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: buttons.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) => buttons[i],
          ),
        );
      }
      return Wrap(spacing: 8, runSpacing: 8, children: buttons);
    }

    // 独立模式：标题 + 按钮
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '快速记录',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (isMobile)
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: buttons.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => buttons[i],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: buttons,
            ),
          ),
      ],
    );
  }
}

/// 单个快速记录按钮
class _QuickCaptureButton extends StatefulWidget {
  final EntryType type;
  final Color color;
  final bool compact;

  const _QuickCaptureButton({
    required this.type,
    required this.color,
    this.compact = false,
  });

  @override
  State<_QuickCaptureButton> createState() => _QuickCaptureButtonState();
}

class _QuickCaptureButtonState extends State<_QuickCaptureButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 60.0 : 88.0;
    final height = widget.compact ? 52.0 : 68.0;
    final emojiSize = widget.compact ? 20.0 : 24.0;
    final labelSize = widget.compact ? 10.0 : 12.0;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          context.push(AppRoutes.diaryNew, extra: widget.type);
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.type.emoji, style: TextStyle(fontSize: emojiSize)),
              const SizedBox(height: 2),
              Text(
                widget.type.label,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                  color: widget.color.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
