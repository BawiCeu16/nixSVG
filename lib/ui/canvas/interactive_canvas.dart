import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/grid_painter.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';

/// The interactive center canvas workspace hosting the vector graphics painters,
/// grid background, interactive viewer, and pointer gesture listeners.
class InteractiveCanvas extends StatefulWidget {
  final TransformationController transformationController;
  final List<VectorShape> shapes;
  final Set<String> selectedShapeIds;
  final EditorMode currentMode;
  final ShapeType? draftShapeType;
  final bool? draftIsShiftPressed;
  final bool? draftIsAltPressed;
  final Offset? panStartOffset;
  final Offset? panCurrentOffset;
  final Rect? marqueeRect;
  final Offset? snapGuidelineX;
  final Offset? snapGuidelineY;
  final double gridSpacing;
  final bool isPanningWithMouse;
  final bool isSpacePressed;
  final bool isResizing;
  final PointerDownEventListener onPointerDown;
  final PointerMoveEventListener onPointerMove;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;
  final VoidCallback onMatrixChanged;
  final ValueChanged<bool>? onCanvasHoverChanged;
  final ValueChanged<Offset>? onPointerHover;

  const InteractiveCanvas({
    super.key,
    required this.transformationController,
    required this.shapes,
    required this.selectedShapeIds,
    required this.currentMode,
    required this.draftShapeType,
    this.draftIsShiftPressed,
    this.draftIsAltPressed,
    required this.panStartOffset,
    required this.panCurrentOffset,
    required this.marqueeRect,
    required this.snapGuidelineX,
    required this.snapGuidelineY,
    required this.gridSpacing,
    required this.isPanningWithMouse,
    required this.isSpacePressed,
    this.isResizing = false,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.onMatrixChanged,
    this.onCanvasHoverChanged,
    this.onPointerHover,
  });

  @override
  State<InteractiveCanvas> createState() => _InteractiveCanvasState();
}

class _InteractiveCanvasState extends State<InteractiveCanvas> {
  double _lastTrackpadScale = 1.0;

  void _handlePointerSignal(PointerSignalEvent pointerSignal) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (pointerSignal is PointerScrollEvent) {
      final isCtrlPressed =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (isCtrlPressed) {
        final double zoomFactor = pointerSignal.scrollDelta.dy < 0
            ? 1.15
            : (1.0 / 1.15);
        widget.transformationController.value =
            CanvasTransformHelper.scrollZoom(
              widget.transformationController.value,
              pointerSignal.localPosition,
              zoomFactor,
            );
        widget.onMatrixChanged();
      } else {
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
        Offset delta = -pointerSignal.scrollDelta;
        if (isShiftPressed) {
          delta = Offset(delta.dy, delta.dx);
        }
        widget.transformationController.value = CanvasTransformHelper.panMatrix(
          widget.transformationController.value,
          delta,
        );
        widget.onMatrixChanged();
      }
    }
  }

  MouseCursor _getCanvasCursor(bool isPanActive) {
    if (widget.isPanningWithMouse) return SystemMouseCursors.grabbing;
    if (isPanActive) return SystemMouseCursors.grab;
    switch (widget.currentMode) {
      case EditorMode.drawText:
        return SystemMouseCursors.text;
      case EditorMode.drawRectangle:
      case EditorMode.drawRoundedRectangle:
      case EditorMode.drawEllipse:
      case EditorMode.drawLine:
      case EditorMode.drawCurve:
      case EditorMode.drawStar:
        return SystemMouseCursors.precise;
      case EditorMode.select:
      case EditorMode.pan:
        return SystemMouseCursors.basic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPanActive =
        widget.currentMode == EditorMode.pan || widget.isSpacePressed;

    return InteractiveViewer(
      transformationController: widget.transformationController,
      panEnabled: false,
      scaleEnabled: false,
      maxScale: CanvasTransformHelper.maxScale,
      minScale: CanvasTransformHelper.minScale,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      child: MouseRegion(
        cursor: _getCanvasCursor(isPanActive),
        onEnter: (_) => widget.onCanvasHoverChanged?.call(true),
        onExit: (_) => widget.onCanvasHoverChanged?.call(false),
        onHover: (event) {
          widget.onPointerHover?.call(event.localPosition);
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            FocusManager.instance.primaryFocus?.unfocus();
            widget.onPointerDown(event);
          },
          onPointerMove: widget.onPointerMove,
          onPointerUp: widget.onPointerUp,
          onPointerCancel: widget.onPointerCancel,
          onPointerSignal: _handlePointerSignal,
          onPointerPanZoomStart: (_) {
            _lastTrackpadScale = 1.0;
          },
          onPointerPanZoomUpdate: (event) {
            FocusManager.instance.primaryFocus?.unfocus();
            if (event.panDelta != Offset.zero) {
              widget.transformationController.value =
                  CanvasTransformHelper.panMatrix(
                    widget.transformationController.value,
                    event.panDelta,
                  );
            }
            if (event.scale != 1.0 && event.scale > 0.0) {
              final double deltaFactor = event.scale / _lastTrackpadScale;
              _lastTrackpadScale = event.scale;
              if ((deltaFactor - 1.0).abs() > 0.0001) {
                widget.transformationController.value =
                    CanvasTransformHelper.scrollZoom(
                      widget.transformationController.value,
                      event.localPosition,
                      deltaFactor,
                    );
              }
            }
            widget.onMatrixChanged();
          },
          onPointerPanZoomEnd: (_) {
            _lastTrackpadScale = 1.0;
          },
          child: Container(
            width: 3200,
            height: 2400,
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surface
                : colorScheme.surface,
            child: Stack(
              children: [
                // Grid Background layer with RepaintBoundary
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(3200, 2400),
                    painter: GridPainter(
                      gridSpacing: widget.gridSpacing,
                      gridColor: colorScheme.onSurface.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.08
                            : 0.06,
                      ),
                      isDotGrid: true,
                    ),
                  ),
                ),

                // Vector Canvas Painter with RepaintBoundary for high 60fps performance
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(3200, 2400),
                    painter: VectorCanvasPainter(
                      shapes: widget.shapes,
                      selectedShapeIds: widget.selectedShapeIds,
                      draftStartPoint: widget.panStartOffset,
                      draftCurrentPoint: widget.panCurrentOffset,
                      draftShapeType: widget.draftShapeType,
                      draftIsShiftPressed: widget.draftIsShiftPressed,
                      draftIsAltPressed: widget.draftIsAltPressed,
                      marqueeRect: widget.marqueeRect,
                      currentMode: widget.currentMode,
                      isResizing: widget.isResizing,
                      snapGuidelineX: widget.snapGuidelineX,
                      snapGuidelineY: widget.snapGuidelineY,
                      colorScheme: colorScheme,
                    ),
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
