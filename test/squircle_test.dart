import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_m3shapes_extended/flutter_m3shapes_extended.dart';

void main() {
  test('RoundedPolygon squircle path generation test', () {
    final rect = Rect.fromLTWH(100, 100, 200, 150);
    final poly = RoundedPolygon.rectangle(
      width: rect.width,
      height: rect.height,
      centerX: rect.center.dx,
      centerY: rect.center.dy,
      rounding: const CornerRounding(radius: 24, smoothing: 0.6),
    );
    expect(poly.cubics.length, greaterThan(0));
    final path = poly.toPath();
    final bounds = path.getBounds();
    expect(bounds.left, closeTo(rect.left, 1.0));
    expect(bounds.top, closeTo(rect.top, 1.0));
    expect(bounds.right, closeTo(rect.right, 1.0));
    expect(bounds.bottom, closeTo(rect.bottom, 1.0));
  });

  test('RoundedPolygon with perVertexRounding and SVG path export', () {
    final rect = Rect.fromLTWH(50, 50, 100, 100);
    final poly = RoundedPolygon.rectangle(
      width: rect.width,
      height: rect.height,
      centerX: rect.center.dx,
      centerY: rect.center.dy,
      perVertexRounding: const [
        CornerRounding(radius: 10, smoothing: 0.6), // bottomRight
        CornerRounding(radius: 20, smoothing: 0.6), // bottomLeft
        CornerRounding(radius: 0, smoothing: 0.6),  // topLeft
        CornerRounding(radius: 15, smoothing: 0.6), // topRight
      ],
    );
    expect(poly.cubics.length, greaterThan(0));
    final path = poly.toPath();
    expect(path.getBounds().width, closeTo(100, 1.0));

    final sb = StringBuffer();
    for (int i = 0; i < poly.cubics.length; i++) {
      final c = poly.cubics[i];
      if (i == 0) {
        sb.write('M ${c.anchor0X.toStringAsFixed(2)} ${c.anchor0Y.toStringAsFixed(2)} ');
      }
      sb.write('C ${c.control0X.toStringAsFixed(2)} ${c.control0Y.toStringAsFixed(2)}, '
          '${c.control1X.toStringAsFixed(2)} ${c.control1Y.toStringAsFixed(2)}, '
          '${c.anchor1X.toStringAsFixed(2)} ${c.anchor1Y.toStringAsFixed(2)} ');
    }
    sb.write('Z');
    final svgPath = sb.toString();
    expect(svgPath.startsWith('M '), isTrue);
    expect(svgPath.endsWith('Z'), isTrue);
  });
}
