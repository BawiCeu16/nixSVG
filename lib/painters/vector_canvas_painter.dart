import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/models/vector_shape.dart';

class VectorCanvasPainter extends CustomPainter {
  final List<VectorShape> shapes;
  final Set<String> selectedShapeIds;
  final Offset? draftStartPoint;
  final Offset? draftCurrentPoint;
  final ShapeType? draftShapeType;
  final bool? draftIsShiftPressed;
  final bool? draftIsAltPressed;
  final Rect? marqueeRect;
  final EditorMode currentMode;
  final bool isResizing;
  final ResizeHandle activeResizeHandle;
  final ResizeHandle hoveredHandle;
  final Offset? snapGuidelineX;
  final Offset? snapGuidelineY;
  final ColorScheme colorScheme;
  final String? editingShapeId;
  final double zoomScale;
  final int shapesRevision;
  final List<Offset>? activePenPoints;
  final List<PathNode>? activePenNodes;
  final Offset? activePenCursor;
  final bool isPenHoveringStart;
  final String? editingPathShapeId;
  final List<PathNode>? editingPathNodes;
  final Set<int>? selectedPathNodeIndices;
  final int? hoveredPathNodeIndex;
  final int? activeHandleNodeIndex;
  final int? activeHandleType;
  final bool isPathClosed;
  final VoidCallback? onImageDecoded;

  VectorCanvasPainter({
    required this.shapes,
    required this.selectedShapeIds,
    this.draftStartPoint,
    this.draftCurrentPoint,
    this.draftShapeType,
    this.draftIsShiftPressed,
    this.draftIsAltPressed,
    this.marqueeRect,
    required this.currentMode,
    this.isResizing = false,
    this.activeResizeHandle = ResizeHandle.none,
    this.hoveredHandle = ResizeHandle.none,
    this.snapGuidelineX,
    this.snapGuidelineY,
    required this.colorScheme,
    this.editingShapeId,
    this.zoomScale = 1.0,
    this.activePenPoints,
    this.activePenNodes,
    this.activePenCursor,
    this.isPenHoveringStart = false,
    this.editingPathShapeId,
    this.editingPathNodes,
    this.selectedPathNodeIndices,
    this.hoveredPathNodeIndex,
    this.activeHandleNodeIndex,
    this.activeHandleType,
    this.isPathClosed = false,
    this.onImageDecoded,
    super.repaint,
    int? shapesRevision,
  }) : shapesRevision = shapesRevision ?? _computeShapesRevision(shapes);

  static int _computeShapesRevision(List<VectorShape> shapes) {
    int hash = shapes.length;
    for (int i = 0; i < shapes.length; i++) {
      final s = shapes[i];
      int shapeState = s.revision * 31;
      if (s.isVisible) shapeState += 17;
      if (s.isLocked) shapeState += 19;
      shapeState += (s.rect.left * 10).toInt();
      shapeState += (s.rect.top * 10).toInt();
      shapeState += (s.rect.width * 10).toInt();
      shapeState += (s.rect.height * 10).toInt();
      if (s.decodedImage != null) {
        shapeState += (s.decodedImage.hashCode & 0x7fff) + 23;
      }
      hash = 0x1fffffff & (hash * 31 + shapeState + s.id.hashCode);
    }
    return hash;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw existing vector shapes with viewport AABB culling
    final canvasBounds = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final shape in shapes) {
      if (!shape.isVisible) continue;
      if (!canvasBounds.overlaps(shape.getBoundingBox())) continue;
      _drawShape(canvas, shape);
    }

    // 2. Draw selection overlays for selected shapes
    if (marqueeRect != null) {
      for (final shape in shapes) {
        if (selectedShapeIds.contains(shape.id) && shape.isVisible) {
          _drawIndividualSelectionOutline(canvas, shape);
        }
      }
    } else if (selectedShapeIds.length > 1) {
      Rect? combinedBounds;
      for (final shape in shapes) {
        if (selectedShapeIds.contains(shape.id) && shape.isVisible) {
          _drawIndividualSelectionOutline(canvas, shape);
          combinedBounds = combinedBounds == null
              ? shape.rect
              : combinedBounds.expandToInclude(shape.rect);
        }
      }
      if (combinedBounds != null) {
        _drawMultiSelectionBoundingBox(canvas, combinedBounds);
      }
    } else {
      for (final shape in shapes) {
        if (selectedShapeIds.contains(shape.id) && shape.isVisible) {
          if (shape.id != editingShapeId) {
            _drawSelectionBox(canvas, shape);
          }
        }
      }
    }

    // 3. Draw draft shape being created
    if (draftStartPoint != null &&
        draftCurrentPoint != null &&
        draftShapeType != null) {
      final isShift = draftIsShiftPressed ?? false;
      final isAlt = draftIsAltPressed ?? false;
      final draftRect = CanvasGeometry.calculateDrawRect(
        start: draftStartPoint!,
        current: draftCurrentPoint!,
        shapeType: draftShapeType!,
        isShiftPressed: isShift,
        isAltPressed: isAlt,
      );
      _drawDraftShape(canvas, draftRect, draftShapeType!);
      _drawDimensionBadge(canvas, draftRect, shapeType: draftShapeType);
    }

    // 4. Draw marquee selection box if dragging marquee
    if (marqueeRect != null) {
      final normalized = Rect.fromLTRB(
        math.min(marqueeRect!.left, marqueeRect!.right),
        math.min(marqueeRect!.top, marqueeRect!.bottom),
        math.max(marqueeRect!.left, marqueeRect!.right),
        math.max(marqueeRect!.top, marqueeRect!.bottom),
      );
      final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
      final marqueePaint = Paint()
        ..color = colorScheme.primaryContainer.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      final marqueeBorder = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * s;
      canvas.drawRect(normalized, marqueePaint);
      canvas.drawRect(normalized, marqueeBorder);
    }

    // 5. Draw snap guidelines
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    if (snapGuidelineX != null) {
      final snapPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 1.2 * s;
      canvas.drawLine(
        snapGuidelineX!,
        Offset(snapGuidelineX!.dx, size.height),
        snapPaint,
      );
    }
    if (snapGuidelineY != null) {
      final snapPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 1.2 * s;
      canvas.drawLine(
        snapGuidelineY!,
        Offset(size.width, snapGuidelineY!.dy),
        snapPaint,
      );
    }

    // 6. Draw active Pen Tool live preview & anchor nodes (Figma / Illustrator style)
    if (activePenNodes != null && activePenNodes!.isNotEmpty) {
      final nodes = activePenNodes!;

      // 6a. Placed segments (Cubic Bézier)
      if (nodes.length > 1) {
        final penPath = CanvasGeometry.nodesToPath(nodes);
        final penStroke = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(penPath, penStroke);
      }

      // 6b. Prospective rubber-band curve to cursor / closing start
      if (activePenCursor != null) {
        final prospective = CanvasGeometry.calculateProspectiveCurve(
          nodes.last,
          activePenCursor!,
          firstNode: isPenHoveringStart && nodes.length >= 2 ? nodes.first : null,
        );
        final guidePaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * s;
        final dashedGuide = CanvasGeometry.dashPath(
          prospective,
          dashLength: 4.0 * s,
          dashGap: 4.0 * s,
        );
        canvas.drawPath(dashedGuide, guidePaint);
      }

      // 6c. Control handle arms & knob circles
      final armPaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * s;

      for (int i = 0; i < nodes.length; i++) {
        final node = nodes[i];

        // Inbound handle
        if (node.handleIn != null) {
          canvas.drawLine(node.position, node.handleIn!, armPaint);
          canvas.drawCircle(
            node.handleIn!,
            3.5 * s,
            Paint()..color = Colors.white..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            node.handleIn!,
            3.5 * s,
            Paint()
              ..color = colorScheme.primary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 * s,
          );
        }

        // Outbound handle
        if (node.handleOut != null) {
          canvas.drawLine(node.position, node.handleOut!, armPaint);
          canvas.drawCircle(
            node.handleOut!,
            3.5 * s,
            Paint()..color = Colors.white..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            node.handleOut!,
            3.5 * s,
            Paint()
              ..color = colorScheme.primary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 * s,
          );
        }
      }

      // 6d. Vector anchor point squares & closing glyph
      for (int i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        final isStart = i == 0;
        final isLast = i == nodes.length - 1;

        // If hovering near start point to close, draw ring
        if (isStart && isPenHoveringStart && nodes.length >= 2) {
          canvas.drawCircle(
            node.position,
            9.0 * s,
            Paint()
              ..color = colorScheme.tertiary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 * s,
          );
        }

        // Anchor square (Figma / Illustrator precision)
        final half = 3.5 * s;
        final squareRect = Rect.fromCenter(
          center: node.position,
          width: half * 2,
          height: half * 2,
        );

        canvas.drawRect(
          squareRect,
          Paint()
            ..color = isLast ? colorScheme.primary : Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          squareRect,
          Paint()
            ..color = colorScheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * s,
        );
      }

      // If hovering near start to close, also draw small circle indicator near cursor
      if (isPenHoveringStart && activePenCursor != null) {
        canvas.drawCircle(
          activePenCursor! + Offset(12.0 * s, 12.0 * s),
          3.5 * s,
          Paint()
            ..color = colorScheme.tertiary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * s,
        );
      }
    } else if (activePenPoints != null && activePenPoints!.isNotEmpty) {
      // Fallback simple points renderer
      if (activePenPoints!.length > 1) {
        final penPath = CanvasGeometry.createSmoothPathFromPoints(
          activePenPoints!,
        );
        final penStroke = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(penPath, penStroke);
      }

      if (activePenCursor != null) {
        final lastPoint = activePenPoints!.last;
        final guideLine = Path()
          ..moveTo(lastPoint.dx, lastPoint.dy)
          ..lineTo(activePenCursor!.dx, activePenCursor!.dy);
        final dashedGuide = CanvasGeometry.dashPath(
          guideLine,
          dashLength: 4.0 * s,
          dashGap: 4.0 * s,
        );
        final guidePaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * s;
        canvas.drawPath(dashedGuide, guidePaint);
      }

      for (int i = 0; i < activePenPoints!.length; i++) {
        final p = activePenPoints![i];
        final isStart = i == 0;
        final isClosingHover = isStart &&
            activePenCursor != null &&
            activePenPoints!.length >= 3 &&
            (activePenCursor! - p).distance <= 14.0 * s;

        if (isClosingHover) {
          canvas.drawCircle(
            p,
            8.0 * s,
            Paint()
              ..color = colorScheme.tertiary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 * s,
          );
        }

        canvas.drawCircle(
          p,
          4.0 * s,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          p,
          4.0 * s,
          Paint()
            ..color = isStart ? colorScheme.tertiary : colorScheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * s,
        );
      }
    }

    // 7. Vector Path Node Editing Overlay (when in Vector Node Edit Mode)
    if (editingPathShapeId != null &&
        editingPathNodes != null &&
        editingPathNodes!.isNotEmpty) {
      _drawVectorNodeEditingOverlay(canvas, s);
    }
  }

  void _drawVectorNodeEditingOverlay(Canvas canvas, double s) {
    final nodes = editingPathNodes!;
    final selectedIndices = selectedPathNodeIndices ?? const {};

    // 1. Live path contour preview
    if (nodes.length > 1) {
      final path = CanvasGeometry.nodesToPath(nodes, isClosed: isPathClosed);
      final segmentPaint = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, segmentPaint);
    }

    // 2. Control handles for selected and hovered nodes
    final armPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isSelected = selectedIndices.contains(i);
      final isHovered = hoveredPathNodeIndex == i;

      if (isSelected || isHovered) {
        // Inbound handle
        if (node.handleIn != null) {
          canvas.drawLine(node.position, node.handleIn!, armPaint);
          final isDraggingThis = activeHandleNodeIndex == i && activeHandleType == 1;
          canvas.drawCircle(
            node.handleIn!,
            4.0 * s,
            Paint()
              ..color = isDraggingThis ? colorScheme.primary : Colors.white
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            node.handleIn!,
            4.0 * s,
            Paint()
              ..color = colorScheme.primary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 * s,
          );
        }

        // Outbound handle
        if (node.handleOut != null) {
          canvas.drawLine(node.position, node.handleOut!, armPaint);
          final isDraggingThis = activeHandleNodeIndex == i && activeHandleType == 2;
          canvas.drawCircle(
            node.handleOut!,
            4.0 * s,
            Paint()
              ..color = isDraggingThis ? colorScheme.primary : Colors.white
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            node.handleOut!,
            4.0 * s,
            Paint()
              ..color = colorScheme.primary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5 * s,
          );
        }
      }
    }

    // 3. Anchor points (Corner = crisp square, Smooth = crisp circle)
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isSelected = selectedIndices.contains(i);
      final isHovered = hoveredPathNodeIndex == i;

      // Outer hover accent ring
      if (isHovered) {
        canvas.drawCircle(
          node.position,
          8.5 * s,
          Paint()
            ..color = colorScheme.primary.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0 * s,
        );
      }

      if (node.isCorner) {
        final half = 4.0 * s;
        final squareRect = Rect.fromCenter(
          center: node.position,
          width: half * 2,
          height: half * 2,
        );
        canvas.drawRect(
          squareRect,
          Paint()
            ..color = isSelected ? colorScheme.primary : Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          squareRect,
          Paint()
            ..color = isSelected ? Colors.white : colorScheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * s,
        );
      } else {
        canvas.drawCircle(
          node.position,
          4.5 * s,
          Paint()
            ..color = isSelected ? colorScheme.primary : Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          node.position,
          4.5 * s,
          Paint()
            ..color = isSelected ? Colors.white : colorScheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * s,
        );
      }
    }
  }

  Shader? _createShader(ShapeGradient gradient, Rect bounds, double opacity) {
    // If width or height is 0 (like a horizontal or vertical line), inflate slightly
    final safeBounds = bounds.isEmpty ? bounds.inflate(1.0) : bounds;

    final colors = gradient.stops
        .map(
          (s) =>
              s.color.withValues(alpha: (s.color.a * opacity).clamp(0.0, 1.0)),
        )
        .toList();
    final stops = gradient.stops.map((s) => s.offset).toList();

    if (gradient.type == PaintFillType.linearGradient) {
      // Calculate normalized unit direction vector for the angle
      final rad = gradient.angle * math.pi / 180.0;
      final cosA = math.cos(rad);
      final sinA = math.sin(rad);

      // Begin and end alignments across the bounding box [-1, 1]
      final begin = Alignment(-cosA, -sinA);
      final end = Alignment(cosA, sinA);

      return LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
        stops: stops,
      ).createShader(safeBounds);
    } else {
      return RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: colors,
        stops: stops,
      ).createShader(safeBounds);
    }
  }

  void _drawShape(Canvas canvas, VectorShape shape) {
    canvas.save();

    final center = shape.rect.center;
    if (shape.rotation != 0.0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }

    final fillPaint = Paint()..style = PaintingStyle.fill;
    if (shape.fillType != PaintFillType.solid && shape.fillGradient != null) {
      fillPaint.shader = _createShader(
        shape.fillGradient!,
        shape.rect,
        shape.fillOpacity,
      );
    } else {
      fillPaint.color = shape.fillColor.withValues(alpha: shape.fillOpacity);
    }

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.strokeWidth
      ..strokeCap = shape.strokeCap;

    if (shape.strokeType != PaintFillType.solid &&
        shape.strokeGradient != null) {
      strokePaint.shader = _createShader(
        shape.strokeGradient!,
        shape.rect,
        shape.strokeOpacity,
      );
    } else {
      strokePaint.color = shape.strokeColor.withValues(
        alpha: shape.strokeOpacity,
      );
    }

    void drawStrokedPath(Path path, {Path? shapeBoundary}) {
      if (!shape.isStroked) return;

      void renderStroke(Paint paint) {
        if (shape.strokeStyle == StrokeStyle.solid) {
          canvas.drawPath(path, paint);
        } else {
          final dashLength = shape.strokeStyle == StrokeStyle.dashed
              ? shape.strokeDashLength
              : shape.strokeWidth;
          final dashGap = shape.strokeStyle == StrokeStyle.dashed
              ? shape.strokeDashGap
              : (shape.strokeWidth * 1.5);
          final dashed = shape.getDashedPath(
            dashLength,
            dashGap,
            shape.strokeStyle,
          );
          canvas.drawPath(dashed, paint);
        }
      }

      // If closed shape with inside or outside alignment
      if (shapeBoundary != null && shape.strokeAlign != StrokeAlign.center) {
        canvas.save();
        if (shape.strokeAlign == StrokeAlign.inside) {
          canvas.clipPath(shapeBoundary);
        } else if (shape.strokeAlign == StrokeAlign.outside) {
          // Clip to outside of the boundary (inverse clip)
          final bounds = shape.rect.inflate(shape.strokeWidth * 3 + 10.0);
          final outerPath = Path()..addRect(bounds);
          final clipOut = Path.combine(
            PathOperation.difference,
            outerPath,
            shapeBoundary,
          );
          canvas.clipPath(clipOut);
        }

        // Draw with 2x stroke width because half will be clipped off
        final alignedPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = shape.strokeWidth * 2
          ..strokeCap = shape.strokeCap;
        if (strokePaint.shader != null) {
          alignedPaint.shader = strokePaint.shader;
        } else {
          alignedPaint.color = strokePaint.color;
        }

        renderStroke(alignedPaint);
        canvas.restore();
      } else {
        renderStroke(strokePaint);
      }
    }

    switch (shape.type) {
      case ShapeType.rectangle:
        final maxR = math.min(shape.rect.width, shape.rect.height) / 2;
        final hasRadius = shape.cornerRadius > 0 || shape.hasIndependentCorners;
        if (hasRadius) {
          if (shape.cornerSmoothing > 0.0) {
            final path = shape.getPath();
            if (shape.isFilled) canvas.drawPath(path, fillPaint);
            if (shape.isStroked) {
              drawStrokedPath(path, shapeBoundary: path);
            }
          } else {
            final rrect = shape.hasIndependentCorners
                ? RRect.fromRectAndCorners(
                    shape.rect,
                    topLeft: Radius.circular(
                      shape.effectiveTopLeftRadius.clamp(0.0, maxR),
                    ),
                    topRight: Radius.circular(
                      shape.effectiveTopRightRadius.clamp(0.0, maxR),
                    ),
                    bottomRight: Radius.circular(
                      shape.effectiveBottomRightRadius.clamp(0.0, maxR),
                    ),
                    bottomLeft: Radius.circular(
                      shape.effectiveBottomLeftRadius.clamp(0.0, maxR),
                    ),
                  )
                : RRect.fromRectAndRadius(
                    shape.rect,
                    Radius.circular(shape.cornerRadius.clamp(0.0, maxR)),
                  );
            if (shape.isFilled) canvas.drawRRect(rrect, fillPaint);
            if (shape.isStroked) {
              final path = shape.getPath();
              drawStrokedPath(path, shapeBoundary: path);
            }
          }
        } else {
          if (shape.isFilled) canvas.drawRect(shape.rect, fillPaint);
          if (shape.isStroked) {
            final path = shape.getPath();
            drawStrokedPath(path, shapeBoundary: path);
          }
        }
        break;

      case ShapeType.roundedRectangle:
        final maxR = math.min(shape.rect.width, shape.rect.height) / 2;
        if (shape.cornerSmoothing > 0.0) {
          final path = shape.getPath();
          if (shape.isFilled) canvas.drawPath(path, fillPaint);
          if (shape.isStroked) {
            drawStrokedPath(path, shapeBoundary: path);
          }
        } else {
          final rrect = shape.hasIndependentCorners
              ? RRect.fromRectAndCorners(
                  shape.rect,
                  topLeft: Radius.circular(
                    shape.effectiveTopLeftRadius.clamp(0.0, maxR),
                  ),
                  topRight: Radius.circular(
                    shape.effectiveTopRightRadius.clamp(0.0, maxR),
                  ),
                  bottomRight: Radius.circular(
                    shape.effectiveBottomRightRadius.clamp(0.0, maxR),
                  ),
                  bottomLeft: Radius.circular(
                    shape.effectiveBottomLeftRadius.clamp(0.0, maxR),
                  ),
                )
              : RRect.fromRectAndRadius(
                  shape.rect,
                  Radius.circular(shape.cornerRadius.clamp(0.0, maxR)),
                );
          if (shape.isFilled) canvas.drawRRect(rrect, fillPaint);
          if (shape.isStroked) {
            final path = shape.getPath();
            drawStrokedPath(path, shapeBoundary: path);
          }
        }
        break;

      case ShapeType.ellipse:
        if (shape.isFilled) canvas.drawOval(shape.rect, fillPaint);
        if (shape.isStroked) {
          final path = shape.getPath();
          drawStrokedPath(path, shapeBoundary: path);
        }
        break;

      case ShapeType.line:
        if (!shape.isStroked) break;

        final p1 = shape.rect.topLeft;
        final p2 = shape.rect.bottomRight;
        final dx = p2.dx - p1.dx;
        final dy = p2.dy - p1.dy;
        final lineLen = math.sqrt(dx * dx + dy * dy);
        if (lineLen == 0.0) break;

        Offset? markerCtrl;
        if (shape.isCurved || shape.curvature != 0.0) {
          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          final perp = Offset(-dy / lineLen, dx / lineLen);
          markerCtrl = mid + perp * shape.curvature;
        }

        final hasStartArrow = shape.startCap == LineCapStyle.arrow;
        final hasEndArrow = shape.endCap == LineCapStyle.arrow;

        final baseArrowSize = math.max(10.0, shape.strokeWidth * 3.0);
        final startArrowSize = math.min(baseArrowSize, lineLen * 0.8);
        final endArrowSize = math.min(baseArrowSize, lineLen * 0.8);

        final trimStartDist = hasStartArrow ? startArrowSize * 0.7 : 0.0;
        final trimEndDist = hasEndArrow ? endArrowSize * 0.7 : 0.0;

        Path pathToStroke;
        if (hasStartArrow || hasEndArrow) {
          if (!shape.isCurved && shape.curvature == 0.0) {
            // Analytical trimming for straight lines without Skia PathMetrics overhead
            final totalLen = lineLen;
            final effectiveStartTrim = math.min(totalLen * 0.45, trimStartDist);
            final effectiveEndTrim = math.min(totalLen * 0.45, trimEndDist);
            if (effectiveStartTrim + effectiveEndTrim < totalLen) {
              final startFrac = effectiveStartTrim / totalLen;
              final endFrac = (totalLen - effectiveEndTrim) / totalLen;
              final tStart = Offset(p1.dx + dx * startFrac, p1.dy + dy * startFrac);
              final tEnd = Offset(p1.dx + dx * endFrac, p1.dy + dy * endFrac);
              pathToStroke = Path()
                ..moveTo(tStart.dx, tStart.dy)
                ..lineTo(tEnd.dx, tEnd.dy);
            } else {
              pathToStroke = shape.getPath();
            }
          } else {
            // Curved line trimming using iterator without list allocation
            pathToStroke = shape.getPath();
            final metrics = pathToStroke.computeMetrics();
            final it = metrics.iterator;
            if (it.moveNext()) {
              final metric = it.current;
              final totalLen = metric.length;
              final effectiveStartTrim = math.min(totalLen * 0.45, trimStartDist);
              final effectiveEndTrim = math.min(totalLen * 0.45, trimEndDist);
              if (effectiveStartTrim + effectiveEndTrim < totalLen) {
                pathToStroke = metric.extractPath(
                  effectiveStartTrim,
                  totalLen - effectiveEndTrim,
                );
              }
            }
          }
        } else {
          pathToStroke = shape.getPath();
        }

        if (hasStartArrow || hasEndArrow) {
          final origCap = strokePaint.strokeCap;
          strokePaint.strokeCap = StrokeCap.butt;
          drawStrokedPath(pathToStroke);
          strokePaint.strokeCap = origCap;
        } else {
          drawStrokedPath(pathToStroke);
        }

        if (markerCtrl != null) {
          _drawLineCapMarker(canvas, p1, markerCtrl, shape.startCap, shape);
          _drawLineCapMarker(canvas, p2, markerCtrl, shape.endCap, shape);
        } else {
          _drawLineCapMarker(canvas, p1, p2, shape.startCap, shape);
          _drawLineCapMarker(canvas, p2, p1, shape.endCap, shape);
        }
        break;

      case ShapeType.star:
        final path = shape.getPath();
        if (shape.isFilled) canvas.drawPath(path, fillPaint);
        if (shape.isStroked) drawStrokedPath(path, shapeBoundary: path);
        break;

      case ShapeType.polygon:
        final path = shape.getPath();
        if (shape.isFilled) canvas.drawPath(path, fillPaint);
        if (shape.isStroked) drawStrokedPath(path, shapeBoundary: path);
        break;

      case ShapeType.path:
        final path = shape.getPath();
        if (shape.isFilled) canvas.drawPath(path, fillPaint);
        if (shape.isStroked) drawStrokedPath(path, shapeBoundary: path);
        break;

      case ShapeType.text:
        if (shape.id == editingShapeId) {
          // Inline editor handles active rendering
          break;
        }
        final isGradientText =
            shape.fillType != PaintFillType.solid && shape.fillGradient != null;
        final textPainter = shape.getTextPainter(
          fillPaint: isGradientText ? fillPaint : null,
        );

        // Vertical alignment calculation within shape.rect
        double offsetY = shape.rect.top;
        if (shape.textVerticalAlign == TextVerticalAlign.center) {
          offsetY =
              shape.rect.top +
              math.max(0.0, (shape.rect.height - textPainter.height) / 2);
        } else if (shape.textVerticalAlign == TextVerticalAlign.bottom) {
          offsetY =
              shape.rect.top +
              math.max(0.0, shape.rect.height - textPainter.height);
        }

        textPainter.paint(canvas, Offset(shape.rect.left, offsetY));
        break;

      case ShapeType.image:
        final maxR = math.min(shape.rect.width, shape.rect.height) / 2;
        final hasRadius = shape.cornerRadius > 0 || shape.hasIndependentCorners;
        final rrect = hasRadius
            ? (shape.hasIndependentCorners
                ? RRect.fromRectAndCorners(
                    shape.rect,
                    topLeft: Radius.circular(
                      shape.effectiveTopLeftRadius.clamp(0.0, maxR),
                    ),
                    topRight: Radius.circular(
                      shape.effectiveTopRightRadius.clamp(0.0, maxR),
                    ),
                    bottomRight: Radius.circular(
                      shape.effectiveBottomRightRadius.clamp(0.0, maxR),
                    ),
                    bottomLeft: Radius.circular(
                      shape.effectiveBottomLeftRadius.clamp(0.0, maxR),
                    ),
                  )
                : RRect.fromRectAndRadius(
                    shape.rect,
                    Radius.circular(shape.cornerRadius.clamp(0.0, maxR)),
                  ))
            : null;

        if (shape.decodedImage != null) {
          final srcRect = Rect.fromLTWH(
            0,
            0,
            shape.decodedImage!.width.toDouble(),
            shape.decodedImage!.height.toDouble(),
          );
          final imagePaint = Paint()..filterQuality = FilterQuality.medium;
          if (shape.cornerSmoothing > 0.0 && hasRadius) {
            canvas.save();
            canvas.clipPath(shape.getPath());
            canvas.drawImageRect(
              shape.decodedImage!,
              srcRect,
              shape.rect,
              imagePaint,
            );
            canvas.restore();
          } else if (rrect != null) {
            canvas.save();
            canvas.clipRRect(rrect);
            canvas.drawImageRect(
              shape.decodedImage!,
              srcRect,
              shape.rect,
              imagePaint,
            );
            canvas.restore();
          } else {
            canvas.drawImageRect(
              shape.decodedImage!,
              srcRect,
              shape.rect,
              imagePaint,
            );
          }
        } else {
          if (shape.imageBytes != null && shape.imageBytes!.isNotEmpty) {
            shape.ensureImageDecoded(onDecoded: onImageDecoded);
          }
          final placeholderPaint = Paint()
            ..color = const Color(0xFF64748B).withValues(alpha: 0.12)
            ..style = PaintingStyle.fill;
          if (shape.cornerSmoothing > 0.0 && hasRadius) {
            canvas.drawPath(shape.getPath(), placeholderPaint);
          } else if (rrect != null) {
            canvas.drawRRect(rrect, placeholderPaint);
          } else {
            canvas.drawRect(shape.rect, placeholderPaint);
          }
        }
        if (shape.isStroked) {
          if (hasRadius) {
            final path = shape.getPath();
            drawStrokedPath(path, shapeBoundary: path);
          } else {
            canvas.drawRect(shape.rect, strokePaint);
          }
        }
        break;
    }

    canvas.restore();
  }

  Path _generateStarPath(
    Rect rect, {
    int points = 5,
    double innerRadiusRatio = 0.4,
    double cornerRadius = 0.0,
  }) => CanvasGeometry.createStarPath(
    rect,
    points: points,
    innerRadiusRatio: innerRadiusRatio,
    cornerRadius: cornerRadius,
  );

  void _drawSelectionBox(Canvas canvas, VectorShape shape) {
    if (shape.id == editingPathShapeId) {
      return;
    }
    canvas.save();

    final center = shape.rect.center;
    if (shape.rotation != 0.0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }

    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);

    final handleFill = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;

    if (shape.type == ShapeType.line) {
      final startPt = shape.rect.topLeft;
      final endPt = shape.rect.bottomRight;

      final linePaint = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * s;

      if (shape.isCurved || shape.curvature != 0.0) {
        final mid = Offset(
          (startPt.dx + endPt.dx) / 2,
          (startPt.dy + endPt.dy) / 2,
        );
        final dx = endPt.dx - startPt.dx;
        final dy = endPt.dy - startPt.dy;
        final len = math.sqrt(dx * dx + dy * dy);
        final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
        final controlPt = mid + perp * shape.curvature;

        final path = Path()
          ..moveTo(startPt.dx, startPt.dy)
          ..quadraticBezierTo(controlPt.dx, controlPt.dy, endPt.dx, endPt.dy);
        canvas.drawPath(path, linePaint);

        // Guide dash line
        final guidePaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * s;
        canvas.drawLine(startPt, controlPt, guidePaint);
        canvas.drawLine(endPt, controlPt, guidePaint);

        // Circular Bend Handle
        canvas.drawCircle(controlPt, 6 * s, handleFill);
        canvas.drawCircle(
          controlPt,
          6 * s,
          handleBorder..strokeWidth = 1.5 * s,
        );
      } else {
        canvas.drawLine(startPt, endPt, linePaint);
      }

      for (final pt in [startPt, endPt]) {
        final handleRect = Rect.fromCenter(
          center: pt,
          width: 10 * s,
          height: 10 * s,
        );
        canvas.drawRect(handleRect, handleFill);
        canvas.drawRect(
          handleRect,
          handleBorder..strokeWidth = 1.5 * s,
        );
      }

      canvas.restore();
      return;
    }

    final rect = shape.rect;
    final boxPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s;

    canvas.drawRect(rect, boxPaint);

    final handlePoints = {
      ResizeHandle.topLeft: rect.topLeft,
      ResizeHandle.topRight: rect.topRight,
      ResizeHandle.bottomLeft: rect.bottomLeft,
      ResizeHandle.bottomRight: rect.bottomRight,
      ResizeHandle.topCenter: rect.topCenter,
      ResizeHandle.bottomCenter: rect.bottomCenter,
      ResizeHandle.centerLeft: rect.centerLeft,
      ResizeHandle.centerRight: rect.centerRight,
    };

    for (final entry in handlePoints.entries) {
      final pt = entry.value;
      final isHovered = hoveredHandle == entry.key ||
          activeResizeHandle == entry.key;
      final size = (isHovered ? 12.0 : 10.0) * s;
      final handleRect = Rect.fromCenter(center: pt, width: size, height: size);

      // Subtle shadow for Mac-like polish
      canvas.drawRect(
        handleRect.shift(Offset(0, 0.8 * s)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.2 * s),
      );

      canvas.drawRect(
        handleRect,
        isHovered
            ? (Paint()..color = colorScheme.primary..style = PaintingStyle.fill)
            : handleFill,
      );
      canvas.drawRect(
        handleRect,
        isHovered
            ? (Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5 * s)
            : (handleBorder..strokeWidth = 1.5 * s),
      );
    }

    // Top rotation handle
    final rotCenter = Offset(rect.topCenter.dx, rect.topCenter.dy - 20 * s);
    final isRotHovered = hoveredHandle == ResizeHandle.rotation ||
        activeResizeHandle == ResizeHandle.rotation;
    final linePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.85)
      ..strokeWidth = 1.5 * s;
    canvas.drawLine(rect.topCenter, rotCenter, linePaint);
    canvas.drawCircle(
      rotCenter,
      (isRotHovered ? 6.5 : 5.0) * s,
      isRotHovered
          ? (Paint()..color = colorScheme.primary..style = PaintingStyle.fill)
          : handleFill,
    );
    canvas.drawCircle(
      rotCenter,
      (isRotHovered ? 6.5 : 5.0) * s,
      isRotHovered
          ? (Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5 * s)
          : (handleBorder..strokeWidth = 1.5 * s),
    );

    // Figma-style corner radius handles inside rectangles
    final radiusHandles = CanvasHitTester.getRadiusHandlePositions(
      shape,
      zoomScale: zoomScale,
    );
    if (radiusHandles.isNotEmpty) {
      final radiusHandleFill = Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.fill;
      final radiusHandleBorder = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * s;
      final radiusHoverFill = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.fill;

      for (final entry in radiusHandles.entries) {
        final pt = entry.value;
        final isHovered = hoveredHandle == entry.key ||
            activeResizeHandle == entry.key;

        // Shadow behind corner radius handle for crispness
        canvas.drawCircle(
          pt + Offset(0, 0.8 * s),
          (isHovered ? 5.5 : 4.5) * s,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.22)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 * s),
        );

        canvas.drawCircle(
          pt,
          (isHovered ? 5.5 : 4.2) * s,
          isHovered ? radiusHoverFill : radiusHandleFill,
        );
        canvas.drawCircle(
          pt,
          (isHovered ? 5.5 : 4.2) * s,
          isHovered
              ? (Paint()
                ..color = Colors.white
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5 * s)
              : radiusHandleBorder,
        );
      }
    }

    // Show live width, height, and radius badge while resizing or dragging radius
    if (isResizing || activeResizeHandle != ResizeHandle.none) {
      _drawDimensionBadge(
        canvas,
        rect,
        shapeType: shape.type,
        cornerRadius: (shape.type == ShapeType.roundedRectangle ||
                shape.type == ShapeType.rectangle ||
                shape.type == ShapeType.star ||
                shape.type == ShapeType.polygon ||
                shape.type == ShapeType.image)
            ? (activeResizeHandle == ResizeHandle.radiusTopLeft
                ? shape.effectiveTopLeftRadius
                : activeResizeHandle == ResizeHandle.radiusTopRight
                    ? shape.effectiveTopRightRadius
                    : activeResizeHandle == ResizeHandle.radiusBottomLeft
                        ? shape.effectiveBottomLeftRadius
                        : activeResizeHandle == ResizeHandle.radiusBottomRight
                            ? shape.effectiveBottomRightRadius
                            : shape.cornerRadius)
            : null,
        ratio: (shape.type == ShapeType.star &&
                activeResizeHandle == ResizeHandle.ratio)
            ? shape.innerRadiusRatio
            : null,
      );
    }

    canvas.restore();
  }

  void _drawIndividualSelectionOutline(Canvas canvas, VectorShape shape) {
    canvas.save();
    final center = shape.rect.center;
    if (shape.rotation != 0.0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    final outlinePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * s;
    canvas.drawRect(shape.rect, outlinePaint);
    canvas.restore();
  }

  void _drawMultiSelectionBoundingBox(Canvas canvas, Rect bounds) {
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    final boxPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s;
    canvas.drawRect(bounds, boxPaint);

    final handleFill = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s;

    final handlePoints = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
      bounds.topCenter,
      bounds.bottomCenter,
      bounds.centerLeft,
      bounds.centerRight,
    ];

    for (final pt in handlePoints) {
      final handleRect = Rect.fromCenter(
        center: pt,
        width: 9 * s,
        height: 9 * s,
      );
      canvas.drawRect(handleRect, handleFill);
      canvas.drawRect(handleRect, handleBorder);
    }
  }

  void _drawDraftShape(Canvas canvas, Rect rect, ShapeType type) {
    final fillPaint = Paint()
      ..color = colorScheme.primaryContainer.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    switch (type) {
      case ShapeType.rectangle:
      case ShapeType.text:
      case ShapeType.image:
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        break;
      case ShapeType.roundedRectangle:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
        break;
      case ShapeType.ellipse:
        canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
        break;
      case ShapeType.line:
        canvas.drawLine(rect.topLeft, rect.bottomRight, strokePaint);
        break;
      case ShapeType.star:
        final path = _generateStarPath(rect);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
      case ShapeType.polygon:
        final path = CanvasGeometry.createPolygonPath(rect, sides: 6);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
      case ShapeType.path:
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        break;
    }
  }

  void _drawDimensionBadge(
    Canvas canvas,
    Rect rect, {
    ShapeType? shapeType,
    double? cornerRadius,
    double? ratio,
  }) {
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    final width = rect.width.abs().round();
    final height = rect.height.abs().round();

    // Check if shape is circle (ellipse with width == height) or ellipse
    final isCircle =
        shapeType == ShapeType.ellipse && (width - height).abs() <= 1;
    final isEllipse = shapeType == ShapeType.ellipse;

    String badgeText;
    if (isCircle) {
      final radius = (width / 2).round();
      badgeText = '$width × $height  (r: $radius)';
    } else if (isEllipse) {
      final rx = (width / 2).round();
      final ry = (height / 2).round();
      badgeText = '$width × $height  (rx: $rx, ry: $ry)';
    } else if (shapeType == ShapeType.star && ratio != null) {
      badgeText = '$width × $height  (ratio: ${(ratio * 100).round()}%)';
    } else if ((shapeType == ShapeType.roundedRectangle ||
            shapeType == ShapeType.rectangle ||
            shapeType == ShapeType.star ||
            shapeType == ShapeType.polygon ||
            shapeType == ShapeType.image) &&
        cornerRadius != null &&
        cornerRadius > 0) {
      badgeText = '$width × $height  (r: ${cornerRadius.round()})';
    } else if (shapeType == ShapeType.line) {
      final dx = rect.right - rect.left;
      final dy = rect.bottom - rect.top;
      final length = math.sqrt(dx * dx + dy * dy).round();
      final angleDeg = (math.atan2(dy, dx) * 180 / math.pi).round();
      badgeText = 'L: $length  $angleDeg°';
    } else {
      badgeText = '$width × $height';
    }

    final textSpan = TextSpan(
      text: badgeText,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 11 * s,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final left = math.min(rect.left, rect.right);
    final bottom = math.max(rect.top, rect.bottom);
    final badgePos = Offset(left, bottom + 8 * s);
    final bgRect = Rect.fromLTWH(
      badgePos.dx - 6 * s,
      badgePos.dy - 3 * s,
      textPainter.width + 12 * s,
      textPainter.height + 6 * s,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(6 * s)),
      Paint()
        ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(6 * s)),
      Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * s,
    );
    textPainter.paint(canvas, badgePos);
  }

  void _drawLineCapMarker(
    Canvas canvas,
    Offset point,
    Offset toward,
    LineCapStyle capStyle,
    VectorShape shape,
  ) {
    if (capStyle == LineCapStyle.none) return;

    final dx = point.dx - toward.dx;
    final dy = point.dy - toward.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final angle = math.atan2(dy, dx);
    final color = shape.strokeColor.withValues(alpha: shape.strokeOpacity);
    final baseSize = math.max(10.0, shape.strokeWidth * 3.0);
    final size = math.min(baseSize, dist * 0.8);

    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(angle);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (capStyle) {
      case LineCapStyle.arrow:
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(-size, -size * 0.4)
          ..lineTo(-size * 0.7, 0)
          ..lineTo(-size, size * 0.4)
          ..close();
        canvas.drawPath(path, fillPaint);
        break;
      case LineCapStyle.circle:
        final radius = math.max(4.0, shape.strokeWidth * 1.5);
        canvas.drawCircle(Offset.zero, radius, fillPaint);
        break;
      case LineCapStyle.square:
        final squareSize = math.max(6.0, shape.strokeWidth * 2.0);
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: squareSize,
          height: squareSize,
        );
        canvas.drawRect(rect, fillPaint);
        break;
      case LineCapStyle.round:
        final radius = math.max(4.0, shape.strokeWidth * 1.5);
        canvas.drawCircle(Offset.zero, radius, fillPaint);
        break;
      case LineCapStyle.none:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VectorCanvasPainter oldDelegate) {
    if (oldDelegate.onImageDecoded != onImageDecoded) return true;
    if (oldDelegate.currentMode != currentMode) return true;
    if (oldDelegate.isResizing != isResizing) return true;
    if (oldDelegate.activeResizeHandle != activeResizeHandle) return true;
    if (oldDelegate.hoveredHandle != hoveredHandle) return true;
    if (oldDelegate.draftStartPoint != draftStartPoint) return true;
    if (oldDelegate.draftCurrentPoint != draftCurrentPoint) return true;
    if (oldDelegate.draftShapeType != draftShapeType) return true;
    if (oldDelegate.draftIsShiftPressed != draftIsShiftPressed) return true;
    if (oldDelegate.draftIsAltPressed != draftIsAltPressed) return true;
    if (oldDelegate.marqueeRect != marqueeRect) return true;
    if (oldDelegate.snapGuidelineX != snapGuidelineX) return true;
    if (oldDelegate.snapGuidelineY != snapGuidelineY) return true;
    if (oldDelegate.editingShapeId != editingShapeId) return true;
    if (oldDelegate.zoomScale != zoomScale) return true;
    if (oldDelegate.colorScheme != colorScheme) return true;
    if (oldDelegate.shapesRevision != shapesRevision) return true;
    if (oldDelegate.activePenPoints != activePenPoints) return true;
    if (oldDelegate.activePenNodes != activePenNodes) return true;
    if (oldDelegate.activePenCursor != activePenCursor) return true;
    if (oldDelegate.isPenHoveringStart != isPenHoveringStart) return true;
    if (oldDelegate.editingPathShapeId != editingPathShapeId) return true;
    if (oldDelegate.editingPathNodes != editingPathNodes) return true;
    if (oldDelegate.selectedPathNodeIndices != selectedPathNodeIndices) return true;
    if (oldDelegate.hoveredPathNodeIndex != hoveredPathNodeIndex) return true;
    if (oldDelegate.activeHandleNodeIndex != activeHandleNodeIndex) return true;
    if (oldDelegate.activeHandleType != activeHandleType) return true;
    if (oldDelegate.isPathClosed != isPathClosed) return true;
    if (oldDelegate.shapes.length != shapes.length) return true;
    if (oldDelegate.selectedShapeIds.length != selectedShapeIds.length) return true;
    if (!setEquals(oldDelegate.selectedShapeIds, selectedShapeIds)) return true;

    for (int i = 0; i < shapes.length; i++) {
      if (!identical(oldDelegate.shapes[i], shapes[i]) ||
          oldDelegate.shapes[i].revision != shapes[i].revision ||
          oldDelegate.shapes[i].decodedImage != shapes[i].decodedImage) {
        return true;
      }
    }

    return false;
  }
}
