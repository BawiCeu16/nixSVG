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
  static MouseCursor getHandleCursor(ResizeHandle handle, [double rotation = 0.0]) {
    if (handle == ResizeHandle.none) return SystemMouseCursors.basic;
    // Rotation handle & corner rotation zones: curved rotation cursor
    if (handle == ResizeHandle.rotation) return SystemMouseCursors.alias;
    if (handle.isRadius) return SystemMouseCursors.precise;

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
    final normalized =
        effectiveAngle < 0 ? effectiveAngle + 180.0 : effectiveAngle;

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
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)),
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
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)),
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
      sb.write(
        ' L ${tIn.dx.toStringAsFixed(1)} ${tIn.dy.toStringAsFixed(1)}',
      );
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
}
