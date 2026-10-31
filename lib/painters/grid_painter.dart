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

  // Static vertex buffer cache to eliminate allocations during canvas redraws
  static final Map<String, Float32List> _pointCache = {};

  GridPainter({
    this.gridSpacing = 40.0,
    this.gridColor = const Color(0x1AFFFFFF),
    this.isDotGrid = true,
    this.gridStyle = 'dots',
    this.transformMatrix,
  });

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

    final paint = Paint()..color = gridColor;

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
    final matrix = transformMatrix!;
    final m0 = matrix.storage[0];
    final m1 = matrix.storage[1];
    final double scale = math.sqrt(m0 * m0 + m1 * m1);
    if (scale <= 0.0 || scale.isNaN || scale.isInfinite) return;

    final double curTx = matrix.storage[12];
    final double curTy = matrix.storage[13];
    final double tx = curTx.isFinite ? curTx : 0.0;
    final double ty = curTy.isFinite ? curTy : 0.0;

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

    final paint = Paint()..color = gridColor;

    if (effectiveStyle == 'lines') {
      paint.strokeWidth = 1.0;
      paint.strokeCap = StrokeCap.butt;
      final int vCount = math.max(0, kEnd - kStart + 1);
      final int hCount = math.max(0, jEnd - jStart + 1);
      final buffer = Float32List((vCount + hCount) * 4);
      int idx = 0;
      for (int k = kStart; k <= kEnd; k++) {
        final double x = k * screenSpacing + tx;
        buffer[idx++] = x;
        buffer[idx++] = 0;
        buffer[idx++] = x;
        buffer[idx++] = height;
      }
      for (int j = jStart; j <= jEnd; j++) {
        final double y = j * screenSpacing + ty;
        buffer[idx++] = 0;
        buffer[idx++] = y;
        buffer[idx++] = width;
        buffer[idx++] = y;
      }
      canvas.drawRawPoints(ui.PointMode.lines, buffer, paint);
    } else if (effectiveStyle == 'crosses') {
      const double arm = 3.5;
      final int totalPoints = math.max(0, (kEnd - kStart + 1) * (jEnd - jStart + 1));
      final buffer = Float32List(totalPoints * 8);
      int idx = 0;
      for (int k = kStart; k <= kEnd; k++) {
        final double x = k * screenSpacing + tx;
        for (int j = jStart; j <= jEnd; j++) {
          final double y = j * screenSpacing + ty;
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
      paint.strokeWidth = 1.0;
      canvas.drawRawPoints(ui.PointMode.lines, buffer, paint);
    } else {
      // dots
      final int totalPoints = math.max(0, (kEnd - kStart + 1) * (jEnd - jStart + 1));
      final buffer = Float32List(totalPoints * 2);
      int idx = 0;
      for (int k = kStart; k <= kEnd; k++) {
        final double x = k * screenSpacing + tx;
        for (int j = jStart; j <= jEnd; j++) {
          final double y = j * screenSpacing + ty;
          buffer[idx++] = x;
          buffer[idx++] = y;
        }
      }
      paint.strokeWidth = 2.4;
      paint.strokeCap = StrokeCap.round;
      canvas.drawRawPoints(ui.PointMode.points, buffer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.isDotGrid != isDotGrid ||
        oldDelegate.gridStyle != gridStyle ||
        oldDelegate.transformMatrix != transformMatrix;
  }
}
