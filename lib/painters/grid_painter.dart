import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// High-performance GPU-accelerated grid background painter for nixSVG.
/// Utilizes memoized Float32List vertex buffers and [Canvas.drawRawPoints]
/// to batch thousands of grid points/lines into a single Skia/Impeller draw call.
class GridPainter extends CustomPainter {
  final double gridSpacing;
  final Color gridColor;
  final bool isDotGrid;
  final String gridStyle;

  // Static vertex buffer cache to eliminate allocations during canvas redraws
  static final Map<String, Float32List> _pointCache = {};

  GridPainter({
    this.gridSpacing = 40.0,
    this.gridColor = const Color(0x1AFFFFFF),
    this.isDotGrid = true,
    this.gridStyle = 'dots',
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

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.isDotGrid != isDotGrid ||
        oldDelegate.gridStyle != gridStyle;
  }
}
