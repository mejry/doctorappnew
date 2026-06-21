// lib/shared/widgets/buttons/icon_button.dart
import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? iconSize;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.iconSize = 20,
    this.tooltip,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(
        icon,
        color: iconColor ?? Theme.of(context).iconTheme.color,
        size: iconSize,
      ),
      onPressed: onPressed,
      padding: padding ?? const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      style: backgroundColor != null
          ? IconButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            )
          : null,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
