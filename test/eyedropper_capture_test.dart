import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RenderRepaintBoundary captures exact pixel colors', (tester) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFFFF5500),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(byteData, isNotNull);

      // Read center pixel at (50, 50)
      final offset = (50 * image.width + 50) * 4;
      final r = byteData!.getUint8(offset);
      final g = byteData.getUint8(offset + 1);
      final b = byteData.getUint8(offset + 2);
      final a = byteData.getUint8(offset + 3);

      expect(r, 0xFF);
      expect(g, 0x55);
      expect(b, 0x00);
      expect(a, 0xFF);
    });
  });
}
