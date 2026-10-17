import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:nixsvg/models/vector_shape.dart';
import 'nix_color_models.dart';
import 'nix_color_picker.dart';

/// Shows an adaptive Material 3 Expressive Color & Gradient Picker.
///
/// On Desktop & Web (or when [anchorRect] is provided and screen is wide),
/// this displays as an anchored floating Popover beside the trigger.
/// On Mobile or narrow screens, it seamlessly adapts to a centered Dialog.
Future<Color?> showNixColorPicker({
  required BuildContext context,
  required Color initialColor,
  ShapeGradient? initialGradient,
  bool enableGradient = true,
  ColorPickerMode? initialMode,
  ValueChanged<Color>? onColorChanged,
  ValueChanged<ShapeGradient>? onGradientChanged,
  ValueChanged<ColorPickerMode>? onModeChanged,
  String title = 'Color & Gradient',
  Rect? anchorRect,
  GlobalKey? anchorKey,
  bool forceDialog = false,
  bool forcePopover = false,
}) async {
  // If a GlobalKey is passed, resolve its screen rect
  Rect? resolvedAnchor = anchorRect;
  if (resolvedAnchor == null && anchorKey != null) {
    final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final origin = renderBox.localToGlobal(Offset.zero);
      resolvedAnchor = origin & renderBox.size;
    }
  }

  final mediaQuery = MediaQuery.of(context);
  final isDesktopOrWide = mediaQuery.size.width >= 600;

  final shouldUsePopover = !forceDialog && (forcePopover || (isDesktopOrWide && resolvedAnchor != null));

  Color selectedColor = initialColor;

  if (shouldUsePopover && resolvedAnchor != null) {
    return showGeneralDialog<Color>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Color Picker',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _AnchoredColorPopover(
          anchorRect: resolvedAnchor!,
          child: NixColorPicker(
            initialColor: initialColor,
            initialGradient: initialGradient,
            enableGradient: enableGradient,
            initialMode: initialMode,
            title: title,
            onColorChanged: (c) {
              selectedColor = c;
              onColorChanged?.call(c);
            },
            onGradientChanged: onGradientChanged,
            onModeChanged: onModeChanged,
            onColorFinalized: (c) => selectedColor = c,
            onClose: () => Navigator.of(dialogContext).pop(selectedColor),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            alignment: _getPopoverAlignment(resolvedAnchor!, mediaQuery.size),
            child: child,
          ),
        );
      },
    );
  } else {
    // Dialog presentation (mobile, narrow screens, or centered)
    return showDialog<Color>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: NixColorPicker(
              initialColor: initialColor,
              initialGradient: initialGradient,
              enableGradient: enableGradient,
              initialMode: initialMode,
              title: title,
              onColorChanged: (c) {
                selectedColor = c;
                onColorChanged?.call(c);
              },
              onGradientChanged: onGradientChanged,
              onModeChanged: onModeChanged,
              onColorFinalized: (c) => selectedColor = c,
              onClose: () => Navigator.of(dialogContext).pop(selectedColor),
            ),
          ),
        );
      },
    );
  }
}

Alignment _getPopoverAlignment(Rect anchorRect, Size screenSize) {
  final double x = (anchorRect.center.dx / screenSize.width) * 2 - 1;
  final double y = (anchorRect.center.dy / screenSize.height) * 2 - 1;
  return Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
}

/// Floating anchored popover container with smart screen edge clamping
class _AnchoredColorPopover extends StatelessWidget {
  final Rect anchorRect;
  final Widget child;

  const _AnchoredColorPopover({
    required this.anchorRect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double popoverWidth = 330.0;
    const double estimatedHeight = 520.0;
    const double margin = 12.0;

    double left;
    double top;

    // Prefer opening to the left of the anchor if anchor is in the right half of the screen (e.g. Inspector sidebar)
    if (anchorRect.center.dx > screenSize.width / 2) {
      left = anchorRect.left - popoverWidth - margin;
      if (left < margin) {
        // Fallback: place below or above
        left = (screenSize.width - popoverWidth) / 2;
      }
    } else {
      // Anchor is on the left half: open to the right
      left = anchorRect.right + margin;
      if (left + popoverWidth > screenSize.width - margin) {
        left = (screenSize.width - popoverWidth) / 2;
      }
    }

    // Align vertically with the anchor center
    top = anchorRect.center.dy - (estimatedHeight / 2);
    // Clamp inside screen bounds
    top = top.clamp(margin, math.max(margin, screenSize.height - estimatedHeight - margin));
    left = left.clamp(margin, math.max(margin, screenSize.width - popoverWidth - margin));

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ],
    );
  }
}
