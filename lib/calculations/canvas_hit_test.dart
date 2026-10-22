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

  /// Returns the unrotated local positions for corner radius handles inside a rectangle,
  /// dynamically adjusting for [zoomScale].
  static Map<ResizeHandle, Offset> getRadiusHandlePositions(
    VectorShape shape, {
    double zoomScale = 1.0,
  }) {
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    final minSize = 24.0 * s;
    if (shape.rect.width < minSize || shape.rect.height < minSize) {
      return const {};
    }

    if (shape.type == ShapeType.star) {
      final rect = shape.rect;
      final maxRadius = math.min(rect.width, rect.height) / 2;
      final center = rect.center;
      final rInset = math.min(
        shape.cornerRadius > 0
            ? shape.cornerRadius.clamp(10.0 * s, maxRadius * 0.45)
            : 16.0 * s,
        maxRadius * 0.45,
      );
      return {
        ResizeHandle.radiusTopLeft: Offset(center.dx, center.dy - maxRadius + rInset),
      };
    }

    if (shape.type != ShapeType.rectangle &&
        shape.type != ShapeType.roundedRectangle &&
        shape.type != ShapeType.image) {
      return const {};
    }
    final rect = shape.rect;
    final maxRadius = math.min(rect.width, rect.height) / 2;

    final tlRadius = shape.effectiveTopLeftRadius.clamp(0.0, maxRadius);
    final trRadius = shape.effectiveTopRightRadius.clamp(0.0, maxRadius);
    final blRadius = shape.effectiveBottomLeftRadius.clamp(0.0, maxRadius);
    final brRadius = shape.effectiveBottomRightRadius.clamp(0.0, maxRadius);

    final tlInset = tlRadius > 0
        ? tlRadius.clamp(8.0 * s, maxRadius)
        : math.min(16.0 * s, maxRadius * 0.4);
    final trInset = trRadius > 0
        ? trRadius.clamp(8.0 * s, maxRadius)
        : math.min(16.0 * s, maxRadius * 0.4);
    final blInset = blRadius > 0
        ? blRadius.clamp(8.0 * s, maxRadius)
        : math.min(16.0 * s, maxRadius * 0.4);
    final brInset = brRadius > 0
        ? brRadius.clamp(8.0 * s, maxRadius)
        : math.min(16.0 * s, maxRadius * 0.4);

    return {
      ResizeHandle.radiusTopLeft:
          Offset(rect.left + tlInset, rect.top + tlInset),
      ResizeHandle.radiusTopRight:
          Offset(rect.right - trInset, rect.top + trInset),
      ResizeHandle.radiusBottomLeft:
          Offset(rect.left + blInset, rect.bottom - blInset),
      ResizeHandle.radiusBottomRight:
          Offset(rect.right - brInset, rect.bottom - brInset),
    };
  }

  /// Hit-tests whether a given canvas point touches a shape's resize, rotation, or radius handle.
  /// Dynamically scales hit areas with [zoomScale] so handles are equally easy to hit at all zoom levels.
  static ResizeHandle hitTestHandle(
    Offset pos,
    VectorShape shape, {
    double zoomScale = 1.0,
  }) {
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    final rect = shape.rect;
    final double hitSize = 26.0 * s;

    // Fast handle rejection using cached bounding box
    final bounds = shape.getBoundingBox();
    if (!bounds.inflate(45.0 * s).contains(pos)) {
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

    // 1. Top Rotation Handle (located 20 * s pixels above top center)
    final rotCenter = Offset(rect.topCenter.dx, rect.topCenter.dy - 20.0 * s);
    if ((testPos - rotCenter).distance <= 16.0 * s) {
      return ResizeHandle.rotation;
    }

    // 2. Corner Radius Handles (inside rectangles)
    final radiusHandles = getRadiusHandlePositions(shape, zoomScale: zoomScale);
    for (final entry in radiusHandles.entries) {
      if ((testPos - entry.value).distance <= 14.0 * s) {
        return entry.key;
      }
    }

    // 3. Corner Resize Handles (highest priority corner hits)
    final double cornerHitSize = 24.0 * s;
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
    final double edgeHitSize = 22.0 * s;
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
    if (!rect.deflate(2.0 * s).contains(testPos)) {
      for (final c in [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ]) {
        final dist = (testPos - c).distance;
        if (dist > 12.0 * s && dist <= 32.0 * s) {
          return ResizeHandle.rotation;
        }
      }
    }

    return ResizeHandle.none;
  }

  /// Hit-tests handles on a multi-selection union bounding box.
  static ResizeHandle hitTestRectHandles(
    Offset pos,
    Rect rect, {
    double zoomScale = 1.0,
  }) {
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    final double hitSize = 22.0 * s;
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
