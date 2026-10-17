import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nixsvg/models/vector_shape.dart';

/// Canvas calculations dedicated to pointer hit-testing for shapes and transform handles.
class CanvasHitTester {
  const CanvasHitTester._();

  /// Hit-tests whether a given canvas point intersects an unlocked, visible shape.
  static bool hitTestShape(Offset point, VectorShape shape) {
    if (!shape.isVisible || shape.isLocked) return false;

    // Generous touch / pointer padding (especially for lines which have zero height)
    if (shape.type == ShapeType.line && !shape.isStroked) return false;
    final padding = shape.type == ShapeType.line ? 16.0 : 8.0;

    // Fast AABB rejection using cached bounding box before trig math
    final bounds = shape.getBoundingBox();
    if (!bounds.inflate(padding).contains(point)) {
      return false;
    }

    final effectiveRect = Rect.fromLTRB(
      math.min(shape.rect.left, shape.rect.right) - padding,
      math.min(shape.rect.top, shape.rect.bottom) - padding,
      math.max(shape.rect.left, shape.rect.right) + padding,
      math.max(shape.rect.top, shape.rect.bottom) + padding,
    );

    if (shape.rotation == 0.0 && shape.type != ShapeType.line) {
      return effectiveRect.contains(point);
    }

    // Transform query point into shape's unrotated coordinate system
    final center = shape.rect.center;
    final rad = -shape.rotation * math.pi / 180.0;
    final cosVal = math.cos(rad);
    final sinVal = math.sin(rad);
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final unrotatedPoint = Offset(
      center.dx + dx * cosVal - dy * sinVal,
      center.dy + dx * sinVal + dy * cosVal,
    );

    if (shape.type == ShapeType.line) {
      final p = unrotatedPoint;
      final v = shape.rect.topLeft;
      final w = shape.rect.bottomRight;
      final l2 = (w.dx - v.dx) * (w.dx - v.dx) + (w.dy - v.dy) * (w.dy - v.dy);
      double distance;
      if (l2 == 0.0) {
        distance = (p - v).distance;
      } else {
        var t =
            ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) /
            l2;
        t = math.max(0.0, math.min(1.0, t));
        final projection = Offset(
          v.dx + t * (w.dx - v.dx),
          v.dy + t * (w.dy - v.dy),
        );
        distance = (p - projection).distance;
      }
      return distance <= padding;
    }

    return effectiveRect.contains(unrotatedPoint);
  }

  /// Returns the unrotated local positions for corner radius handles inside a rectangle.
  static Map<ResizeHandle, Offset> getRadiusHandlePositions(VectorShape shape) {
    if ((shape.type != ShapeType.rectangle &&
            shape.type != ShapeType.roundedRectangle) ||
        shape.rect.width < 32 ||
        shape.rect.height < 32) {
      return const {};
    }
    final rect = shape.rect;
    final maxRadius = math.min(rect.width, rect.height) / 2;
    final currentRadius = (shape.type == ShapeType.roundedRectangle
            ? shape.cornerRadius
            : 0.0)
        .clamp(0.0, maxRadius);
    final handleInset = currentRadius > 0
        ? currentRadius.clamp(8.0, maxRadius)
        : math.min(16.0, maxRadius * 0.4);

    return {
      ResizeHandle.radiusTopLeft:
          Offset(rect.left + handleInset, rect.top + handleInset),
      ResizeHandle.radiusTopRight:
          Offset(rect.right - handleInset, rect.top + handleInset),
      ResizeHandle.radiusBottomLeft:
          Offset(rect.left + handleInset, rect.bottom - handleInset),
      ResizeHandle.radiusBottomRight:
          Offset(rect.right - handleInset, rect.bottom - handleInset),
    };
  }

  /// Hit-tests whether a given canvas point touches a shape's resize, rotation, or radius handle.
  static ResizeHandle hitTestHandle(Offset pos, VectorShape shape) {
    final rect = shape.rect;
    const double hitSize = 26.0;

    // Fast handle rejection using cached bounding box
    final bounds = shape.getBoundingBox();
    if (!bounds.inflate(40.0).contains(pos)) {
      return ResizeHandle.none;
    }

    Offset testPos = pos;
    if (shape.rotation != 0.0) {
      final center = shape.rect.center;
      final rad = -shape.rotation * math.pi / 180.0;
      final cosVal = math.cos(rad);
      final sinVal = math.sin(rad);
      final dx = pos.dx - center.dx;
      final dy = pos.dy - center.dy;
      testPos = Offset(
        center.dx + dx * cosVal - dy * sinVal,
        center.dy + dx * sinVal + dy * cosVal,
      );
    }

    if (shape.type == ShapeType.line) {
      if (Rect.fromCenter(
        center: rect.topLeft,
        width: hitSize,
        height: hitSize,
      ).contains(testPos)) {
        return ResizeHandle.topLeft;
      }
      if (Rect.fromCenter(
        center: rect.bottomRight,
        width: hitSize,
        height: hitSize,
      ).contains(testPos)) {
        return ResizeHandle.bottomRight;
      }
      if (shape.isCurved || shape.curvature != 0.0) {
        final startPt = rect.topLeft;
        final endPt = rect.bottomRight;
        final mid = Offset(
          (startPt.dx + endPt.dx) / 2,
          (startPt.dy + endPt.dy) / 2,
        );
        final dx = endPt.dx - startPt.dx;
        final dy = endPt.dy - startPt.dy;
        final len = math.sqrt(dx * dx + dy * dy);
        final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
        final controlPt = mid + perp * shape.curvature;
        if (Rect.fromCenter(
          center: controlPt,
          width: hitSize,
          height: hitSize,
        ).contains(testPos)) {
          return ResizeHandle.topCenter;
        }
      }
      return ResizeHandle.none;
    }

    // 1. Top Rotation Handle (located 20px above top center)
    final rotCenter = Offset(rect.topCenter.dx, rect.topCenter.dy - 20);
    if ((testPos - rotCenter).distance <= 14.0) {
      return ResizeHandle.rotation;
    }

    // 2. Corner Radius Handles (inside rectangles)
    final radiusHandles = getRadiusHandlePositions(shape);
    for (final entry in radiusHandles.entries) {
      if ((testPos - entry.value).distance <= 13.0) {
        return entry.key;
      }
    }

    // 3. Corner Resize Handles (highest priority corner hits)
    const double cornerHitSize = 24.0;
    if (Rect.fromCenter(
      center: rect.topLeft,
      width: cornerHitSize,
      height: cornerHitSize,
    ).contains(testPos)) {
      return ResizeHandle.topLeft;
    }
    if (Rect.fromCenter(
      center: rect.topRight,
      width: cornerHitSize,
      height: cornerHitSize,
    ).contains(testPos)) {
      return ResizeHandle.topRight;
    }
    if (Rect.fromCenter(
      center: rect.bottomLeft,
      width: cornerHitSize,
      height: cornerHitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomLeft;
    }
    if (Rect.fromCenter(
      center: rect.bottomRight,
      width: cornerHitSize,
      height: cornerHitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomRight;
    }

    // 4. Edge Midpoint Resize Handles
    const double edgeHitSize = 22.0;
    if (Rect.fromCenter(
      center: rect.topCenter,
      width: edgeHitSize,
      height: edgeHitSize,
    ).contains(testPos)) {
      return ResizeHandle.topCenter;
    }
    if (Rect.fromCenter(
      center: rect.bottomCenter,
      width: edgeHitSize,
      height: edgeHitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomCenter;
    }
    if (Rect.fromCenter(
      center: rect.centerLeft,
      width: edgeHitSize,
      height: edgeHitSize,
    ).contains(testPos)) {
      return ResizeHandle.centerLeft;
    }
    if (Rect.fromCenter(
      center: rect.centerRight,
      width: edgeHitSize,
      height: edgeHitSize,
    ).contains(testPos)) {
      return ResizeHandle.centerRight;
    }

    // 5. Outer corner rotation zones (Figma rotates when cursor is slightly outside corner handles)
    if (!rect.deflate(2.0).contains(testPos)) {
      for (final c in [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ]) {
        final dist = (testPos - c).distance;
        if (dist > 12.0 && dist <= 28.0) {
          return ResizeHandle.rotation;
        }
      }
    }

    return ResizeHandle.none;
  }

  /// Hit-tests handles on a multi-selection union bounding box.
  static ResizeHandle hitTestRectHandles(Offset pos, Rect rect) {
    const double hitSize = 22.0;
    if (Rect.fromCenter(center: rect.topLeft, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.topLeft;
    }
    if (Rect.fromCenter(center: rect.topRight, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.topRight;
    }
    if (Rect.fromCenter(center: rect.bottomLeft, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.bottomLeft;
    }
    if (Rect.fromCenter(center: rect.bottomRight, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.bottomRight;
    }
    if (Rect.fromCenter(center: rect.topCenter, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.topCenter;
    }
    if (Rect.fromCenter(center: rect.bottomCenter, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.bottomCenter;
    }
    if (Rect.fromCenter(center: rect.centerLeft, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.centerLeft;
    }
    if (Rect.fromCenter(center: rect.centerRight, width: hitSize, height: hitSize).contains(pos)) {
      return ResizeHandle.centerRight;
    }
    return ResizeHandle.none;
  }
}
