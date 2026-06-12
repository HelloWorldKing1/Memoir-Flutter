import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../data/models/enums.dart';

/// 快速记录组件。
///
/// 5 种记录类型的快速创建入口，点击进入编辑器并预选类型。
/// 桌面端按钮有鼠标悬浮效果（放大 + 加深底色 + 阴影）。
class QuickCapture extends StatelessWidget {
  final bool showTitle;

  const QuickCapture({super.key, this.showTitle = true});

  static const _typeColors = {
    EntryType.inspiration: Color(0xFFFFB300),
    EntryType.reflection: Color(0xFF7C4DFF),
    EntryType.diary: Color(0xFF448AFF),
    EntryType.summary: Color(0xFF009688),
    EntryType.article: Color(0xFF607D8B),
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
            child: Wrap(spacing: 10, runSpacing: 10, children: buttons),
          ),
      ],
    );
  }
}

/// 单个快速记录按钮 — 支持悬浮 + 点击动画
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
  late final AnimationController _hoverCtrl;
  late final Animation<double> _hoverScale;
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovering = hovering);
    if (hovering) {
      _hoverCtrl.forward();
    } else {
      _hoverCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 60.0 : 88.0;
    final height = widget.compact ? 52.0 : 68.0;
    final emojiSize = widget.compact ? 20.0 : 24.0;
    final labelSize = widget.compact ? 10.0 : 12.0;
    final color = widget.color;

    // 悬浮时底色加深
    final bgAlpha = _isHovering ? 0.22 : 0.10;
    final borderAlpha = _isHovering ? 0.6 : 0.3;

    return AnimatedScale(
      scale: _isPressed ? 0.92 : _hoverScale.value,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Material(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onHover: (hovering) => _onHover(hovering),
          onTap: () => context.push(AppRoutes.diaryNew, extra: widget.type),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.transparent,
          splashColor: color.withValues(alpha: 0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: borderAlpha),
                width: 1,
              ),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
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
                    color: color.withValues(alpha: _isHovering ? 1.0 : 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
