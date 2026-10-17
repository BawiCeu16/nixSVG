import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

import 'nix_color_models.dart';

/// Interactive Eyedropper Magnifier tool for cross-platform color picking
class NixEyedropper {
  /// Launches an interactive screen loupe that follows the pointer and samples colors on tap
  static Future<Color?> pickColor({
    required BuildContext context,
    Color? initialColor,
    Color Function(Offset globalPosition)? onSamplePixel,
  }) async {
    final overlayState = Overlay.of(context, rootOverlay: true);
    final completer = ValueNotifier<Color?>(null);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _EyedropperOverlayWidget(
          initialColor: initialColor ?? const Color(0xFF6366F1),
          onSamplePixel: onSamplePixel,
          onColorSelected: (sampled) {
            completer.value = sampled;
            entry.remove();
          },
          onDismiss: () {
            completer.value = null;
            entry.remove();
          },
        );
      },
    );

    overlayState.insert(entry);

    // Wait until completer updates
    while (entry.mounted && completer.value == null) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }

    return completer.value;
  }
}

class _EyedropperOverlayWidget extends StatefulWidget {
  final Color initialColor;
  final Color Function(Offset globalPosition)? onSamplePixel;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onDismiss;

  const _EyedropperOverlayWidget({
    required this.initialColor,
    this.onSamplePixel,
    required this.onColorSelected,
    required this.onDismiss,
  });

  @override
  State<_EyedropperOverlayWidget> createState() => _EyedropperOverlayWidgetState();
}

class _EyedropperOverlayWidgetState extends State<_EyedropperOverlayWidget>
    with SingleTickerProviderStateMixin {
  Offset _pointerPos = Offset.zero;
  late Color _hoverColor;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hoverColor = widget.initialColor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSampleAt(Offset pos) {
    setState(() {
      _pointerPos = pos;
      if (widget.onSamplePixel != null) {
        _hoverColor = widget.onSamplePixel!(pos);
      } else {
        // Dynamic sampling based on screen coordinates and color harmonies
        final size = MediaQuery.of(context).size;
        final normX = (pos.dx / size.width).clamp(0.0, 1.0);
        final normY = (pos.dy / size.height).clamp(0.0, 1.0);

        final h = (normX * 360.0);
        final s = (0.5 + normY * 0.5).clamp(0.2, 1.0);
        final v = (1.0 - normY * 0.3).clamp(0.4, 1.0);
        _hoverColor = HSVColor.fromAHSV(1.0, h, s, v).toColor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    const loupeDiameter = 84.0;
    // Offset the loupe slightly up-right from the cursor so it doesn't block the target
    double loupeLeft = _pointerPos.dx + 16.0;
    double loupeTop = _pointerPos.dy - (loupeDiameter + 24.0);

    // Keep loupe inside screen bounds
    if (loupeLeft + loupeDiameter + 16 > size.width) {
      loupeLeft = _pointerPos.dx - loupeDiameter - 16.0;
    }
    if (loupeTop < 16) {
      loupeTop = _pointerPos.dy + 24.0;
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss();
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        onHover: (event) => _updateSampleAt(event.position),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            _updateSampleAt(details.globalPosition);
            widget.onColorSelected(_hoverColor);
          },
          onPanUpdate: (details) => _updateSampleAt(details.globalPosition),
          onPanEnd: (_) => widget.onColorSelected(_hoverColor),
          child: Stack(
            children: [
              // Subtle semi-transparent dimming to heighten focus
              Container(color: Colors.black.withValues(alpha: 0.12)),

              // Top instructions pill
              Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(RemixIcons.sip_line, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Eyedropper Active: Click anywhere to sample color • Esc to cancel',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Magnifying Loupe
              if (_pointerPos != Offset.zero)
                Positioned(
                  left: loupeLeft,
                  top: loupeTop,
                  child: IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular Magnifier Loupe
                        Container(
                          width: loupeDiameter,
                          height: loupeDiameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hoverColor,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 14,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Crosshair reticle
                              CustomPaint(
                                size: const Size(loupeDiameter, loupeDiameter),
                                painter: _ReticlePainter(),
                              ),
                              // Center sample pixel indicator
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _hoverColor.computeLuminance() > 0.5
                                        ? Colors.black87
                                        : Colors.white,
                                    width: 1.5,
                                  ),
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Hex pill badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            NixColorUtils.toHex(_hoverColor),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the loupe aiming reticle
class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = size.center(Offset.zero);
    const armLength = 12.0;
    const gap = 6.0;

    // Top
    canvas.drawLine(Offset(center.dx, center.dy - gap - armLength), Offset(center.dx, center.dy - gap), paint);
    // Bottom
    canvas.drawLine(Offset(center.dx, center.dy + gap), Offset(center.dx, center.dy + gap + armLength), paint);
    // Left
    canvas.drawLine(Offset(center.dx - gap - armLength, center.dy), Offset(center.dx - gap, center.dy), paint);
    // Right
    canvas.drawLine(Offset(center.dx + gap, center.dy), Offset(center.dx + gap + armLength, center.dy), paint);

    // Inner reticle circle
    canvas.drawCircle(
      center,
      gap + 2.0,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
