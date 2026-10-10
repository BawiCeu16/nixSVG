import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double gridSpacing;
  final Color gridColor;
  final bool isDotGrid;

  GridPainter({
    this.gridSpacing = 40.0,
    this.gridColor = const Color(0x1AFFFFFF),
    this.isDotGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    if (isDotGrid) {
      for (double x = 0; x <= size.width; x += gridSpacing) {
        for (double y = 0; y <= size.height; y += gridSpacing) {
          canvas.drawCircle(Offset(x, y), 1.2, paint);
        }
      }
    } else {
      for (double x = 0; x <= size.width; x += gridSpacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y <= size.height; y += gridSpacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.isDotGrid != isDotGrid;
  }
}
