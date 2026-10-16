import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/grid_painter.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/ui/canvas/canvas_inline_text_editor.dart';

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
  final String? editingTextShapeId;
  final bool isEditingNewText;
  final bool selectAllText;
  final ValueChanged<String>? onInlineTextChanged;
  final VoidCallback? onInlineTextCommit;
  final VoidCallback? onInlineTextCancel;
  final ValueChanged<Rect>? onInlineTextRectChanged;
  final PointerDownEventListener onPointerDown;
  final PointerMoveEventListener onPointerMove;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;
  final Color? canvasBackgroundColor;
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
    this.editingTextShapeId,
    this.isEditingNewText = false,
    this.selectAllText = false,
    this.canvasBackgroundColor,
    this.onInlineTextChanged,
    this.onInlineTextCommit,
    this.onInlineTextCancel,
    this.onInlineTextRectChanged,
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
  int _lastTrackpadTime = 0;
  bool _innerHit = false;
  bool _outerDragActive = false;

  Offset _toCanvasCoordinates(Offset globalPos) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final viewportPos = box != null ? box.globalToLocal(globalPos) : globalPos;
    return CanvasTransformHelper.screenToCanvas(
      widget.transformationController.value,
      viewportPos,
    );
  }

  Matrix4 _getGlobalToCanvasMatrix() {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final boxOrigin =
        box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
    final matrix = widget.transformationController.value;
    final scale = CanvasTransformHelper.getScale(matrix);
    final tx = matrix.storage[12];
    final ty = matrix.storage[13];

    final m = Matrix4.identity();
    m.storage[0] = 1.0 / scale;
    m.storage[5] = 1.0 / scale;
    m.storage[12] = -(boxOrigin.dx + tx) / scale;
    m.storage[13] = -(boxOrigin.dy + ty) / scale;
    return m;
  }

  void _handlePointerSignal(PointerSignalEvent pointerSignal) {
    if (pointerSignal is! PointerScrollEvent) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final viewportPos = box != null
        ? box.globalToLocal(pointerSignal.position)
        : pointerSignal.localPosition;

    final isCtrlPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isCtrlPressed) {
      final double dy = pointerSignal.scrollDelta.dy;
      if (dy == 0.0 || !dy.isFinite) return;

      // Smooth exponential zoom scaling:
      // Handles both continuous trackpad micro-increments (Linux/Web pinch) and mouse wheel ticks
      final double rawFactor = math.exp(-dy * 0.006);
      final double zoomFactor = rawFactor.clamp(0.5, 2.0);

      widget.transformationController.value =
          CanvasTransformHelper.zoomAtScreenPoint(
            widget.transformationController.value,
            viewportPos,
            zoomFactor,
          );
      widget.onMatrixChanged();
    } else {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      Offset delta = -pointerSignal.scrollDelta;
      if (isShiftPressed) {
        delta = Offset(delta.dy, delta.dx);
      }
      if (delta != Offset.zero && delta.dx.isFinite && delta.dy.isFinite) {
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
    if (isPanActive || widget.currentMode == EditorMode.pan) {
      return SystemMouseCursors.grab;
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPanActive =
        widget.currentMode == EditorMode.pan || widget.isSpacePressed;
    final effectiveCanvasBg = widget.canvasBackgroundColor ?? colorScheme.surface;

    return MouseRegion(
      cursor: _getCanvasCursor(isPanActive),
      onEnter: (_) => widget.onCanvasHoverChanged?.call(true),
      onExit: (_) => widget.onCanvasHoverChanged?.call(false),
      onHover: (event) {
        final canvasPos = _toCanvasCoordinates(event.position);
        widget.onPointerHover?.call(canvasPos);
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: _handlePointerSignal,
        onPointerPanZoomStart: (_) {
          _lastTrackpadScale = 1.0;
          _lastTrackpadTime = DateTime.now().millisecondsSinceEpoch;
          _outerDragActive = false;
          _innerHit = false;
        },
        onPointerPanZoomUpdate: (event) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Reset stale scale if gesture paused or was interrupted (> 250ms gap)
          if (now - _lastTrackpadTime > 250 ||
              _lastTrackpadScale <= 0.0 ||
              !_lastTrackpadScale.isFinite) {
            _lastTrackpadScale = 1.0;
          }
          _lastTrackpadTime = now;

          var currentMatrix = widget.transformationController.value;

          // 1. Two-finger trackpad pan translation
          if (event.panDelta != Offset.zero &&
              event.panDelta.dx.isFinite &&
              event.panDelta.dy.isFinite) {
            currentMatrix = CanvasTransformHelper.panMatrix(
              currentMatrix,
              event.panDelta,
            );
          }

          // 2. Trackpad pinch-to-zoom scaling
          if (event.scale > 0.0 && event.scale.isFinite) {
            final double deltaFactor = event.scale / _lastTrackpadScale;
            _lastTrackpadScale = event.scale;

            if (deltaFactor.isFinite &&
                deltaFactor > 0.0 &&
                (deltaFactor - 1.0).abs() > 0.0001) {
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              final viewportPos = box != null
                  ? box.globalToLocal(event.position)
                  : event.localPosition;
              currentMatrix = CanvasTransformHelper.zoomAtScreenPoint(
                currentMatrix,
                viewportPos,
                deltaFactor,
              );
            }
          }

          widget.transformationController.value = currentMatrix;
          widget.onMatrixChanged();
        },
        onPointerPanZoomEnd: (_) {
          _lastTrackpadScale = 1.0;
          _lastTrackpadTime = 0;
        },
        onPointerDown: (event) {
          if (_innerHit) {
            _innerHit = false;
            return;
          }
          _outerDragActive = true;
          if (widget.editingTextShapeId != null) {
            widget.onInlineTextCommit?.call();
            FocusManager.instance.primaryFocus?.unfocus();
          }
          widget.onPointerDown(event.transformed(_getGlobalToCanvasMatrix()));
        },
        onPointerMove: (event) {
          if (!_outerDragActive) return;
          widget.onPointerMove(event.transformed(_getGlobalToCanvasMatrix()));
        },
        onPointerUp: (event) {
          if (!_outerDragActive) return;
          _outerDragActive = false;
          widget.onPointerUp(event.transformed(_getGlobalToCanvasMatrix()));
        },
        onPointerCancel: (event) {
          if (!_outerDragActive) return;
          _outerDragActive = false;
          widget.onPointerCancel(event.transformed(_getGlobalToCanvasMatrix()));
        },
        child: InteractiveViewer(
          transformationController: widget.transformationController,
          panEnabled: false,
          scaleEnabled: false,
          constrained: false,
          maxScale: CanvasTransformHelper.maxScale,
          minScale: CanvasTransformHelper.minScale,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _innerHit = true;
              _outerDragActive = false;
              if (widget.editingTextShapeId != null) {
                final editingShape = widget.shapes
                    .cast<VectorShape?>()
                    .firstWhere(
                      (s) => s?.id == widget.editingTextShapeId,
                      orElse: () => null,
                    );
                if (editingShape != null &&
                    CanvasHitTester.hitTestShape(
                      event.localPosition,
                      editingShape,
                    )) {
                  // Tapped inside active text editor to position cursor or select text
                  return;
                }
                // Tapped outside active text editor (on canvas background) -> commit
                widget.onInlineTextCommit?.call();
                FocusManager.instance.primaryFocus?.unfocus();
              }
              widget.onPointerDown(event);
            },
            onPointerMove: widget.onPointerMove,
            onPointerUp: widget.onPointerUp,
            onPointerCancel: widget.onPointerCancel,
            child: Container(
              width: 3200,
              height: 2400,
            decoration: BoxDecoration(
              color: effectiveCanvasBg,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.35 : 0.25,
                ),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Grid Background layer with RepaintBoundary
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(3200, 2400),
                    painter: GridPainter(
                      gridSpacing: widget.gridSpacing,
                      gridColor: colorScheme.onSurface.withValues(
                        alpha: isDark ? 0.08 : 0.06,
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
                      editingShapeId: widget.editingTextShapeId,
                    ),
                  ),
                ),

                // Canvas Inline Text Editor Overlay
                if (widget.editingTextShapeId != null) ...[
                  () {
                    final editingShape = widget.shapes
                        .cast<VectorShape?>()
                        .firstWhere(
                          (s) => s?.id == widget.editingTextShapeId,
                          orElse: () => null,
                        );
                    if (editingShape == null) return const SizedBox.shrink();
                    return CanvasInlineTextEditor(
                      key: ValueKey('canvas-text-editor-${editingShape.id}'),
                      shape: editingShape,
                      isNew: widget.isEditingNewText,
                      selectAll: widget.selectAllText,
                      onTextChanged: (text) =>
                          widget.onInlineTextChanged?.call(text),
                      onCommit: () => widget.onInlineTextCommit?.call(),
                      onCancel: () => widget.onInlineTextCancel?.call(),
                      onRectChanged: (newRect) =>
                          widget.onInlineTextRectChanged?.call(newRect),
                    );
                  }(),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
