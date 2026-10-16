import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
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
  final Offset? snapGuidelineX;
  final Offset? snapGuidelineY;
  final ColorScheme colorScheme;
  final String? editingShapeId;

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
    this.snapGuidelineX,
    this.snapGuidelineY,
    required this.colorScheme,
    this.editingShapeId,
  });

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
      final marqueePaint = Paint()
        ..color = colorScheme.primaryContainer.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      final marqueeBorder = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRect(normalized, marqueePaint);
      canvas.drawRect(normalized, marqueeBorder);
    }

    // 5. Draw snap guidelines
    if (snapGuidelineX != null) {
      final snapPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 1.2;
      canvas.drawLine(
        snapGuidelineX!,
        Offset(snapGuidelineX!.dx, size.height),
        snapPaint,
      );
    }
    if (snapGuidelineY != null) {
      final snapPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 1.2;
      canvas.drawLine(
        snapGuidelineY!,
        Offset(size.width, snapGuidelineY!.dy),
        snapPaint,
      );
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
        if (shape.isFilled) canvas.drawRect(shape.rect, fillPaint);
        if (shape.isStroked) {
          final path = shape.getPath();
          drawStrokedPath(path, shapeBoundary: path);
        }
        break;

      case ShapeType.roundedRectangle:
        final rrect = RRect.fromRectAndRadius(
          shape.rect,
          Radius.circular(shape.cornerRadius),
        );
        if (shape.isFilled) canvas.drawRRect(rrect, fillPaint);
        if (shape.isStroked) {
          final path = shape.getPath();
          drawStrokedPath(path, shapeBoundary: path);
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

        Path pathToStroke = shape.getPath();

        if (hasStartArrow || hasEndArrow) {
          final metrics = pathToStroke.computeMetrics().toList();
          if (metrics.isNotEmpty) {
            final totalLen = metrics.first.length;
            final effectiveStartTrim = math.min(totalLen * 0.45, trimStartDist);
            final effectiveEndTrim = math.min(totalLen * 0.45, trimEndDist);
            if (effectiveStartTrim + effectiveEndTrim < totalLen) {
              pathToStroke = metrics.first.extractPath(
                effectiveStartTrim,
                totalLen - effectiveEndTrim,
              );
            }
          }
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
        if (shape.decodedImage != null) {
          final srcRect = Rect.fromLTWH(
            0,
            0,
            shape.decodedImage!.width.toDouble(),
            shape.decodedImage!.height.toDouble(),
          );
          canvas.drawImageRect(
            shape.decodedImage!,
            srcRect,
            shape.rect,
            Paint(),
          );
        } else {
          canvas.drawRect(shape.rect, fillPaint);
        }
        if (shape.isStroked) canvas.drawRect(shape.rect, strokePaint);
        break;
    }

    canvas.restore();
  }

  Path _generateStarPath(Rect rect) => CanvasGeometry.createStarPath(rect);

  void _drawSelectionBox(Canvas canvas, VectorShape shape) {
    canvas.save();

    final center = shape.rect.center;
    if (shape.rotation != 0.0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }

    final handleFill = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    if (shape.type == ShapeType.line) {
      final startPt = shape.rect.topLeft;
      final endPt = shape.rect.bottomRight;

      final linePaint = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

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
          ..strokeWidth = 1.0;
        canvas.drawLine(startPt, controlPt, guidePaint);
        canvas.drawLine(endPt, controlPt, guidePaint);

        // Circular Bend Handle
        canvas.drawCircle(controlPt, 6, handleFill);
        canvas.drawCircle(controlPt, 6, handleBorder);
      } else {
        canvas.drawLine(startPt, endPt, linePaint);
      }

      for (final pt in [startPt, endPt]) {
        final handleRect = Rect.fromCenter(center: pt, width: 10, height: 10);
        canvas.drawRect(handleRect, handleFill);
        canvas.drawRect(handleRect, handleBorder);
      }

      canvas.restore();
      return;
    }

    final rect = shape.rect;
    final boxPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRect(rect, boxPaint);

    final handlePoints = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
      rect.topCenter,
      rect.bottomCenter,
      rect.centerLeft,
      rect.centerRight,
    ];

    for (final pt in handlePoints) {
      final handleRect = Rect.fromCenter(center: pt, width: 10, height: 10);
      canvas.drawRect(handleRect, handleFill);
      canvas.drawRect(handleRect, handleBorder);
    }

    // Top rotation handle
    final rotCenter = Offset(rect.topCenter.dx, rect.topCenter.dy - 20);
    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 1.5;
    canvas.drawLine(rect.topCenter, rotCenter, linePaint);
    canvas.drawCircle(rotCenter, 5, handleFill);
    canvas.drawCircle(rotCenter, 5, handleBorder);

    // Figma-style corner radius handles inside rectangles
    if ((shape.type == ShapeType.rectangle ||
            shape.type == ShapeType.roundedRectangle) &&
        rect.width >= 40 &&
        rect.height >= 40) {
      final radiusInset = math.min(
        16.0,
        math.min(rect.width, rect.height) * 0.2,
      );
      final radiusHandleFill = Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.fill;
      final radiusHandleBorder = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final radiusHandles = [
        Offset(rect.left + radiusInset, rect.top + radiusInset),
        Offset(rect.right - radiusInset, rect.top + radiusInset),
        Offset(rect.left + radiusInset, rect.bottom - radiusInset),
        Offset(rect.right - radiusInset, rect.bottom - radiusInset),
      ];
      for (final pt in radiusHandles) {
        canvas.drawCircle(pt, 3.5, radiusHandleFill);
        canvas.drawCircle(pt, 3.5, radiusHandleBorder);
      }
    }

    // Show live width, height, and radius badge while resizing
    if (isResizing) {
      _drawDimensionBadge(
        canvas,
        rect,
        shapeType: shape.type,
        cornerRadius: shape.type == ShapeType.roundedRectangle
            ? shape.cornerRadius
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
    final outlinePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(shape.rect, outlinePaint);
    canvas.restore();
  }

  void _drawMultiSelectionBoundingBox(Canvas canvas, Rect bounds) {
    final boxPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(bounds, boxPaint);

    final handleFill = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

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
      final handleRect = Rect.fromCenter(center: pt, width: 9, height: 9);
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
    }
  }

  void _drawDimensionBadge(
    Canvas canvas,
    Rect rect, {
    ShapeType? shapeType,
    double? cornerRadius,
  }) {
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
    } else if (shapeType == ShapeType.roundedRectangle &&
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
        fontSize: 11,
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
    final badgePos = Offset(left, bottom + 8);
    final bgRect = Rect.fromLTWH(
      badgePos.dx - 6,
      badgePos.dy - 3,
      textPainter.width + 12,
      textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()
        ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
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
  bool shouldRepaint(covariant VectorCanvasPainter oldDelegate) => true;
}
