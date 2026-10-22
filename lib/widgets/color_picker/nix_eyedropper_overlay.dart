import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:nixsvg/main.dart';
import 'package:remixicon/remixicon.dart';

import 'nix_color_models.dart';

/// Screen snapshot data structure holding decoded raw RGBA pixels
class NixScreenSnapshot {
  final ui.Image image;
  final ByteData byteData;
  final double pixelRatio;
  final int width;
  final int height;

  const NixScreenSnapshot({
    required this.image,
    required this.byteData,
    required this.pixelRatio,
    required this.width,
    required this.height,
  });

  /// Extracts the exact pixel color at logical viewport coordinate [logicalPosition]
  Color getPixelColor(Offset logicalPosition) {
    final px = (logicalPosition.dx * pixelRatio).round().clamp(0, width - 1);
    final py = (logicalPosition.dy * pixelRatio).round().clamp(0, height - 1);
    final offset = (py * width + px) * 4;
    if (offset + 3 >= byteData.lengthInBytes) {
      return Colors.black;
    }
    final r = byteData.getUint8(offset);
    final g = byteData.getUint8(offset + 1);
    final b = byteData.getUint8(offset + 2);
    final a = byteData.getUint8(offset + 3);
    return Color.fromARGB(a, r, g, b);
  }

  /// Extracts a square grid of colors around [logicalPosition] for the magnifying loupe
  List<List<Color>> getPixelGrid(Offset logicalPosition, {int radius = 4}) {
    final px = (logicalPosition.dx * pixelRatio).round();
    final py = (logicalPosition.dy * pixelRatio).round();
    final size = radius * 2 + 1;
    final grid = List.generate(
      size,
      (_) => List.filled(size, Colors.transparent),
    );

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final curX = (px + dx).clamp(0, width - 1);
        final curY = (py + dy).clamp(0, height - 1);
        final offset = (curY * width + curX) * 4;
        if (offset + 3 < byteData.lengthInBytes) {
          final r = byteData.getUint8(offset);
          final g = byteData.getUint8(offset + 1);
          final b = byteData.getUint8(offset + 2);
          final a = byteData.getUint8(offset + 3);
          grid[dy + radius][dx + radius] = Color.fromARGB(a, r, g, b);
        }
      }
    }
    return grid;
  }
}

/// Interactive Eyedropper Magnifier tool for cross-platform color picking from the screen
class NixEyedropper {
  /// Captures the full screen pixels from root RepaintBoundary
  static Future<NixScreenSnapshot?> captureScreen(BuildContext context) async {
    try {
      RenderRepaintBoundary? boundary;
      final rootKeyContext = NixSvgApp.rootRepaintBoundaryKey.currentContext;
      if (rootKeyContext != null) {
        final ro = rootKeyContext.findRenderObject();
        if (ro is RenderRepaintBoundary && ro.hasSize) {
          boundary = ro;
        }
      }

      if (boundary == null || !boundary.hasSize) {
        context.visitAncestorElements((element) {
          final ro = element.findRenderObject();
          if (ro is RenderRepaintBoundary && ro.hasSize) {
            boundary = ro;
            return false;
          }
          return true;
        });
      }

      if (boundary == null || !boundary!.hasSize) {
        final rootViews = RendererBinding.instance.renderViews;
        if (rootViews.isNotEmpty) {
          RenderObject? firstChild = rootViews.first.child;
          while (firstChild is RenderObject) {
            if (firstChild is RenderRepaintBoundary && firstChild.hasSize) {
              boundary = firstChild;
              break;
            }
            if (firstChild is RenderObjectWithChildMixin) {
              firstChild = (firstChild as dynamic).child;
            } else {
              break;
            }
          }
        }
      }

      final activeBoundary = boundary;
      if (activeBoundary == null ||
          !activeBoundary.hasSize ||
          activeBoundary.debugNeedsPaint) {
        return null;
      }

      final pixelRatio = View.of(context).devicePixelRatio;
      final image = await activeBoundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return null;

      return NixScreenSnapshot(
        image: image,
        byteData: byteData,
        pixelRatio: pixelRatio,
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      debugPrint('Screen capture error for eyedropper: $e');
      return null;
    }
  }

  /// Launches an interactive screen loupe that follows the pointer and samples real screen colors on tap
  static Future<Color?> pickColor({
    required BuildContext context,
    Color? initialColor,
    Color Function(Offset globalPosition)? onSamplePixel,
    VoidCallback? onBeforeCapture,
    VoidCallback? onAfterCapture,
  }) async {
    onBeforeCapture?.call();
    if (!context.mounted) return null;

    final snapshot = await captureScreen(context);
    onAfterCapture?.call();
    if (!context.mounted) return null;

    final overlayState = Overlay.of(context, rootOverlay: true);
    final completer = Completer<Color?>();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _EyedropperOverlayWidget(
          initialColor: initialColor ?? const Color(0xFF6366F1),
          snapshot: snapshot,
          onSamplePixel: onSamplePixel,
          onColorSelected: (sampled) {
            if (!completer.isCompleted) {
              completer.complete(sampled);
            }
            if (entry.mounted) {
              entry.remove();
            }
          },
          onDismiss: () {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
            if (entry.mounted) {
              entry.remove();
            }
          },
        );
      },
    );

    overlayState.insert(entry);
    return await completer.future;
  }
}

class _EyedropperOverlayWidget extends StatefulWidget {
  final Color initialColor;
  final NixScreenSnapshot? snapshot;
  final Color Function(Offset globalPosition)? onSamplePixel;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onDismiss;

  const _EyedropperOverlayWidget({
    required this.initialColor,
    this.snapshot,
    this.onSamplePixel,
    required this.onColorSelected,
    required this.onDismiss,
  });

  @override
  State<_EyedropperOverlayWidget> createState() =>
      _EyedropperOverlayWidgetState();
}

class _EyedropperOverlayWidgetState extends State<_EyedropperOverlayWidget>
    with SingleTickerProviderStateMixin {
  Offset _pointerPos = Offset.zero;
  late Color _hoverColor;
  List<List<Color>> _pixelGrid = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hoverColor = widget.initialColor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSampleAt(Offset pos) {
    Color sampledColor;
    List<List<Color>> grid = [];

    if (widget.snapshot != null) {
      sampledColor = widget.snapshot!.getPixelColor(pos);
      grid = widget.snapshot!.getPixelGrid(pos, radius: 4);
    } else if (widget.onSamplePixel != null) {
      sampledColor = widget.onSamplePixel!(pos);
      grid = List.generate(9, (_) => List.filled(9, sampledColor));
    } else {
      sampledColor = widget.initialColor;
      grid = List.generate(9, (_) => List.filled(9, sampledColor));
    }

    setState(() {
      _pointerPos = pos;
      _hoverColor = sampledColor;
      _pixelGrid = grid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    const loupeDiameter = 112.0;
    // Offset loupe slightly up-right from the cursor so it never blocks the target pixel
    double loupeLeft = _pointerPos.dx + 24.0;
    double loupeTop = _pointerPos.dy - (loupeDiameter + 42.0);

    // Keep loupe inside screen bounds
    if (loupeLeft + loupeDiameter + 24 > size.width) {
      loupeLeft = _pointerPos.dx - loupeDiameter - 24.0;
    }
    if (loupeTop < 24) {
      loupeTop = _pointerPos.dy + 32.0;
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            widget.onDismiss();
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            widget.onColorSelected(_hoverColor);
          }
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        onHover: (event) => _updateSampleAt(event.position),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (event.buttons == kSecondaryMouseButton) {
              widget.onDismiss();
              return;
            }
            _updateSampleAt(event.position);
          },
          onPointerMove: (event) {
            _updateSampleAt(event.position);
          },
          onPointerUp: (event) {
            _updateSampleAt(event.position);
            widget.onColorSelected(_hoverColor);
          },
          child: Stack(
            children: [
              // Clear transparent interaction surface (does not dim so original colors stay true)
              const SizedBox.expand(),

              // Top instructions pill
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.96,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.sip_line,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Click to sample screen color • Esc to cancel',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
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
                        // Circular Magnifier Loupe with Pixel Grid
                        Container(
                          width: loupeDiameter,
                          height: loupeDiameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pixel Grid from real screen snapshot
                                if (_pixelGrid.isNotEmpty)
                                  CustomPaint(
                                    size: const Size(
                                      loupeDiameter,
                                      loupeDiameter,
                                    ),
                                    painter: _LoupePixelGridPainter(
                                      grid: _pixelGrid,
                                      centerColor: _hoverColor,
                                    ),
                                  )
                                else
                                  Container(color: _hoverColor),

                                // Precision Crosshair Reticle
                                CustomPaint(
                                  size: const Size(
                                    loupeDiameter,
                                    loupeDiameter,
                                  ),
                                  painter: _ReticlePainter(
                                    crossColor: _hoverColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Hex & RGB pill badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.38),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Swatch preview square
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: _hoverColor,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                NixColorUtils.toHex(_hoverColor),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'rgb(${(_hoverColor.r * 255).round()}, ${(_hoverColor.g * 255).round()}, ${(_hoverColor.b * 255).round()})',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

/// Custom painter for the loupe pixel grid
class _LoupePixelGridPainter extends CustomPainter {
  final List<List<Color>> grid;
  final Color centerColor;

  _LoupePixelGridPainter({
    required this.grid,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty) return;
    final int rows = grid.length;
    final int cols = grid.first.length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final cellPaint = Paint()..style = PaintingStyle.fill;
    final gridLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        cellPaint.color = grid[r][c];
        canvas.drawRect(rect, cellPaint);
        canvas.drawRect(rect, gridLinePaint);
      }
    }

    // Highlight center cell
    final midR = rows ~/ 2;
    final midC = cols ~/ 2;
    final centerRect = Rect.fromLTWH(midC * cellW, midR * cellH, cellW, cellH);

    final highlightPaint = Paint()
      ..color = centerColor.computeLuminance() > 0.5
          ? Colors.black.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(centerRect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _LoupePixelGridPainter oldDelegate) => true;
}

/// Custom painter for the loupe aiming crosshair reticle
class _ReticlePainter extends CustomPainter {
  final Color crossColor;

  _ReticlePainter({this.crossColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = crossColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = size.center(Offset.zero);
    const armLength = 14.0;
    const gap = 6.0;

    // Top
    canvas.drawLine(
      Offset(center.dx, center.dy - gap - armLength),
      Offset(center.dx, center.dy - gap),
      paint,
    );
    // Bottom
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + gap + armLength),
      paint,
    );
    // Left
    canvas.drawLine(
      Offset(center.dx - gap - armLength, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );
    // Right
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + gap + armLength, center.dy),
      paint,
    );

    // Inner reticle circle
    canvas.drawCircle(
      center,
      gap + 3.0,
      Paint()
        ..color = crossColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) => false;
}
