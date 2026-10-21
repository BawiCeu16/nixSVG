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

  final shouldUseAnchor = !forceDialog && (forcePopover || (isDesktopOrWide && resolvedAnchor != null));
  final Rect? effectiveAnchor = shouldUseAnchor ? resolvedAnchor : null;

  Color selectedColor = initialColor;

  return showGeneralDialog<Color>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Color Picker',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _DraggableColorPickerOverlay(
        anchorRect: effectiveAnchor,
        builder: (context, onDragDelta) {
          return NixColorPicker(
            initialColor: initialColor,
            initialGradient: initialGradient,
            enableGradient: enableGradient,
            initialMode: initialMode,
            title: title,
            onDragDelta: onDragDelta,
            onColorChanged: (c) {
              selectedColor = c;
              onColorChanged?.call(c);
            },
            onGradientChanged: onGradientChanged,
            onModeChanged: onModeChanged,
            onColorFinalized: (c) => selectedColor = c,
            onClose: () => Navigator.of(dialogContext).pop(selectedColor),
          );
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          alignment: effectiveAnchor != null
              ? _getPopoverAlignment(effectiveAnchor, mediaQuery.size)
              : Alignment.center,
          child: child,
        ),
      );
    },
  );
}

Alignment _getPopoverAlignment(Rect anchorRect, Size screenSize) {
  final double x = (anchorRect.center.dx / screenSize.width) * 2 - 1;
  final double y = (anchorRect.center.dy / screenSize.height) * 2 - 1;
  return Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
}

/// Floating draggable color picker overlay supporting both anchored position
/// and centered dialog presentation, draggable from the Header across the screen.
class _DraggableColorPickerOverlay extends StatefulWidget {
  final Rect? anchorRect;
  final Widget Function(BuildContext context, ValueChanged<Offset> onDragDelta) builder;

  const _DraggableColorPickerOverlay({
    this.anchorRect,
    required this.builder,
  });

  @override
  State<_DraggableColorPickerOverlay> createState() => _DraggableColorPickerOverlayState();
}

class _DraggableColorPickerOverlayState extends State<_DraggableColorPickerOverlay> {
  Offset? _position;
  final double _dialogWidth = 330.0;
  final double _estimatedHeight = 520.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double margin = 12.0;

    if (_position == null) {
      if (widget.anchorRect != null) {
        final anchor = widget.anchorRect!;
        double left;
        if (anchor.center.dx > screenSize.width / 2) {
          left = anchor.left - _dialogWidth - margin;
          if (left < margin) {
            left = (screenSize.width - _dialogWidth) / 2;
          }
        } else {
          left = anchor.right + margin;
          if (left + _dialogWidth > screenSize.width - margin) {
            left = (screenSize.width - _dialogWidth) / 2;
          }
        }
        double top = anchor.center.dy - (_estimatedHeight / 2);
        top = top.clamp(margin, math.max<double>(margin, screenSize.height - _estimatedHeight - margin));
        left = left.clamp(margin, math.max<double>(margin, screenSize.width - _dialogWidth - margin));
        _position = Offset(left, top);
      } else {
        // Centered dialog
        final left = math.max<double>(margin, (screenSize.width - _dialogWidth) / 2);
        final top = math.max<double>(margin, (screenSize.height - _estimatedHeight) / 2);
        _position = Offset(left, top);
      }
    } else {
      // Re-clamp if screen size changed
      final clampedX = _position!.dx.clamp(
        margin,
        math.max<double>(margin, screenSize.width - _dialogWidth - margin),
      );
      final clampedY = _position!.dy.clamp(
        margin,
        math.max<double>(margin, screenSize.height - 80.0),
      );
      if (clampedX != _position!.dx || clampedY != _position!.dy) {
        _position = Offset(clampedX, clampedY);
      }
    }

    return Stack(
      children: [
        Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: Material(
            color: Colors.transparent,
            child: widget.builder(context, (delta) {
              setState(() {
                final newX = (_position!.dx + delta.dx).clamp(
                  margin,
                  math.max<double>(margin, screenSize.width - _dialogWidth - margin),
                );
                final newY = (_position!.dy + delta.dy).clamp(
                  margin,
                  math.max<double>(margin, screenSize.height - 80.0),
                );
                _position = Offset(newX, newY);
              });
            }),
          ),
        ),
      ],
    );
  }
}
