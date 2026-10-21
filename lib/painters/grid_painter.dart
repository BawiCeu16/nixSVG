import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double gridSpacing;
  final Color gridColor;
  final bool isDotGrid;
  final String gridStyle;

  GridPainter({
    this.gridSpacing = 40.0,
    this.gridColor = const Color(0x1AFFFFFF),
    this.isDotGrid = true,
    this.gridStyle = 'dots',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final effectiveStyle =
        gridStyle.isNotEmpty ? gridStyle : (isDotGrid ? 'dots' : 'lines');

    switch (effectiveStyle) {
      case 'crosses':
        const double arm = 3.5;
        for (double x = 0; x <= size.width; x += gridSpacing) {
          for (double y = 0; y <= size.height; y += gridSpacing) {
            canvas.drawLine(Offset(x - arm, y), Offset(x + arm, y), paint);
            canvas.drawLine(Offset(x, y - arm), Offset(x, y + arm), paint);
          }
        }
        break;
      case 'lines':
        for (double x = 0; x <= size.width; x += gridSpacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = 0; y <= size.height; y += gridSpacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;
      case 'dots':
      default:
        for (double x = 0; x <= size.width; x += gridSpacing) {
          for (double y = 0; y <= size.height; y += gridSpacing) {
            canvas.drawCircle(Offset(x, y), 1.2, paint);
          }
        }
        break;
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
