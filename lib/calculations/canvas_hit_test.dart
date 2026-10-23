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
    if (point.dx < bounds.left - padding ||
        point.dx > bounds.right + padding ||
        point.dy < bounds.top - padding ||
        point.dy > bounds.bottom + padding) {
      return false;
    }

    final left = math.min(shape.rect.left, shape.rect.right) - padding;
    final top = math.min(shape.rect.top, shape.rect.bottom) - padding;
    final right = math.max(shape.rect.left, shape.rect.right) + padding;
    final bottom = math.max(shape.rect.top, shape.rect.bottom) + padding;

    if (shape.rotation == 0.0 && shape.type != ShapeType.line) {
      if (shape.type == ShapeType.polygon) {
        return shape.getPath().contains(point);
      }
      if (shape.type == ShapeType.path) {
        if (shape.isFilled && shape.getPath().contains(point)) {
          return true;
        }
        return point.dx >= left &&
            point.dx <= right &&
            point.dy >= top &&
            point.dy <= bottom;
      }
      return point.dx >= left &&
          point.dx <= right &&
          point.dy >= top &&
          point.dy <= bottom;
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

    if (shape.type == ShapeType.polygon) {
      return shape.getPath().contains(unrotatedPoint);
    }
    if (shape.type == ShapeType.path) {
      if (shape.isFilled && shape.getPath().contains(unrotatedPoint)) {
        return true;
      }
      return unrotatedPoint.dx >= left &&
          unrotatedPoint.dx <= right &&
          unrotatedPoint.dy >= top &&
          unrotatedPoint.dy <= bottom;
    }

    return unrotatedPoint.dx >= left &&
        unrotatedPoint.dx <= right &&
        unrotatedPoint.dy >= top &&
        unrotatedPoint.dy <= bottom;
  }

  /// Returns the unrotated local position for the star inner ratio handle,
  /// dynamically adjusting for [zoomScale].
  static Offset? getRatioHandlePosition(
    VectorShape shape, {
    double zoomScale = 1.0,
  }) {
    if (shape.type != ShapeType.star) return null;
    final s = (1.0 / (zoomScale > 0 ? zoomScale : 1.0)).clamp(0.02, 50.0);
    final minSize = 24.0 * s;
    if (shape.rect.width < minSize || shape.rect.height < minSize) return null;

    final rect = shape.rect;
    final maxRadius = math.min(rect.width, rect.height) / 2;
    final center = rect.center;
    final numPoints = math.max(3, shape.pointCount);
    final ratio = shape.innerRadiusRatio.clamp(0.05, 0.95);
    final innerRadius = maxRadius * ratio;
    final angleStep = math.pi / numPoints;
    final angle = angleStep - math.pi / 2;
    return Offset(
      center.dx + innerRadius * math.cos(angle),
      center.dy + innerRadius * math.sin(angle),
    );
  }

  /// Returns the unrotated local positions for corner radius and ratio handles inside a shape,
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

    if (shape.type == ShapeType.star || shape.type == ShapeType.polygon) {
      final rect = shape.rect;
      final maxRadius = math.min(rect.width, rect.height) / 2;
      final center = rect.center;
      final rInset = math.min(
        shape.cornerRadius > 0
            ? shape.cornerRadius.clamp(10.0 * s, maxRadius * 0.45)
            : 16.0 * s,
        maxRadius * 0.45,
      );
      final ratioPoint = getRatioHandlePosition(shape, zoomScale: zoomScale);
      return {
        ResizeHandle.radiusTopLeft: Offset(center.dx, center.dy - maxRadius + rInset),
        ResizeHandle.ratio: ?ratioPoint,
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
    final double halfHit = hitSize / 2;

    // Fast handle rejection using cached bounding box without inflate allocation
    final bounds = shape.getBoundingBox();
    final pad = 45.0 * s;
    if (pos.dx < bounds.left - pad ||
        pos.dx > bounds.right + pad ||
        pos.dy < bounds.top - pad ||
        pos.dy > bounds.bottom + pad) {
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
      if ((testPos.dx - rect.topLeft.dx).abs() <= halfHit &&
          (testPos.dy - rect.topLeft.dy).abs() <= halfHit) {
        return ResizeHandle.topLeft;
      }
      if ((testPos.dx - rect.bottomRight.dx).abs() <= halfHit &&
          (testPos.dy - rect.bottomRight.dy).abs() <= halfHit) {
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
        if ((testPos.dx - controlPt.dx).abs() <= halfHit &&
            (testPos.dy - controlPt.dy).abs() <= halfHit) {
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
    final double cornerHalfHit = 12.0 * s;
    if ((testPos.dx - rect.topLeft.dx).abs() <= cornerHalfHit &&
        (testPos.dy - rect.topLeft.dy).abs() <= cornerHalfHit) {
      return ResizeHandle.topLeft;
    }
    if ((testPos.dx - rect.topRight.dx).abs() <= cornerHalfHit &&
        (testPos.dy - rect.topRight.dy).abs() <= cornerHalfHit) {
      return ResizeHandle.topRight;
    }
    if ((testPos.dx - rect.bottomLeft.dx).abs() <= cornerHalfHit &&
        (testPos.dy - rect.bottomLeft.dy).abs() <= cornerHalfHit) {
      return ResizeHandle.bottomLeft;
    }
    if ((testPos.dx - rect.bottomRight.dx).abs() <= cornerHalfHit &&
        (testPos.dy - rect.bottomRight.dy).abs() <= cornerHalfHit) {
      return ResizeHandle.bottomRight;
    }

    // 4. Edge Midpoint Resize Handles
    final double edgeHalfHit = 11.0 * s;
    if ((testPos.dx - rect.topCenter.dx).abs() <= edgeHalfHit &&
        (testPos.dy - rect.topCenter.dy).abs() <= edgeHalfHit) {
      return ResizeHandle.topCenter;
    }
    if ((testPos.dx - rect.bottomCenter.dx).abs() <= edgeHalfHit &&
        (testPos.dy - rect.bottomCenter.dy).abs() <= edgeHalfHit) {
      return ResizeHandle.bottomCenter;
    }
    if ((testPos.dx - rect.centerLeft.dx).abs() <= edgeHalfHit &&
        (testPos.dy - rect.centerLeft.dy).abs() <= edgeHalfHit) {
      return ResizeHandle.centerLeft;
    }
    if ((testPos.dx - rect.centerRight.dx).abs() <= edgeHalfHit &&
        (testPos.dy - rect.centerRight.dy).abs() <= edgeHalfHit) {
      return ResizeHandle.centerRight;
    }

    // 5. Outer corner rotation zones (Figma rotates when cursor is slightly outside corner handles)
    final deflatePad = 2.0 * s;
    final isInsideDeflated = testPos.dx >= rect.left + deflatePad &&
        testPos.dx <= rect.right - deflatePad &&
        testPos.dy >= rect.top + deflatePad &&
        testPos.dy <= rect.bottom - deflatePad;
    if (!isInsideDeflated) {
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
    final double halfHit = 11.0 * s;
    if ((pos.dx - rect.topLeft.dx).abs() <= halfHit &&
        (pos.dy - rect.topLeft.dy).abs() <= halfHit) {
      return ResizeHandle.topLeft;
    }
    if ((pos.dx - rect.topRight.dx).abs() <= halfHit &&
        (pos.dy - rect.topRight.dy).abs() <= halfHit) {
      return ResizeHandle.topRight;
    }
    if ((pos.dx - rect.bottomLeft.dx).abs() <= halfHit &&
        (pos.dy - rect.bottomLeft.dy).abs() <= halfHit) {
      return ResizeHandle.bottomLeft;
    }
    if ((pos.dx - rect.bottomRight.dx).abs() <= halfHit &&
        (pos.dy - rect.bottomRight.dy).abs() <= halfHit) {
      return ResizeHandle.bottomRight;
    }
    if ((pos.dx - rect.topCenter.dx).abs() <= halfHit &&
        (pos.dy - rect.topCenter.dy).abs() <= halfHit) {
      return ResizeHandle.topCenter;
    }
    if ((pos.dx - rect.bottomCenter.dx).abs() <= halfHit &&
        (pos.dy - rect.bottomCenter.dy).abs() <= halfHit) {
      return ResizeHandle.bottomCenter;
    }
    if ((pos.dx - rect.centerLeft.dx).abs() <= halfHit &&
        (pos.dy - rect.centerLeft.dy).abs() <= halfHit) {
      return ResizeHandle.centerLeft;
    }
    if ((pos.dx - rect.centerRight.dx).abs() <= halfHit &&
        (pos.dy - rect.centerRight.dy).abs() <= halfHit) {
      return ResizeHandle.centerRight;
    }
    return ResizeHandle.none;
  }
}
