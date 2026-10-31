import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// High-performance GPU-accelerated grid background painter for nixSVG.
/// Utilizes memoized Float32List vertex buffers and [Canvas.drawRawPoints]
/// to batch thousands of grid points/lines into a single Skia/Impeller draw call.
/// Supports infinite canvas viewport rendering via [transformMatrix].
class GridPainter extends CustomPainter {
  final double gridSpacing;
  final Color gridColor;
  final bool isDotGrid;
  final String gridStyle;
  final Matrix4? transformMatrix;
  final double scale;
  final double tx;
  final double ty;

  // Static vertex buffer cache to eliminate allocations during canvas redraws
  static final Map<String, Float32List> _pointCache = {};
  static Float32List? _sharedInfiniteBuffer;
  static final Paint _sharedPaint = Paint();

  static Float32List _ensureInfiniteBuffer(int count) {
    if (_sharedInfiniteBuffer == null || _sharedInfiniteBuffer!.length < count) {
      final newCapacity = math.max(
        count,
        math.max(2048, (_sharedInfiniteBuffer?.length ?? 0) * 2),
      );
      _sharedInfiniteBuffer = Float32List(newCapacity);
    }
    return _sharedInfiniteBuffer!;
  }

  GridPainter({
    this.gridSpacing = 40.0,
    this.gridColor = const Color(0x1AFFFFFF),
    this.isDotGrid = true,
    this.gridStyle = 'dots',
    this.transformMatrix,
  })  : scale = transformMatrix != null
            ? math.sqrt(
                transformMatrix.storage[0] * transformMatrix.storage[0] +
                    transformMatrix.storage[1] * transformMatrix.storage[1],
              )
            : 1.0,
        tx = transformMatrix != null && transformMatrix.storage[12].isFinite
            ? transformMatrix.storage[12]
            : 0.0,
        ty = transformMatrix != null && transformMatrix.storage[13].isFinite
            ? transformMatrix.storage[13]
            : 0.0;

  static Float32List _getPoints(
    double width,
    double height,
    double spacing,
    String style,
  ) {
    final key = '${width.toInt()}_${height.toInt()}_${spacing.toInt()}_$style';
    final existing = _pointCache[key];
    if (existing != null) return existing;

    final cols = (width / spacing).floor() + 1;
    final rows = (height / spacing).floor() + 1;

    Float32List buffer;
    if (style == 'crosses') {
      const double arm = 3.5;
      buffer = Float32List(cols * rows * 8);
      int idx = 0;
      for (double x = 0; x <= width; x += spacing) {
        for (double y = 0; y <= height; y += spacing) {
          buffer[idx++] = x - arm;
          buffer[idx++] = y;
          buffer[idx++] = x + arm;
          buffer[idx++] = y;
          buffer[idx++] = x;
          buffer[idx++] = y - arm;
          buffer[idx++] = x;
          buffer[idx++] = y + arm;
        }
      }
    } else if (style == 'lines') {
      buffer = Float32List((cols + rows) * 4);
      int idx = 0;
      for (double x = 0; x <= width; x += spacing) {
        buffer[idx++] = x;
        buffer[idx++] = 0;
        buffer[idx++] = x;
        buffer[idx++] = height;
      }
      for (double y = 0; y <= height; y += spacing) {
        buffer[idx++] = 0;
        buffer[idx++] = y;
        buffer[idx++] = width;
        buffer[idx++] = y;
      }
    } else {
      // dots
      buffer = Float32List(cols * rows * 2);
      int idx = 0;
      for (double x = 0; x <= width; x += spacing) {
        for (double y = 0; y <= height; y += spacing) {
          buffer[idx++] = x;
          buffer[idx++] = y;
        }
      }
    }

    // Keep cache bounded
    if (_pointCache.length > 20) {
      _pointCache.clear();
    }
    _pointCache[key] = buffer;
    return buffer;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (transformMatrix != null) {
      _paintInfiniteGrid(canvas, size);
      return;
    }

    final effectiveStyle =
        gridStyle.isNotEmpty ? gridStyle : (isDotGrid ? 'dots' : 'lines');
    final double spacing =
        (gridSpacing.isFinite && gridSpacing >= 4.0) ? gridSpacing : 40.0;

    final points = _getPoints(size.width, size.height, spacing, effectiveStyle);

    final paint = _sharedPaint..color = gridColor;

    if (effectiveStyle == 'dots') {
      paint.strokeWidth = 2.4;
      paint.strokeCap = StrokeCap.round;
      canvas.drawRawPoints(ui.PointMode.points, points, paint);
    } else {
      paint.strokeWidth = 1.0;
      paint.strokeCap = StrokeCap.butt;
      canvas.drawRawPoints(ui.PointMode.lines, points, paint);
    }
  }

  void _paintInfiniteGrid(Canvas canvas, Size size) {
    if (scale <= 0.0 || scale.isNaN || scale.isInfinite) return;

    final double baseSpacing =
        (gridSpacing.isFinite && gridSpacing >= 4.0) ? gridSpacing : 40.0;
    final effectiveStyle =
        gridStyle.isNotEmpty ? gridStyle : (isDotGrid ? 'dots' : 'lines');

    // Dynamic Level of Detail (LOD) - adapt grid spacing during zoom out
    double effectiveSpacing = baseSpacing;
    double screenSpacing = effectiveSpacing * scale;
    while (screenSpacing < 18.0) {
      effectiveSpacing *= 2.0;
      screenSpacing = effectiveSpacing * scale;
    }

    final double width = size.width;
    final double height = size.height;

    final int kStart = ((-tx) / screenSpacing).floor() - 1;
    final int kEnd = ((width - tx) / screenSpacing).ceil() + 1;
    final int jStart = ((-ty) / screenSpacing).floor() - 1;
    final int jEnd = ((height - ty) / screenSpacing).ceil() + 1;

    final paint = _sharedPaint..color = gridColor;

    if (effectiveStyle == 'lines') {
      paint.strokeWidth = 1.0;
      paint.strokeCap = StrokeCap.butt;
      final int vCount = math.max(0, kEnd - kStart + 1);
      final int hCount = math.max(0, jEnd - jStart + 1);
      final int count = (vCount + hCount) * 4;
      final raw = _ensureInfiniteBuffer(count);
      int idx = 0;
      for (int k = kStart; k <= kEnd; k++) {
        final double x = k * screenSpacing + tx;
        raw[idx++] = x;
        raw[idx++] = 0;
        raw[idx++] = x;
        raw[idx++] = height;
      }
      for (int j = jStart; j <= jEnd; j++) {
        final double y = j * screenSpacing + ty;
        raw[idx++] = 0;
        raw[idx++] = y;
        raw[idx++] = width;
        raw[idx++] = y;
      }
      final buffer = Float32List.sublistView(raw, 0, count);
      canvas.drawRawPoints(ui.PointMode.lines, buffer, paint);
    } else if (effectiveStyle == 'crosses') {
      const double arm = 3.5;
      final int totalPoints =
          math.max(0, (kEnd - kStart + 1) * (jEnd - jStart + 1));
      final int count = totalPoints * 8;
      final raw = _ensureInfiniteBuffer(count);
      int idx = 0;
      for (int k = kStart; k <= kEnd; k++) {
        final double x = k * screenSpacing + tx;
        for (int j = jStart; j <= jEnd; j++) {
          final double y = j * screenSpacing + ty;
          raw[idx++] = x - arm;
          raw[idx++] = y;
          raw[idx++] = x + arm;
          raw[idx++] = y;
          raw[idx++] = x;
          raw[idx++] = y - arm;
          raw[idx++] = x;
          raw[idx++] = y + arm;
        }
      }
      paint.strokeWidth = 1.0;
      final buffer = Float32List.sublistView(raw, 0, count);
      canvas.drawRawPoints(ui.PointMode.lines, buffer, paint);
    } else {
      // dots
      final int totalPoints =
          math.max(0, (kEnd - kStart + 1) * (jEnd - jStart + 1));
      final int count = totalPoints * 2;
      final raw = _ensureInfiniteBuffer(count);
      int idx = 0;
      for (int k = kStart; k <= kEnd; k++) {
        final double x = k * screenSpacing + tx;
        for (int j = jStart; j <= jEnd; j++) {
          final double y = j * screenSpacing + ty;
          raw[idx++] = x;
          raw[idx++] = y;
        }
      }
      paint.strokeWidth = 2.4;
      paint.strokeCap = StrokeCap.round;
      final buffer = Float32List.sublistView(raw, 0, count);
      canvas.drawRawPoints(ui.PointMode.points, buffer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.isDotGrid != isDotGrid ||
        oldDelegate.gridStyle != gridStyle ||
        oldDelegate.scale != scale ||
        oldDelegate.tx != tx ||
        oldDelegate.ty != ty;
  }
}
