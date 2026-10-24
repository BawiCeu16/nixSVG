import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_m3shapes_extended/flutter_m3shapes_extended.dart';
import 'package:nixsvg/calculations/svg_path_parser.dart';
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
          if (isAltPressed) {
            final center = Offset(
              (initial.left + initial.right) / 2,
              (initial.top + initial.bottom) / 2,
            );
            final snapped = isShiftPressed
                ? snapLinePoint(center, rawStart)
                : rawStart;
            final halfDelta = snapped - center;
            startPoint = center + halfDelta;
            endPoint = center - halfDelta;
          } else {
            final anchor = endPoint;
            startPoint = isShiftPressed
                ? snapLinePoint(anchor, rawStart)
                : rawStart;
          }
          break;
        case ResizeHandle.bottomRight:
          final rawEnd = Offset(initial.right + dx, initial.bottom + dy);
          if (isAltPressed) {
            final center = Offset(
              (initial.left + initial.right) / 2,
              (initial.top + initial.bottom) / 2,
            );
            final snapped = isShiftPressed
                ? snapLinePoint(center, rawEnd)
                : rawEnd;
            final halfDelta = snapped - center;
            endPoint = center + halfDelta;
            startPoint = center - halfDelta;
          } else {
            final anchor = startPoint;
            endPoint = isShiftPressed ? snapLinePoint(anchor, rawEnd) : rawEnd;
          }
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
        case ResizeHandle.radiusTopLeft:
        case ResizeHandle.radiusTopRight:
        case ResizeHandle.radiusBottomLeft:
        case ResizeHandle.radiusBottomRight:
        case ResizeHandle.ratio:
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
        case ResizeHandle.radiusTopLeft:
        case ResizeHandle.radiusTopRight:
        case ResizeHandle.radiusBottomLeft:
        case ResizeHandle.radiusBottomRight:
        case ResizeHandle.ratio:
        case ResizeHandle.none:
          break;
      }
    }

    if (right - left < minSize) right = left + minSize;
    if (bottom - top < minSize) bottom = top + minSize;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Returns the corresponding [MouseCursor] for an active or hovered [ResizeHandle],
  /// adjusting angle dynamically based on [rotation].
  static MouseCursor getHandleCursor(
    ResizeHandle handle, [
    double rotation = 0.0,
  ]) {
    if (handle == ResizeHandle.none) return SystemMouseCursors.basic;
    // Rotation handle & corner rotation zones: curved rotation cursor
    if (handle == ResizeHandle.rotation) return SystemMouseCursors.alias;
    if (handle.isRadius || handle.isRatio) return SystemMouseCursors.precise;

    double baseAngle = 0.0;
    switch (handle) {
      case ResizeHandle.centerRight:
        baseAngle = 0.0;
        break;
      case ResizeHandle.bottomRight:
        baseAngle = 45.0;
        break;
      case ResizeHandle.bottomCenter:
        baseAngle = 90.0;
        break;
      case ResizeHandle.bottomLeft:
        baseAngle = 135.0;
        break;
      case ResizeHandle.centerLeft:
        baseAngle = 180.0;
        break;
      case ResizeHandle.topLeft:
        baseAngle = 225.0;
        break;
      case ResizeHandle.topCenter:
        baseAngle = 270.0;
        break;
      case ResizeHandle.topRight:
        baseAngle = 315.0;
        break;
      default:
        return SystemMouseCursors.basic;
    }

    final effectiveAngle = (baseAngle + rotation) % 180.0;
    final normalized = effectiveAngle < 0
        ? effectiveAngle + 180.0
        : effectiveAngle;

    if (normalized >= 22.5 && normalized < 67.5) {
      return SystemMouseCursors.resizeUpLeftDownRight;
    } else if (normalized >= 67.5 && normalized < 112.5) {
      return SystemMouseCursors.resizeUpDown;
    } else if (normalized >= 112.5 && normalized < 157.5) {
      return SystemMouseCursors.resizeUpRightDownLeft;
    } else {
      return SystemMouseCursors.resizeLeftRight;
    }
  }

  /// Calculates dynamic smart snapping guidelines relative to other shapes.
  /// Uses [initialShapeRects] and [proposedDelta] to prevent oscillating shaking
  /// while moving shapes.
  static SnapGuidelinesResult calculateSnapGuidelines({
    required List<VectorShape> shapes,
    required Set<String> selectedShapeIds,
    Map<String, Rect>? initialShapeRects,
    Offset? proposedDelta,
    double snapThreshold = 6.0,
  }) {
    if (selectedShapeIds.isEmpty) {
      return const SnapGuidelinesResult();
    }

    Rect targetBounds;
    if (initialShapeRects != null && proposedDelta != null) {
      Rect? initialCombined;
      for (final id in selectedShapeIds) {
        final r = initialShapeRects[id];
        if (r != null) {
          initialCombined = initialCombined == null
              ? r
              : initialCombined.expandToInclude(r);
        }
      }
      if (initialCombined == null) return const SnapGuidelinesResult();
      targetBounds = initialCombined.shift(proposedDelta);
    } else {
      final selectedShapes = shapes
          .where((s) => selectedShapeIds.contains(s.id))
          .toList();
      if (selectedShapes.isEmpty) return const SnapGuidelinesResult();

      targetBounds = selectedShapes.first.rect;
      for (int i = 1; i < selectedShapes.length; i++) {
        targetBounds = targetBounds.expandToInclude(selectedShapes[i].rect);
      }
    }

    Offset? guideX;
    Offset? guideY;
    double snapDx = 0.0;
    double snapDy = 0.0;
    double minDiffX = snapThreshold + 0.001;
    double minDiffY = snapThreshold + 0.001;

    final tLeft = targetBounds.left;
    final tCenterX = targetBounds.center.dx;
    final tRight = targetBounds.right;

    final tTop = targetBounds.top;
    final tCenterY = targetBounds.center.dy;
    final tBottom = targetBounds.bottom;

    for (final s in shapes) {
      if (selectedShapeIds.contains(s.id) || !s.isVisible) continue;
      final oLeft = s.rect.left;
      final oCenterX = s.rect.center.dx;
      final oRight = s.rect.right;

      final oTop = s.rect.top;
      final oCenterY = s.rect.center.dy;
      final oBottom = s.rect.bottom;

      // X Snap alignments (find closest alignment within threshold)
      for (final tx in [tLeft, tCenterX, tRight]) {
        for (final ox in [oLeft, oCenterX, oRight]) {
          final diff = (tx - ox).abs();
          if (diff <= snapThreshold && diff < minDiffX) {
            minDiffX = diff;
            snapDx = ox - tx;
            guideX = Offset(ox, 0);
          }
        }
      }

      // Y Snap alignments (find closest alignment within threshold)
      for (final ty in [tTop, tCenterY, tBottom]) {
        for (final oy in [oTop, oCenterY, oBottom]) {
          final diff = (ty - oy).abs();
          if (diff <= snapThreshold && diff < minDiffY) {
            minDiffY = diff;
            snapDy = oy - ty;
            guideY = Offset(0, oy);
          }
        }
      }
    }

    return SnapGuidelinesResult(
      guidelineX: guideX,
      guidelineY: guideY,
      snapDelta: Offset(snapDx, snapDy),
    );
  }

  /// Returns the axis-aligned bounding box of a shape in canvas space,
  /// accounting for stroke width and rotation with cached memoization.
  static Rect getShapeBoundingBox(VectorShape shape) {
    return shape.getBoundingBox();
  }

  /// Calculates which shape IDs fall inside a marquee selection bounding rectangle.
  static Set<String> calculateMarqueeSelection({
    required Rect marqueeRect,
    required List<VectorShape> shapes,
  }) {
    final mLeft = math.min(marqueeRect.left, marqueeRect.right);
    final mTop = math.min(marqueeRect.top, marqueeRect.bottom);
    final mRight = math.max(marqueeRect.left, marqueeRect.right);
    final mBottom = math.max(marqueeRect.top, marqueeRect.bottom);

    if (mRight <= mLeft || mBottom <= mTop) {
      return const <String>{};
    }

    final result = <String>{};
    for (int i = 0; i < shapes.length; i++) {
      final shape = shapes[i];
      if (shape.isVisible && !shape.isLocked) {
        final b = shape.getBoundingBox();
        if (mRight > b.left &&
            mLeft < b.right &&
            mBottom > b.top &&
            mTop < b.bottom) {
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
    Rect canvasFrame = const Rect.fromLTWH(0, 0, 3200, 2400),
    bool alignToCanvas = false,
  }) {
    if (selectedIds.isEmpty) return;
    final selectedShapes = shapes
        .where((s) => selectedIds.contains(s.id))
        .toList();
    if (selectedShapes.isEmpty) return;

    if (selectedShapes.length == 1) {
      // Single shape aligns relative to the Canvas / Artboard Frame like Figma
      final shape = selectedShapes.first;
      double left = shape.rect.left;
      double top = shape.rect.top;

      switch (align) {
        case 'left':
          left = canvasFrame.left;
          break;
        case 'center':
          left = canvasFrame.center.dx - shape.rect.width / 2;
          break;
        case 'right':
          left = canvasFrame.right - shape.rect.width;
          break;
        case 'top':
          top = canvasFrame.top;
          break;
        case 'middle':
          top = canvasFrame.center.dy - shape.rect.height / 2;
          break;
        case 'bottom':
          top = canvasFrame.bottom - shape.rect.height;
          break;
      }
      shape.rect = Rect.fromLTWH(
        left,
        top,
        shape.rect.width,
        shape.rect.height,
      );
      shape.invalidateCache();
    } else if (alignToCanvas) {
      // Multiple shapes aligned as a collective group to the canvas frame
      Rect groupBounds = selectedShapes.first.rect;
      for (final s in selectedShapes.skip(1)) {
        groupBounds = groupBounds.expandToInclude(s.rect);
      }
      double dx = 0.0;
      double dy = 0.0;
      switch (align) {
        case 'left':
          dx = canvasFrame.left - groupBounds.left;
          break;
        case 'center':
          dx = canvasFrame.center.dx - groupBounds.center.dx;
          break;
        case 'right':
          dx = canvasFrame.right - groupBounds.right;
          break;
        case 'top':
          dy = canvasFrame.top - groupBounds.top;
          break;
        case 'middle':
          dy = canvasFrame.center.dy - groupBounds.center.dy;
          break;
        case 'bottom':
          dy = canvasFrame.bottom - groupBounds.bottom;
          break;
      }
      for (final shape in selectedShapes) {
        shape.rect = shape.rect.shift(Offset(dx, dy));
        shape.invalidateCache();
      }
    } else {
      // Multiple shapes aligned relative to their collective union bounding box
      Rect bounds = selectedShapes.first.rect;
      for (final s in selectedShapes.skip(1)) {
        bounds = bounds.expandToInclude(s.rect);
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
        shape.invalidateCache();
      }
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
        return Rect.fromLTRB(
          start.dx - delta.dx,
          start.dy - delta.dy,
          start.dx + delta.dx,
          start.dy + delta.dy,
        );
      } else {
        return Rect.fromLTRB(start.dx, start.dy, endPos.dx, endPos.dy);
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
    final effectiveDash = math.max(0.5, dashLength);
    final effectiveGap = math.max(0.5, dashGap);
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? effectiveDash : effectiveGap;
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

  /// Creates a mathematically smooth squircle / continuous corner-rounded rectangle [Path]
  /// using [RoundedPolygon.rectangle] with Material 3 Expressive and iOS/Figma-grade
  /// continuous curvature (G2 continuity).
  static Path createSquircleRectPath(
    Rect rect, {
    required double cornerRadius,
    required double cornerSmoothing,
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomRightRadius,
    double? bottomLeftRadius,
  }) {
    if (rect.width <= 0 || rect.height <= 0) return Path();
    final maxR = math.min(rect.width, rect.height) / 2.0;
    final smoothing = cornerSmoothing.clamp(0.0, 1.0);

    final bool hasIndependent = topLeftRadius != null ||
        topRightRadius != null ||
        bottomRightRadius != null ||
        bottomLeftRadius != null;

    final brR = (bottomRightRadius ?? cornerRadius).clamp(0.0, maxR);
    final blR = (bottomLeftRadius ?? cornerRadius).clamp(0.0, maxR);
    final tlR = (topLeftRadius ?? cornerRadius).clamp(0.0, maxR);
    final trR = (topRightRadius ?? cornerRadius).clamp(0.0, maxR);

    if (tlR <= 0 && trR <= 0 && brR <= 0 && blR <= 0) {
      return Path()..addRect(rect);
    }

    if (smoothing <= 0.0) {
      final path = Path();
      if (hasIndependent) {
        path.addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(tlR),
            topRight: Radius.circular(trR),
            bottomRight: Radius.circular(brR),
            bottomLeft: Radius.circular(blR),
          ),
        );
      } else {
        path.addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(brR)),
        );
      }
      return path;
    }

    // Vertex order for RoundedPolygon.rectangle is:
    // 0: bottomRight (right, bottom)
    // 1: bottomLeft (left, bottom)
    // 2: topLeft (left, top)
    // 3: topRight (right, top)
    final poly = RoundedPolygon.rectangle(
      width: rect.width,
      height: rect.height,
      centerX: rect.center.dx,
      centerY: rect.center.dy,
      perVertexRounding: [
        CornerRounding(radius: brR, smoothing: smoothing),
        CornerRounding(radius: blR, smoothing: smoothing),
        CornerRounding(radius: tlR, smoothing: smoothing),
        CornerRounding(radius: trR, smoothing: smoothing),
      ],
    );

    return poly.toPath();
  }

  /// Generates SVG cubic Bézier path commands for a smooth squircle rectangle.
  static String generateSquircleSvgPathData(
    Rect rect, {
    required double cornerRadius,
    required double cornerSmoothing,
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomRightRadius,
    double? bottomLeftRadius,
  }) {
    if (rect.width <= 0 || rect.height <= 0) return '';
    final maxR = math.min(rect.width, rect.height) / 2.0;
    final smoothing = cornerSmoothing.clamp(0.0, 1.0);

    final brR = (bottomRightRadius ?? cornerRadius).clamp(0.0, maxR);
    final blR = (bottomLeftRadius ?? cornerRadius).clamp(0.0, maxR);
    final tlR = (topLeftRadius ?? cornerRadius).clamp(0.0, maxR);
    final trR = (topRightRadius ?? cornerRadius).clamp(0.0, maxR);

    final poly = RoundedPolygon.rectangle(
      width: rect.width,
      height: rect.height,
      centerX: rect.center.dx,
      centerY: rect.center.dy,
      perVertexRounding: [
        CornerRounding(radius: brR, smoothing: smoothing),
        CornerRounding(radius: blR, smoothing: smoothing),
        CornerRounding(radius: tlR, smoothing: smoothing),
        CornerRounding(radius: trR, smoothing: smoothing),
      ],
    );

    final sb = StringBuffer();
    for (int i = 0; i < poly.cubics.length; i++) {
      final c = poly.cubics[i];
      if (i == 0) {
        sb.write('M ${c.anchor0X.toStringAsFixed(2)} ${c.anchor0Y.toStringAsFixed(2)} ');
      }
      sb.write('C ${c.control0X.toStringAsFixed(2)} ${c.control0Y.toStringAsFixed(2)}, '
          '${c.control1X.toStringAsFixed(2)} ${c.control1Y.toStringAsFixed(2)}, '
          '${c.anchor1X.toStringAsFixed(2)} ${c.anchor1Y.toStringAsFixed(2)} ');
    }
    sb.write('Z');
    return sb.toString();
  }

  /// Generates a geometric star [Path] fitted within [rect], supporting custom [points],
  /// [innerRadiusRatio], and smooth [cornerRadius] corner rounding fillets.
  static Path createStarPath(
    Rect rect, {
    int points = 5,
    double innerRadiusRatio = 0.4,
    double cornerRadius = 0.0,
  }) {
    final numPoints = math.max(3, points);
    final ratio = innerRadiusRatio.clamp(0.05, 0.95);
    final center = rect.center;
    final outerRadius = math.min(rect.width, rect.height) / 2;
    final innerRadius = outerRadius * ratio;
    final totalVertices = numPoints * 2;
    final angleStep = math.pi / numPoints;

    final vertices = <Offset>[];
    for (int i = 0; i < totalVertices; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * angleStep - math.pi / 2;
      vertices.add(
        Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ),
      );
    }

    final path = Path();
    if (vertices.isEmpty) return path;

    if (cornerRadius <= 0.0) {
      path.moveTo(vertices[0].dx, vertices[0].dy);
      for (int i = 1; i < totalVertices; i++) {
        path.lineTo(vertices[i].dx, vertices[i].dy);
      }
      path.close();
      return path;
    }

    // Compute edge lengths
    final edgeLengths = <double>[];
    for (int i = 0; i < totalVertices; i++) {
      final nextIdx = (i + 1) % totalVertices;
      edgeLengths.add((vertices[nextIdx] - vertices[i]).distance);
    }

    // Compute tangent points and conic fillet weights for each vertex
    final tangentIn = <Offset>[];
    final tangentOut = <Offset>[];
    final filletWeights = <double>[];

    for (int i = 0; i < totalVertices; i++) {
      final prevIdx = (i - 1 + totalVertices) % totalVertices;
      final pi = vertices[i];
      final pPrev = vertices[prevIdx];
      final pNext = vertices[(i + 1) % totalVertices];

      final vIn = pPrev - pi;
      final vOut = pNext - pi;
      final lenIn = edgeLengths[prevIdx];
      final lenOut = edgeLengths[i];

      if (lenIn == 0 || lenOut == 0) {
        tangentIn.add(pi);
        tangentOut.add(pi);
        filletWeights.add(1.0);
        continue;
      }

      final uIn = Offset(vIn.dx / lenIn, vIn.dy / lenIn);
      final uOut = Offset(vOut.dx / lenOut, vOut.dy / lenOut);

      final dot = (uIn.dx * uOut.dx + uIn.dy * uOut.dy).clamp(-1.0, 1.0);
      final angle = math.acos(dot);
      final halfAngle = angle / 2;
      final tanHalf = math.tan(halfAngle);

      final maxFilletDist = math.min(lenIn, lenOut) * 0.49;
      double d = 0.0;
      if (tanHalf > 1e-4) {
        d = (cornerRadius / tanHalf).clamp(0.0, maxFilletDist);
      }

      tangentIn.add(pi + Offset(uIn.dx * d, uIn.dy * d));
      tangentOut.add(pi + Offset(uOut.dx * d, uOut.dy * d));
      filletWeights.add(math.cos(halfAngle));
    }

    path.moveTo(tangentOut[0].dx, tangentOut[0].dy);
    for (int i = 1; i <= totalVertices; i++) {
      final idx = i % totalVertices;
      path.lineTo(tangentIn[idx].dx, tangentIn[idx].dy);

      final pi = vertices[idx];
      path.conicTo(
        pi.dx,
        pi.dy,
        tangentOut[idx].dx,
        tangentOut[idx].dy,
        filletWeights[idx],
      );
    }
    path.close();
    return path;
  }

  /// Generates SVG path data commands for a star with optional rounded corner fillets.
  static String generateStarSvgPathData(
    Rect rect, {
    int points = 5,
    double innerRadiusRatio = 0.4,
    double cornerRadius = 0.0,
  }) {
    final numPoints = math.max(3, points);
    final ratio = innerRadiusRatio.clamp(0.05, 0.95);
    final center = rect.center;
    final outerRadius = math.min(rect.width, rect.height) / 2;
    final innerRadius = outerRadius * ratio;
    final totalVertices = numPoints * 2;
    final angleStep = math.pi / numPoints;

    final vertices = <Offset>[];
    for (int i = 0; i < totalVertices; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * angleStep - math.pi / 2;
      vertices.add(
        Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ),
      );
    }

    if (cornerRadius <= 0.0) {
      final sb = StringBuffer();
      sb.write(
        'M ${vertices[0].dx.toStringAsFixed(1)} ${vertices[0].dy.toStringAsFixed(1)}',
      );
      for (int i = 1; i < totalVertices; i++) {
        sb.write(
          ' L ${vertices[i].dx.toStringAsFixed(1)} ${vertices[i].dy.toStringAsFixed(1)}',
        );
      }
      sb.write(' Z');
      return sb.toString();
    }

    final edgeLengths = <double>[];
    for (int i = 0; i < totalVertices; i++) {
      final nextIdx = (i + 1) % totalVertices;
      edgeLengths.add((vertices[nextIdx] - vertices[i]).distance);
    }

    final tangentIn = <Offset>[];
    final tangentOut = <Offset>[];

    for (int i = 0; i < totalVertices; i++) {
      final prevIdx = (i - 1 + totalVertices) % totalVertices;
      final pi = vertices[i];
      final pPrev = vertices[prevIdx];
      final pNext = vertices[(i + 1) % totalVertices];

      final vIn = pPrev - pi;
      final vOut = pNext - pi;
      final lenIn = edgeLengths[prevIdx];
      final lenOut = edgeLengths[i];

      if (lenIn == 0 || lenOut == 0) {
        tangentIn.add(pi);
        tangentOut.add(pi);
        continue;
      }

      final uIn = Offset(vIn.dx / lenIn, vIn.dy / lenIn);
      final uOut = Offset(vOut.dx / lenOut, vOut.dy / lenOut);
      final dot = (uIn.dx * uOut.dx + uIn.dy * uOut.dy).clamp(-1.0, 1.0);
      final halfAngle = math.acos(dot) / 2;
      final tanHalf = math.tan(halfAngle);
      final maxFilletDist = math.min(lenIn, lenOut) * 0.49;
      double d = 0.0;
      if (tanHalf > 1e-4) {
        d = (cornerRadius / tanHalf).clamp(0.0, maxFilletDist);
      }

      tangentIn.add(pi + Offset(uIn.dx * d, uIn.dy * d));
      tangentOut.add(pi + Offset(uOut.dx * d, uOut.dy * d));
    }

    final sb = StringBuffer();
    sb.write(
      'M ${tangentOut[0].dx.toStringAsFixed(1)} ${tangentOut[0].dy.toStringAsFixed(1)}',
    );
    for (int i = 1; i <= totalVertices; i++) {
      final idx = i % totalVertices;
      final pi = vertices[idx];
      final tIn = tangentIn[idx];
      final tOut = tangentOut[idx];
      sb.write(' L ${tIn.dx.toStringAsFixed(1)} ${tIn.dy.toStringAsFixed(1)}');
      sb.write(
        ' Q ${pi.dx.toStringAsFixed(1)} ${pi.dy.toStringAsFixed(1)} ${tOut.dx.toStringAsFixed(1)} ${tOut.dy.toStringAsFixed(1)}',
      );
    }
    sb.write(' Z');
    return sb.toString();
  }

  /// Generates SVG points list string for unrounded polygon stars.
  static String generateStarPointsSvg(
    Rect rect, {
    int points = 5,
    double innerRadiusRatio = 0.4,
  }) {
    final numPoints = math.max(3, points);
    final ratio = innerRadiusRatio.clamp(0.05, 0.95);
    final center = rect.center;
    final outerRadius = math.min(rect.width, rect.height) / 2;
    final innerRadius = outerRadius * ratio;
    final totalVertices = numPoints * 2;
    final angleStep = math.pi / numPoints;
    final pointsList = <String>[];

    for (int i = 0; i < totalVertices; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      pointsList.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    return pointsList.join(' ');
  }

  /// Generates a geometric regular polygon [Path] fitted within [rect], supporting custom [sides]
  /// and smooth [cornerRadius] corner rounding fillets.
  static Path createPolygonPath(
    Rect rect, {
    int sides = 5,
    double cornerRadius = 0.0,
  }) {
    final numSides = math.max(3, sides);
    final center = rect.center;
    final radiusX = rect.width / 2;
    final radiusY = rect.height / 2;
    final angleStep = (2 * math.pi) / numSides;

    final vertices = <Offset>[];
    for (int i = 0; i < numSides; i++) {
      final angle = i * angleStep - math.pi / 2;
      vertices.add(
        Offset(
          center.dx + radiusX * math.cos(angle),
          center.dy + radiusY * math.sin(angle),
        ),
      );
    }

    final path = Path();
    if (vertices.isEmpty) return path;

    if (cornerRadius <= 0.0) {
      path.moveTo(vertices[0].dx, vertices[0].dy);
      for (int i = 1; i < numSides; i++) {
        path.lineTo(vertices[i].dx, vertices[i].dy);
      }
      path.close();
      return path;
    }

    // Compute edge lengths
    final edgeLengths = <double>[];
    for (int i = 0; i < numSides; i++) {
      final nextIdx = (i + 1) % numSides;
      edgeLengths.add((vertices[nextIdx] - vertices[i]).distance);
    }

    // Compute tangent points and conic fillet weights for each vertex
    final tangentIn = <Offset>[];
    final tangentOut = <Offset>[];
    final filletWeights = <double>[];

    for (int i = 0; i < numSides; i++) {
      final prevIdx = (i - 1 + numSides) % numSides;
      final pi = vertices[i];
      final pPrev = vertices[prevIdx];
      final pNext = vertices[(i + 1) % numSides];

      final vIn = pPrev - pi;
      final vOut = pNext - pi;
      final lenIn = edgeLengths[prevIdx];
      final lenOut = edgeLengths[i];

      if (lenIn == 0 || lenOut == 0) {
        tangentIn.add(pi);
        tangentOut.add(pi);
        filletWeights.add(1.0);
        continue;
      }

      final uIn = Offset(vIn.dx / lenIn, vIn.dy / lenIn);
      final uOut = Offset(vOut.dx / lenOut, vOut.dy / lenOut);

      final dot = (uIn.dx * uOut.dx + uIn.dy * uOut.dy).clamp(-1.0, 1.0);
      final angle = math.acos(dot);
      final halfAngle = angle / 2;
      final tanHalf = math.tan(halfAngle);

      final maxFilletDist = math.min(lenIn, lenOut) * 0.49;
      double d = 0.0;
      if (tanHalf > 1e-4) {
        d = (cornerRadius / tanHalf).clamp(0.0, maxFilletDist);
      }

      tangentIn.add(pi + Offset(uIn.dx * d, uIn.dy * d));
      tangentOut.add(pi + Offset(uOut.dx * d, uOut.dy * d));
      filletWeights.add(math.cos(halfAngle));
    }

    path.moveTo(tangentOut[0].dx, tangentOut[0].dy);
    for (int i = 1; i <= numSides; i++) {
      final idx = i % numSides;
      path.lineTo(tangentIn[idx].dx, tangentIn[idx].dy);

      final pi = vertices[idx];
      path.conicTo(
        pi.dx,
        pi.dy,
        tangentOut[idx].dx,
        tangentOut[idx].dy,
        filletWeights[idx],
      );
    }
    path.close();
    return path;
  }

  /// Generates SVG points list string for unrounded regular polygons.
  static String generatePolygonPointsSvg(Rect rect, {int sides = 5}) {
    final numSides = math.max(3, sides);
    final center = rect.center;
    final radiusX = rect.width / 2;
    final radiusY = rect.height / 2;
    final angleStep = (2 * math.pi) / numSides;
    final pointsList = <String>[];

    for (int i = 0; i < numSides; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radiusX * math.cos(angle);
      final y = center.dy + radiusY * math.sin(angle);
      pointsList.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    return pointsList.join(' ');
  }

  /// Generates SVG path data commands for a polygon with optional rounded corner fillets.
  static String generatePolygonSvgPathData(
    Rect rect, {
    int sides = 5,
    double cornerRadius = 0.0,
  }) {
    final numSides = math.max(3, sides);
    final center = rect.center;
    final radiusX = rect.width / 2;
    final radiusY = rect.height / 2;
    final angleStep = (2 * math.pi) / numSides;

    final vertices = <Offset>[];
    for (int i = 0; i < numSides; i++) {
      final angle = i * angleStep - math.pi / 2;
      vertices.add(
        Offset(
          center.dx + radiusX * math.cos(angle),
          center.dy + radiusY * math.sin(angle),
        ),
      );
    }

    if (vertices.isEmpty) return '';

    if (cornerRadius <= 0.0) {
      final sb = StringBuffer(
        'M ${vertices[0].dx.toStringAsFixed(1)} ${vertices[0].dy.toStringAsFixed(1)}',
      );
      for (int i = 1; i < numSides; i++) {
        sb.write(
          ' L ${vertices[i].dx.toStringAsFixed(1)} ${vertices[i].dy.toStringAsFixed(1)}',
        );
      }
      sb.write(' Z');
      return sb.toString();
    }

    final edgeLengths = <double>[];
    for (int i = 0; i < numSides; i++) {
      final nextIdx = (i + 1) % numSides;
      edgeLengths.add((vertices[nextIdx] - vertices[i]).distance);
    }

    final tangentIn = <Offset>[];
    final tangentOut = <Offset>[];

    for (int i = 0; i < numSides; i++) {
      final prevIdx = (i - 1 + numSides) % numSides;
      final pi = vertices[i];
      final pPrev = vertices[prevIdx];
      final pNext = vertices[(i + 1) % numSides];

      final vIn = pPrev - pi;
      final vOut = pNext - pi;
      final lenIn = edgeLengths[prevIdx];
      final lenOut = edgeLengths[i];

      if (lenIn == 0 || lenOut == 0) {
        tangentIn.add(pi);
        tangentOut.add(pi);
        continue;
      }

      final uIn = Offset(vIn.dx / lenIn, vIn.dy / lenIn);
      final uOut = Offset(vOut.dx / lenOut, vOut.dy / lenOut);

      final dot = (uIn.dx * uOut.dx + uIn.dy * uOut.dy).clamp(-1.0, 1.0);
      final angle = math.acos(dot);
      final halfAngle = angle / 2;
      final tanHalf = math.tan(halfAngle);

      final maxFilletDist = math.min(lenIn, lenOut) * 0.49;
      double d = 0.0;
      if (tanHalf > 1e-4) {
        d = (cornerRadius / tanHalf).clamp(0.0, maxFilletDist);
      }

      tangentIn.add(pi + Offset(uIn.dx * d, uIn.dy * d));
      tangentOut.add(pi + Offset(uOut.dx * d, uOut.dy * d));
    }

    final sb = StringBuffer(
      'M ${tangentOut[0].dx.toStringAsFixed(1)} ${tangentOut[0].dy.toStringAsFixed(1)}',
    );
    for (int i = 1; i <= numSides; i++) {
      final idx = i % numSides;
      final tIn = tangentIn[idx];
      final pi = vertices[idx];
      final tOut = tangentOut[idx];

      sb.write(' L ${tIn.dx.toStringAsFixed(1)} ${tIn.dy.toStringAsFixed(1)}');
      sb.write(
        ' Q ${pi.dx.toStringAsFixed(1)} ${pi.dy.toStringAsFixed(1)} ${tOut.dx.toStringAsFixed(1)} ${tOut.dy.toStringAsFixed(1)}',
      );
    }
    sb.write(' Z');
    return sb.toString();
  }

  /// Distributes selected shapes evenly along [direction] ('horizontal' or 'vertical').
  /// Requires at least 3 shapes to compute intermediate spacing gaps.
  static void distributeShapes({
    required List<VectorShape> shapes,
    required Set<String> selectedIds,
    required String direction,
  }) {
    if (selectedIds.length < 3) return;
    final selected = shapes.where((s) => selectedIds.contains(s.id)).toList();
    if (selected.length < 3) return;

    if (direction == 'horizontal') {
      selected.sort((a, b) => a.rect.left.compareTo(b.rect.left));
      final first = selected.first;
      final last = selected.last;
      final totalSpan = last.rect.right - first.rect.left;
      double sumWidths = 0.0;
      for (final s in selected) {
        sumWidths += s.rect.width;
      }
      final remainingSpace = totalSpan - sumWidths;
      final gap = remainingSpace / (selected.length - 1);

      double currentX = first.rect.left + first.rect.width + gap;
      for (int i = 1; i < selected.length - 1; i++) {
        final s = selected[i];
        s.rect = Rect.fromLTWH(
          currentX,
          s.rect.top,
          s.rect.width,
          s.rect.height,
        );
        s.invalidateCache();
        currentX += s.rect.width + gap;
      }
    } else {
      selected.sort((a, b) => a.rect.top.compareTo(b.rect.top));
      final first = selected.first;
      final last = selected.last;
      final totalSpan = last.rect.bottom - first.rect.top;
      double sumHeights = 0.0;
      for (final s in selected) {
        sumHeights += s.rect.height;
      }
      final remainingSpace = totalSpan - sumHeights;
      final gap = remainingSpace / (selected.length - 1);

      double currentY = first.rect.top + first.rect.height + gap;
      for (int i = 1; i < selected.length - 1; i++) {
        final s = selected[i];
        s.rect = Rect.fromLTWH(
          s.rect.left,
          currentY,
          s.rect.width,
          s.rect.height,
        );
        s.invalidateCache();
        currentY += s.rect.height + gap;
      }
    }
  }

  /// Combines two or more shapes using a Boolean vector [operation].
  /// Returns a new unified [VectorShape] of type [ShapeType.path].
  static VectorShape? combineShapes({
    required List<VectorShape> shapes,
    required Set<String> selectedIds,
    required PathOperation operation,
    int shapeCounter = 1,
  }) {
    if (selectedIds.length < 2) return null;
    final selected = shapes.where((s) => selectedIds.contains(s.id)).toList();
    if (selected.length < 2) return null;

    Path combined = selected.first.getPath();
    for (int i = 1; i < selected.length; i++) {
      combined = Path.combine(operation, combined, selected[i].getPath());
    }

    final bounds = combined.getBounds();
    final svgData = SvgPathParser.pathToSvgData(combined);
    final topShape = selected.last;

    String opName = 'Union';
    if (operation == PathOperation.difference) opName = 'Subtract';
    if (operation == PathOperation.intersect) opName = 'Intersect';
    if (operation == PathOperation.xor) opName = 'Exclude';

    return VectorShape(
      id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
      name: '$opName $shapeCounter',
      type: ShapeType.path,
      pathData: svgData,
      customPath: combined,
      rect: bounds,
      fillColor: topShape.fillColor,
      isFilled: topShape.isFilled,
      fillOpacity: topShape.fillOpacity,
      fillType: topShape.fillType,
      fillGradient: topShape.fillGradient,
      strokeColor: topShape.strokeColor,
      isStroked: topShape.isStroked,
      strokeWidth: topShape.strokeWidth,
      strokeOpacity: topShape.strokeOpacity,
      strokeType: topShape.strokeType,
      strokeGradient: topShape.strokeGradient,
    );
  }

  /// Creates a smooth, continuous Bézier [Path] from a sequence of sampled or clicked [points].
  /// Uses midpoint quadratic Bézier curve interpolation for fluid, natural pen strokes.
  static Path createSmoothPathFromPoints(
    List<Offset> points, {
    bool isClosed = false,
  }) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(points[0].dx + 0.1, points[0].dy + 0.1);
      return path;
    }
    if (points.length == 2) {
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(points[1].dx, points[1].dy);
      if (isClosed) path.close();
      return path;
    }

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2.0, (p0.dy + p1.dy) / 2.0);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }

    path.lineTo(points.last.dx, points.last.dy);
    if (isClosed) {
      path.close();
    }
    return path;
  }

  /// Creates a polygonal [Path] connecting [points] directly with straight line segments.
  static Path createPolylinePathFromPoints(
    List<Offset> points, {
    bool isClosed = false,
  }) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (isClosed) {
      path.close();
    }
    return path;
  }

  /// Converts a sequence of [PathNode] anchor points into a Flutter [Path],
  /// creating straight lines where handles are absent and cubic Bézier curves where handles exist.
  static Path nodesToPath(List<PathNode> nodes, {bool isClosed = false}) {
    final path = Path();
    if (nodes.isEmpty) return path;

    path.moveTo(nodes[0].position.dx, nodes[0].position.dy);

    for (int i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      final cp1 = a.handleOut ?? a.position;
      final cp2 = b.handleIn ?? b.position;

      if (cp1 == a.position && cp2 == b.position) {
        path.lineTo(b.position.dx, b.position.dy);
      } else {
        path.cubicTo(
          cp1.dx,
          cp1.dy,
          cp2.dx,
          cp2.dy,
          b.position.dx,
          b.position.dy,
        );
      }
    }

    if (isClosed && nodes.length >= 2) {
      final a = nodes.last;
      final b = nodes.first;
      final cp1 = a.handleOut ?? a.position;
      final cp2 = b.handleIn ?? b.position;

      if (cp1 == a.position && cp2 == b.position) {
        path.close();
      } else {
        path.cubicTo(
          cp1.dx,
          cp1.dy,
          cp2.dx,
          cp2.dy,
          b.position.dx,
          b.position.dy,
        );
        path.close();
      }
    }

    return path;
  }

  /// Converts a sequence of [PathNode] anchor points into exact standards-compliant SVG path data.
  static String nodesToSvgData(List<PathNode> nodes, {bool isClosed = false}) {
    if (nodes.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.write(
      'M ${nodes[0].position.dx.toStringAsFixed(2)} ${nodes[0].position.dy.toStringAsFixed(2)}',
    );

    for (int i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      final cp1 = a.handleOut ?? a.position;
      final cp2 = b.handleIn ?? b.position;

      if (cp1 == a.position && cp2 == b.position) {
        buffer.write(
          ' L ${b.position.dx.toStringAsFixed(2)} ${b.position.dy.toStringAsFixed(2)}',
        );
      } else {
        buffer.write(
          ' C ${cp1.dx.toStringAsFixed(2)} ${cp1.dy.toStringAsFixed(2)} '
          '${cp2.dx.toStringAsFixed(2)} ${cp2.dy.toStringAsFixed(2)} '
          '${b.position.dx.toStringAsFixed(2)} ${b.position.dy.toStringAsFixed(2)}',
        );
      }
    }

    if (isClosed && nodes.length >= 2) {
      final a = nodes.last;
      final b = nodes.first;
      final cp1 = a.handleOut ?? a.position;
      final cp2 = b.handleIn ?? b.position;

      if (cp1 == a.position && cp2 == b.position) {
        buffer.write(' Z');
      } else {
        buffer.write(
          ' C ${cp1.dx.toStringAsFixed(2)} ${cp1.dy.toStringAsFixed(2)} '
          '${cp2.dx.toStringAsFixed(2)} ${cp2.dy.toStringAsFixed(2)} '
          '${b.position.dx.toStringAsFixed(2)} ${b.position.dy.toStringAsFixed(2)} Z',
        );
      }
    }

    return buffer.toString().trim();
  }

  /// Snaps a control handle offset around [anchor] to the nearest 45-degree angle increment,
  /// preserving the exact drag distance (Illustrator / Figma Shift key constraint).
  static Offset calculateHandleSnapAngle(
    Offset anchor,
    Offset handlePos, {
    double stepRadians = math.pi / 4.0,
  }) {
    final delta = handlePos - anchor;
    if (delta.distance == 0.0) return handlePos;
    final angle = math.atan2(delta.dy, delta.dx);
    final snappedAngle = (angle / stepRadians).round() * stepRadians;
    return anchor +
        Offset(
          delta.distance * math.cos(snappedAngle),
          delta.distance * math.sin(snappedAngle),
        );
  }

  /// Generates the prospective rubber-band curve from [lastNode] to [cursorPos]
  /// or connecting to [firstNode] when closing the path.
  static Path calculateProspectiveCurve(
    PathNode lastNode,
    Offset cursorPos, {
    PathNode? firstNode,
  }) {
    final path = Path();
    final p1 = lastNode.position;
    final cp1 = lastNode.handleOut ?? p1;

    path.moveTo(p1.dx, p1.dy);
    if (firstNode != null) {
      final p2 = firstNode.position;
      final cp2 = firstNode.handleIn ?? p2;
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    } else {
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cursorPos.dx,
        cursorPos.dy,
        cursorPos.dx,
        cursorPos.dy,
      );
    }
    return path;
  }

  /// Extracts anchor [PathNode] points from an existing [Path] by evaluating its contour metrics.
  static List<PathNode> extractNodesFromPath(
    Path path, {
    bool isClosed = false,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return [];
    final nodes = <PathNode>[];

    for (final metric in metrics) {
      final len = metric.length;
      if (len <= 0) continue;

      // Sample nodes evenly along path length
      final step = (len / 8.0).clamp(30.0, 120.0);
      for (double d = 0; d < len; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null) {
          nodes.add(PathNode(position: tangent.position));
        }
      }

      if (!metric.isClosed && !isClosed) {
        final endTangent = metric.getTangentForOffset(len);
        if (endTangent != null &&
            (nodes.isEmpty ||
                (nodes.last.position - endTangent.position).distance > 2.0)) {
          nodes.add(PathNode(position: endTangent.position));
        }
      }
    }
    return nodes;
  }

  /// Tests if [point] hits [node.position] within [tolerance].
  static bool hitTestPathNode(
    Offset point,
    PathNode node, {
    double tolerance = 10.0,
    double zoomScale = 1.0,
  }) {
    final effectiveTol = tolerance / (zoomScale > 0 ? zoomScale : 1.0);
    return (point - node.position).distance <= effectiveTol;
  }

  /// Finds the index of the node in [nodes] hit by [point], or null if none.
  static int? hitTestPathNodes(
    Offset point,
    List<PathNode> nodes, {
    double tolerance = 10.0,
    double zoomScale = 1.0,
  }) {
    final effectiveTol = tolerance / (zoomScale > 0 ? zoomScale : 1.0);
    for (int i = 0; i < nodes.length; i++) {
      if ((point - nodes[i].position).distance <= effectiveTol) {
        return i;
      }
    }
    return null;
  }

  /// Tests if [point] hits [node.handleIn] (returns 1) or [node.handleOut] (returns 2). Returns 0 if none.
  static int hitTestPathHandle(
    Offset point,
    PathNode node, {
    double tolerance = 10.0,
    double zoomScale = 1.0,
  }) {
    final effectiveTol = tolerance / (zoomScale > 0 ? zoomScale : 1.0);
    if (node.handleIn != null &&
        (point - node.handleIn!).distance <= effectiveTol) {
      return 1;
    }
    if (node.handleOut != null &&
        (point - node.handleOut!).distance <= effectiveTol) {
      return 2;
    }
    return 0;
  }

  /// Finds the index of the segment between nodes[i] and nodes[i+1] nearest to [point].
  /// Returns null if no segment is within [threshold].
  static int? findNearestSegmentIndex(
    Offset point,
    List<PathNode> nodes, {
    bool isClosed = false,
    double threshold = 12.0,
    double zoomScale = 1.0,
  }) {
    if (nodes.length < 2) return null;
    int? bestIndex;
    final effectiveThreshold = threshold / (zoomScale > 0 ? zoomScale : 1.0);
    double bestDistance = effectiveThreshold;

    final segmentCount = isClosed ? nodes.length : nodes.length - 1;
    for (int i = 0; i < segmentCount; i++) {
      final a = nodes[i];
      final b = nodes[(i + 1) % nodes.length];

      final p0 = a.position;
      final p1 = a.handleOut ?? a.position;
      final p2 = b.handleIn ?? b.position;
      final p3 = b.position;

      // Sample 12 points along segment
      for (int step = 0; step <= 12; step++) {
        final t = step / 12.0;
        final oneMinusT = 1.0 - t;
        final samplePoint = p0 * (oneMinusT * oneMinusT * oneMinusT) +
            p1 * (3.0 * oneMinusT * oneMinusT * t) +
            p2 * (3.0 * oneMinusT * t * t) +
            p3 * (t * t * t);

        final dist = (point - samplePoint).distance;
        if (dist < bestDistance) {
          bestDistance = dist;
          bestIndex = i;
        }
      }
    }
    return bestIndex;
  }

  /// Calculates a default smooth tangent vector for converting a sharp corner node into a smooth curve.
  static Offset calculateDefaultTangent(
    List<PathNode> nodes,
    int index, {
    bool isClosed = false,
  }) {
    if (nodes.length < 2) return const Offset(20, 0);

    final current = nodes[index].position;
    final prev = nodes[index > 0 ? index - 1 : (isClosed ? nodes.length - 1 : 0)].position;
    final next = nodes[(index + 1) < nodes.length ? index + 1 : (isClosed ? 0 : index)].position;

    final dir = next - prev;
    if (dir.distance == 0) return const Offset(20, 0);

    final normalized = Offset(dir.dx / dir.distance, dir.dy / dir.distance);
    final distanceToPrev = (current - prev).distance;
    final distanceToNext = (next - current).distance;
    final handleLength = math.min(
      math.min(distanceToPrev, distanceToNext) * 0.35,
      60.0,
    );

    return normalized * math.max(handleLength, 15.0);
  }
}
