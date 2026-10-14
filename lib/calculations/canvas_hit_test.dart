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

  /// Hit-tests whether a given canvas point touches a shape's resize or rotation handle.
  static ResizeHandle hitTestHandle(Offset pos, VectorShape shape) {
    final rect = shape.rect;
    const double hitSize = 28.0; // Touch and mouse friendly handle size

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

    // Rotation Handle (located 24px above top center or slightly outside any of the 4 corners like Figma)
    if (Rect.fromCenter(
      center: Offset(rect.topCenter.dx, rect.topCenter.dy - 24),
      width: hitSize + 4,
      height: hitSize + 4,
    ).contains(testPos)) {
      return ResizeHandle.rotation;
    }

    // Outer corner rotation zones (Figma rotates when cursor is slightly outside corner handles)
    for (final c in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      final dist = (testPos - c).distance;
      if (dist > hitSize / 2 && dist <= hitSize / 2 + 14) {
        return ResizeHandle.rotation;
      }
    }

    // Corner Handles
    if (Rect.fromCenter(
      center: rect.topLeft,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.topLeft;
    }
    if (Rect.fromCenter(
      center: rect.topRight,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.topRight;
    }
    if (Rect.fromCenter(
      center: rect.bottomLeft,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomLeft;
    }
    if (Rect.fromCenter(
      center: rect.bottomRight,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomRight;
    }

    // Edge Midpoint Handles
    if (Rect.fromCenter(
      center: rect.topCenter,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.topCenter;
    }
    if (Rect.fromCenter(
      center: rect.bottomCenter,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomCenter;
    }
    if (Rect.fromCenter(
      center: rect.centerLeft,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.centerLeft;
    }
    if (Rect.fromCenter(
      center: rect.centerRight,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.centerRight;
    }

    return ResizeHandle.none;
  }
}
