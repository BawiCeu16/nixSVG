import 'dart:math' as math;
import 'package:flutter/material.dart';

enum FigmaContextMenuItemType {
  action,
  divider,
}

/// Represents an item in a Figma / macOS style context menu.
class FigmaContextMenuEntry {
  final FigmaContextMenuItemType type;
  final String? title;
  final IconData? icon;
  final String? shortcut;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isEnabled;

  const FigmaContextMenuEntry.action({
    required this.title,
    this.icon,
    this.shortcut,
    this.onTap,
    this.isDestructive = false,
    this.isEnabled = true,
  }) : type = FigmaContextMenuItemType.action;

  const FigmaContextMenuEntry.divider()
      : type = FigmaContextMenuItemType.divider,
        title = null,
        icon = null,
        shortcut = null,
        onTap = null,
        isDestructive = false,
        isEnabled = true;
}

/// Convenience subclass for context menu items.
class FigmaMenuItem extends FigmaContextMenuEntry {
  const FigmaMenuItem({
    required String label,
    super.icon,
    super.shortcut,
    super.onTap,
    super.isDestructive = false,
    super.isEnabled = true,
  }) : super.action(
          title: label,
        );
}

/// Convenience subclass for context menu divider separator.
class FigmaMenuDivider extends FigmaContextMenuEntry {
  const FigmaMenuDivider() : super.divider();
}

bool _isMenuOpening = false;

/// Shows a desktop macOS / Figma-style context menu at [globalPosition].
Future<void> showFigmaContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required List<FigmaContextMenuEntry> items,
  double minWidth = 200,
}) async {
  // Prevent duplicate opens in the same event dispatch / frame
  if (_isMenuOpening) return;
  _isMenuOpening = true;
  Future.microtask(() => _isMenuOpening = false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final overlay = Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox? ??
        Navigator.maybeOf(context)?.overlay?.context.findRenderObject() as RenderBox?;
    final overlaySize = overlay?.size ?? MediaQuery.maybeOf(context)?.size ?? const Size(1920, 1080);

    final safeX = globalPosition.dx.clamp(0.0, math.max(0.0, overlaySize.width - 2)).toDouble();
    final safeY = globalPosition.dy.clamp(0.0, math.max(0.0, overlaySize.height - 2)).toDouble();

    final relativeRect = RelativeRect.fromRect(
      Rect.fromLTWH(safeX, safeY, 1, 1),
      Offset.zero & overlaySize,
    );

    final popupItems = <PopupMenuEntry<VoidCallback>>[];
    for (final item in items) {
      if (item.type == FigmaContextMenuItemType.divider) {
        popupItems.add(const _FigmaMenuDivider());
      } else {
        popupItems.add(
          _FigmaMenuItem(
            title: item.title!,
            icon: item.icon,
            shortcut: item.shortcut,
            isDestructive: item.isDestructive,
            isEnabled: item.isEnabled,
            onTap: item.onTap,
            minWidth: minWidth,
          ),
        );
      }
    }

    final selectedAction = await showMenu<VoidCallback>(
      context: context,
      position: relativeRect,
      items: popupItems,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.45,
          ),
          width: 1.0,
        ),
      ),
    );

    selectedAction?.call();
}

class _FigmaMenuItem extends PopupMenuItem<VoidCallback> {
  _FigmaMenuItem({
    required String title,
    IconData? icon,
    String? shortcut,
    bool isDestructive = false,
    bool isEnabled = true,
    VoidCallback? onTap,
    double minWidth = 200,
  }) : super(
          value: onTap,
          enabled: isEnabled,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: _FigmaMenuItemContent(
              title: title,
              icon: icon,
              shortcut: shortcut,
              isDestructive: isDestructive,
              isEnabled: isEnabled,
            ),
          ),
        );
}

class _FigmaMenuItemContent extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? shortcut;
  final bool isDestructive;
  final bool isEnabled;

  const _FigmaMenuItemContent({
    required this.title,
    this.icon,
    this.shortcut,
    required this.isDestructive,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isDestructive
        ? colorScheme.error
        : (isEnabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: 0.38));
    final iconColor = isDestructive
        ? colorScheme.error
        : (isEnabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurface.withValues(alpha: 0.38));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
        ] else ...[
          const SizedBox(width: 22),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        if (shortcut != null) ...[
          const SizedBox(width: 14),
          Text(
            shortcut!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isEnabled
                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.65)
                  : colorScheme.onSurface.withValues(alpha: 0.3),
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _FigmaMenuDivider extends PopupMenuEntry<Never> {
  const _FigmaMenuDivider();

  @override
  double get height => 8;

  @override
  bool represents(Never? value) => false;

  @override
  State<_FigmaMenuDivider> createState() => _FigmaMenuDividerState();
}

class _FigmaMenuDividerState extends State<_FigmaMenuDivider> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      height: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
