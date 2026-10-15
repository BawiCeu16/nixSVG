import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:nixsvg/models/vector_shape.dart';

/// Calculation result for active smart alignment guidelines.
class SnapGuidelinesResult {
  final Offset? guidelineX;
  final Offset? guidelineY;
  final Offset snapDelta;

  const SnapGuidelinesResult({
    this.guidelineX,
    this.guidelineY,
    this.snapDelta = Offset.zero,
  });
}

/// Canvas geometric math and transformation calculations.
class CanvasGeometry {
  const CanvasGeometry._();

  /// Snaps a line to the nearest 45-degree angle increment.
  static Offset snapLinePoint(Offset start, Offset current) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return current;
    final angle = math.atan2(dy, dx);
    final snapAngle = (angle / (math.pi / 4)).round() * (math.pi / 4);
    return start +
        Offset(distance * math.cos(snapAngle), distance * math.sin(snapAngle));
  }

  /// Calculates a resized [Rect] based on the active handle, start offset, and current pointer offset.
  /// Fully supports Figma-style proportional resizing (holding Shift) and
  /// symmetrical center resizing (holding Alt/Option).
  static Rect resizeRect(
    Rect initial,
    Offset start,
    Offset current,
    ResizeHandle handle, {
    bool isLine = false,
  }) {
    final isShiftPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftRight,
        );
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;

    double dx = current.dx - start.dx;
    double dy = current.dy - start.dy;
    const double minSize = 6.0;

    if (isLine) {
      Offset startPoint = initial.topLeft;
      Offset endPoint = initial.bottomRight;

      switch (handle) {
        case ResizeHandle.topLeft:
          final rawStart = Offset(initial.left + dx, initial.top + dy);
          final anchor = endPoint;
          startPoint = isShiftPressed
              ? snapLinePoint(anchor, rawStart)
              : rawStart;
          break;
        case ResizeHandle.bottomRight:
          final rawEnd = Offset(initial.right + dx, initial.bottom + dy);
          final anchor = startPoint;
          endPoint = isShiftPressed ? snapLinePoint(anchor, rawEnd) : rawEnd;
          break;
        case ResizeHandle.topRight:
          final rawPoint = Offset(initial.right + dx, initial.top + dy);
          final anchor = initial.bottomLeft;
          final snapped = isShiftPressed
              ? snapLinePoint(anchor, rawPoint)
              : rawPoint;
          endPoint = Offset(snapped.dx, endPoint.dy);
          startPoint = Offset(startPoint.dx, snapped.dy);
          break;
        case ResizeHandle.bottomLeft:
          final rawPoint = Offset(initial.left + dx, initial.top + dy);
          final anchor = initial.topRight;
          final snapped = isShiftPressed
              ? snapLinePoint(anchor, rawPoint)
              : rawPoint;
          startPoint = Offset(snapped.dx, startPoint.dy);
          endPoint = Offset(endPoint.dx, snapped.dy);
          break;
        default:
          break;
      }
      return Rect.fromLTRB(
        startPoint.dx,
        startPoint.dy,
        endPoint.dx,
        endPoint.dy,
      );
    }

    // For corner handles with Shift pressed: preserve aspect ratio
    final bool isCornerHandle =
        handle == ResizeHandle.topLeft ||
        handle == ResizeHandle.topRight ||
        handle == ResizeHandle.bottomLeft ||
        handle == ResizeHandle.bottomRight;

    if (isCornerHandle &&
        isShiftPressed &&
        initial.height > 0 &&
        initial.width > 0) {
      final double aspect = initial.width / initial.height;
      final double rawW =
          initial.width +
          (handle == ResizeHandle.topLeft || handle == ResizeHandle.bottomLeft
              ? -dx
              : dx);
      final double rawH =
          initial.height +
          (handle == ResizeHandle.topLeft || handle == ResizeHandle.topRight
              ? -dy
              : dy);
      final double dominantDelta = (rawW.abs() > rawH.abs() * aspect)
          ? (rawW - initial.width)
          : (rawH - initial.height) * aspect;

      if (handle == ResizeHandle.bottomRight) {
        dx = dominantDelta;
        dy = dominantDelta / aspect;
      } else if (handle == ResizeHandle.topLeft) {
        dx = -dominantDelta;
        dy = -dominantDelta / aspect;
      } else if (handle == ResizeHandle.topRight) {
        dx = dominantDelta;
        dy = -dominantDelta / aspect;
      } else if (handle == ResizeHandle.bottomLeft) {
        dx = -dominantDelta;
        dy = dominantDelta / aspect;
      }
    }

    double left = initial.left;
    double top = initial.top;
    double right = initial.right;
    double bottom = initial.bottom;

    if (isAltPressed) {
      // Resize symmetrically around center
      switch (handle) {
        case ResizeHandle.topLeft:
          left = initial.left + dx;
          right = initial.right - dx;
          top = initial.top + dy;
          bottom = initial.bottom - dy;
          break;
        case ResizeHandle.topRight:
          right = initial.right + dx;
          left = initial.left - dx;
          top = initial.top + dy;
          bottom = initial.bottom - dy;
          break;
        case ResizeHandle.bottomLeft:
          left = initial.left + dx;
          right = initial.right - dx;
          bottom = initial.bottom + dy;
          top = initial.top - dy;
          break;
        case ResizeHandle.bottomRight:
          right = initial.right + dx;
          left = initial.left - dx;
          bottom = initial.bottom + dy;
          top = initial.top - dy;
          break;
        case ResizeHandle.topCenter:
          top = initial.top + dy;
          bottom = initial.bottom - dy;
          break;
        case ResizeHandle.bottomCenter:
          bottom = initial.bottom + dy;
          top = initial.top - dy;
          break;
        case ResizeHandle.centerLeft:
          left = initial.left + dx;
          right = initial.right - dx;
          break;
        case ResizeHandle.centerRight:
          right = initial.right + dx;
          left = initial.left - dx;
          break;
        case ResizeHandle.rotation:
        case ResizeHandle.none:
          break;
      }
    } else {
      switch (handle) {
        case ResizeHandle.topLeft:
          left = math.min(initial.left + dx, right - minSize);
          top = math.min(initial.top + dy, bottom - minSize);
          break;
        case ResizeHandle.topRight:
          right = math.max(initial.right + dx, left + minSize);
          top = math.min(initial.top + dy, bottom - minSize);
          break;
        case ResizeHandle.bottomLeft:
          left = math.min(initial.left + dx, right - minSize);
          bottom = math.max(initial.bottom + dy, top + minSize);
          break;
        case ResizeHandle.bottomRight:
          right = math.max(initial.right + dx, left + minSize);
          bottom = math.max(initial.bottom + dy, top + minSize);
          break;
        case ResizeHandle.topCenter:
          top = math.min(initial.top + dy, bottom - minSize);
          break;
        case ResizeHandle.bottomCenter:
          bottom = math.max(initial.bottom + dy, top + minSize);
          break;
        case ResizeHandle.centerLeft:
          left = math.min(initial.left + dx, right - minSize);
          break;
        case ResizeHandle.centerRight:
          right = math.max(initial.right + dx, left + minSize);
          break;
        case ResizeHandle.rotation:
        case ResizeHandle.none:
          break;
      }
    }

    if (right - left < minSize) right = left + minSize;
    if (bottom - top < minSize) bottom = top + minSize;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Calculates dynamic smart snapping guidelines relative to other shapes.
  static SnapGuidelinesResult calculateSnapGuidelines({
    required List<VectorShape> shapes,
    required Set<String> selectedShapeIds,
    double snapThreshold = 6.0,
  }) {
    if (selectedShapeIds.isEmpty) {
      return const SnapGuidelinesResult();
    }
    final selectedShapes = shapes
        .where((s) => selectedShapeIds.contains(s.id))
        .toList();
    if (selectedShapes.isEmpty) return const SnapGuidelinesResult();

    Rect targetBounds = selectedShapes.first.rect;
    for (final s in selectedShapes.skip(1)) {
      targetBounds = targetBounds.expandToInclude(s.rect);
    }

    Offset? guideX;
    Offset? guideY;
    double snapDx = 0.0;
    double snapDy = 0.0;

    final targetXPositions = [
      targetBounds.left,
      targetBounds.center.dx,
      targetBounds.right,
    ];
    final targetYPositions = [
      targetBounds.top,
      targetBounds.center.dy,
      targetBounds.bottom,
    ];

    for (final s in shapes) {
      if (selectedShapeIds.contains(s.id) || !s.isVisible) continue;
      final otherXPositions = [s.rect.left, s.rect.center.dx, s.rect.right];
      final otherYPositions = [s.rect.top, s.rect.center.dy, s.rect.bottom];

      if (guideX == null) {
        for (final tx in targetXPositions) {
          for (final ox in otherXPositions) {
            if ((tx - ox).abs() <= snapThreshold) {
              guideX = Offset(ox, 0);
              snapDx = ox - tx;
              break;
            }
          }
          if (guideX != null) break;
        }
      }

      if (guideY == null) {
        for (final ty in targetYPositions) {
          for (final oy in otherYPositions) {
            if ((ty - oy).abs() <= snapThreshold) {
              guideY = Offset(0, oy);
              snapDy = oy - ty;
              break;
            }
          }
          if (guideY != null) break;
        }
      }

      if (guideX != null && guideY != null) break;
    }

    return SnapGuidelinesResult(
      guidelineX: guideX,
      guidelineY: guideY,
      snapDelta: Offset(snapDx, snapDy),
    );
  }

  /// Returns the axis-aligned bounding box of a shape in canvas space,
  /// accounting for stroke width and rotation.
  static Rect getShapeBoundingBox(VectorShape shape) {
    final rawRect = Rect.fromLTRB(
      math.min(shape.rect.left, shape.rect.right),
      math.min(shape.rect.top, shape.rect.bottom),
      math.max(shape.rect.left, shape.rect.right),
      math.max(shape.rect.top, shape.rect.bottom),
    );

    // Padding for stroke width or zero-dimension lines
    final strokePadding = shape.type == ShapeType.line
        ? math.max(3.0, shape.strokeWidth / 2)
        : (shape.isStroked ? shape.strokeWidth / 2 : 0.0);
    final paddedRect = rawRect.inflate(strokePadding);

    if (shape.rotation == 0.0) {
      return paddedRect;
    }

    final center = shape.rect.center;
    final rad = shape.rotation * math.pi / 180.0;
    final cosVal = math.cos(rad);
    final sinVal = math.sin(rad);

    final corners = [
      paddedRect.topLeft,
      paddedRect.topRight,
      paddedRect.bottomRight,
      paddedRect.bottomLeft,
    ];

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final corner in corners) {
      final dx = corner.dx - center.dx;
      final dy = corner.dy - center.dy;
      final rx = center.dx + dx * cosVal - dy * sinVal;
      final ry = center.dy + dx * sinVal + dy * cosVal;
      if (rx < minX) minX = rx;
      if (rx > maxX) maxX = rx;
      if (ry < minY) minY = ry;
      if (ry > maxY) maxY = ry;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calculates which shape IDs fall inside a marquee selection bounding rectangle.
  static Set<String> calculateMarqueeSelection({
    required Rect marqueeRect,
    required List<VectorShape> shapes,
  }) {
    final normalizedMarquee = Rect.fromLTRB(
      math.min(marqueeRect.left, marqueeRect.right),
      math.min(marqueeRect.top, marqueeRect.bottom),
      math.max(marqueeRect.left, marqueeRect.right),
      math.max(marqueeRect.top, marqueeRect.bottom),
    );

    if (normalizedMarquee.width == 0.0 || normalizedMarquee.height == 0.0) {
      return const <String>{};
    }

    final result = <String>{};
    for (final shape in shapes) {
      if (shape.isVisible && !shape.isLocked) {
        final shapeBounds = getShapeBoundingBox(shape);
        if (normalizedMarquee.overlaps(shapeBounds)) {
          result.add(shape.id);
        }
      }
    }
    return result;
  }

  /// Aligns the rects of the selected shapes according to an alignment command.
  /// When multiple shapes are selected, aligns to their collective bounding box.
  /// When a single shape is selected, aligns relative to standard design artboard canvas.
  static void alignShapes({
    required List<VectorShape> shapes,
    required Set<String> selectedIds,
    required String align,
    Rect canvasFrame = const Rect.fromLTWH(0, 0, 1920, 1080),
  }) {
    if (selectedIds.isEmpty) return;
    final selectedShapes = shapes
        .where((s) => selectedIds.contains(s.id))
        .toList();
    if (selectedShapes.isEmpty) return;

    Rect bounds;
    if (selectedShapes.length == 1) {
      bounds = canvasFrame;
    } else {
      bounds = selectedShapes.first.rect;
      for (final s in selectedShapes.skip(1)) {
        bounds = bounds.expandToInclude(s.rect);
      }
    }

    for (final shape in selectedShapes) {
      double left = shape.rect.left;
      double top = shape.rect.top;

      switch (align) {
        case 'left':
          left = bounds.left;
          break;
        case 'center':
          left = bounds.center.dx - shape.rect.width / 2;
          break;
        case 'right':
          left = bounds.right - shape.rect.width;
          break;
        case 'top':
          top = bounds.top;
          break;
        case 'middle':
          top = bounds.center.dy - shape.rect.height / 2;
          break;
        case 'bottom':
          top = bounds.bottom - shape.rect.height;
          break;
      }
      shape.rect = Rect.fromLTWH(
        left,
        top,
        shape.rect.width,
        shape.rect.height,
      );
    }
  }

  /// Calculates the [Rect] for drawing a shape on the canvas:
  /// - If [isShiftPressed] is true, shapes constrain to a 1:1 square/circle bounding box,
  ///   or lines snap to 45° angle increments.
  /// - If [isAltPressed] is true, shapes expand symmetrically from [start] as the center point.
  static Rect calculateDrawRect({
    required Offset start,
    required Offset current,
    required ShapeType shapeType,
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (shapeType == ShapeType.line) {
      final endPos = isShiftPressed ? snapLinePoint(start, current) : current;
      if (isAltPressed) {
        // Expand symmetrically around start point
        final delta = endPos - start;
        return Rect.fromPoints(start - delta, start + delta);
      } else {
        return Rect.fromPoints(start, endPos);
      }
    }

    if (shapeType == ShapeType.text) {
      if (isAltPressed) {
        final halfWidth = (current.dx - start.dx).abs();
        final halfHeight = (current.dy - start.dy).abs();
        return Rect.fromCenter(
          center: start,
          width: math.max(halfWidth * 2, 2.0),
          height: math.max(halfHeight * 2, 2.0),
        );
      }
      return Rect.fromPoints(start, current);
    }

    // Shapes: rectangle, roundedRectangle, ellipse, star
    double rawWidth = (current.dx - start.dx).abs();
    double rawHeight = (current.dy - start.dy).abs();

    if (isShiftPressed) {
      final maxSide = math.max(rawWidth, rawHeight);
      rawWidth = maxSide;
      rawHeight = maxSide;
    }

    if (isAltPressed) {
      // Shape centered at start point
      return Rect.fromCenter(
        center: start,
        width: rawWidth * 2,
        height: rawHeight * 2,
      );
    } else {
      // Shape anchored at start corner
      final signX = current.dx >= start.dx ? 1.0 : -1.0;
      final signY = current.dy >= start.dy ? 1.0 : -1.0;
      final endPoint = Offset(
        start.dx + signX * rawWidth,
        start.dy + signY * rawHeight,
      );
      return Rect.fromPoints(start, endPoint);
    }
  }

  /// Converts a [Path] into a dashed or dotted path given [dashLength] and [dashGap].
  static Path dashPath(
    Path source, {
    required double dashLength,
    required double dashGap,
  }) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : dashGap;
        if (distance + length > metric.length) {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, metric.length),
              Offset.zero,
            );
          }
          break;
        }
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }
}
