import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';

void main() {
  group('Line Drawing and Arrow Precision Tests', () {
    test(
      'calculateDrawRect preserves exact start and end points across all 4 quadrants',
      () {
        const start = Offset(200, 200);

        // Quadrant 1: Bottom-Right (x > start.x, y > start.y)
        const endBR = Offset(350, 300);
        final rectBR = CanvasGeometry.calculateDrawRect(
          start: start,
          current: endBR,
          shapeType: ShapeType.line,
          isShiftPressed: false,
          isAltPressed: false,
        );
        expect(rectBR.topLeft, equals(start));
        expect(rectBR.bottomRight, equals(endBR));

        // Quadrant 2: Bottom-Left (x < start.x, y > start.y)
        const endBL = Offset(50, 300);
        final rectBL = CanvasGeometry.calculateDrawRect(
          start: start,
          current: endBL,
          shapeType: ShapeType.line,
          isShiftPressed: false,
          isAltPressed: false,
        );
        expect(rectBL.topLeft, equals(start));
        expect(rectBL.bottomRight, equals(endBL));

        // Quadrant 3: Top-Left (x < start.x, y < start.y)
        const endTL = Offset(80, 70);
        final rectTL = CanvasGeometry.calculateDrawRect(
          start: start,
          current: endTL,
          shapeType: ShapeType.line,
          isShiftPressed: false,
          isAltPressed: false,
        );
        expect(rectTL.topLeft, equals(start));
        expect(rectTL.bottomRight, equals(endTL));

        // Quadrant 4: Top-Right (x > start.x, y < start.y)
        const endTR = Offset(320, 90);
        final rectTR = CanvasGeometry.calculateDrawRect(
          start: start,
          current: endTR,
          shapeType: ShapeType.line,
          isShiftPressed: false,
          isAltPressed: false,
        );
        expect(rectTR.topLeft, equals(start));
        expect(rectTR.bottomRight, equals(endTR));
      },
    );

    test('calculateDrawRect with Alt expands line symmetrically from center', () {
      const start = Offset(200, 200);
      const current = Offset(260, 280); // delta = (60, 80)

      final altRect = CanvasGeometry.calculateDrawRect(
        start: start,
        current: current,
        shapeType: ShapeType.line,
        isShiftPressed: false,
        isAltPressed: true,
      );

      // Symmetrically expanded: p1 = (140, 120), p2 = (260, 280)
      expect(altRect.topLeft, equals(const Offset(140, 120)));
      expect(altRect.bottomRight, equals(const Offset(260, 280)));
      // Midpoint of line is start
      final mid = (altRect.topLeft + altRect.bottomRight) / 2;
      expect(mid, equals(start));
    });

    test('calculateDrawRect with Shift snaps angle to 45-degree increments', () {
      const start = Offset(100, 100);
      // Nearly horizontal drag to the right (dx=100, dy=5) -> snaps to 0 degrees
      const currentH = Offset(200, 105);
      final rectH = CanvasGeometry.calculateDrawRect(
        start: start,
        current: currentH,
        shapeType: ShapeType.line,
        isShiftPressed: true,
        isAltPressed: false,
      );
      expect(rectH.topLeft, equals(start));
      expect(rectH.bottomRight.dy, closeTo(start.dy, 0.001));

      // Dragging left (dx=-100, dy=-5) -> snaps to 180 degrees
      const currentLeft = Offset(0, 95);
      final rectLeft = CanvasGeometry.calculateDrawRect(
        start: start,
        current: currentLeft,
        shapeType: ShapeType.line,
        isShiftPressed: true,
        isAltPressed: false,
      );
      expect(rectLeft.topLeft, equals(start));
      expect(rectLeft.bottomRight.dy, closeTo(start.dy, 0.001));
      expect(rectLeft.bottomRight.dx, lessThan(start.dx));
    });

    test('resizeRect for line adjusts handles precisely', () {
      final initial = Rect.fromLTRB(100, 150, 300, 250);
      final startOffset = Offset.zero;

      // Move top-left handle (start point) by (-20, -30)
      final currentTL = const Offset(-20, -30);
      final resizedTL = CanvasGeometry.resizeRect(
        initial,
        startOffset,
        currentTL,
        ResizeHandle.topLeft,
        isLine: true,
      );
      expect(resizedTL.topLeft, equals(const Offset(80, 120)));
      expect(resizedTL.bottomRight, equals(const Offset(300, 250)));

      // Move bottom-right handle (end point) by (40, 50)
      final currentBR = const Offset(40, 50);
      final resizedBR = CanvasGeometry.resizeRect(
        initial,
        startOffset,
        currentBR,
        ResizeHandle.bottomRight,
        isLine: true,
      );
      expect(resizedBR.topLeft, equals(const Offset(100, 150)));
      expect(resizedBR.bottomRight, equals(const Offset(340, 300)));
    });

    test('Line with arrow caps renders correctly and exports SVG with markers', () {
      final lineShape = VectorShape(
        id: 'line-arrow-1',
        name: 'Directional Arrow',
        type: ShapeType.line,
        rect: Rect.fromLTRB(50, 50, 250, 150),
        isStroked: true,
        strokeWidth: 4.0,
        strokeColor: const Color(0xFFE11D48),
        startCap: LineCapStyle.circle,
        endCap: LineCapStyle.arrow,
      );

      // Verify SVG defs contain arrow-end marker
      final defs = lineShape.toSvgDefs();
      expect(defs, contains('marker id="arrow-end-line-arrow-1"'));

      // Verify SVG element references marker-end
      final svgElement = lineShape.toSvgElement();
      expect(svgElement, contains('marker-end="url(#arrow-end-line-arrow-1)"'));
      expect(svgElement, contains('x1="50.0" y1="50.0" x2="250.0" y2="150.0"'));
    });

    testWidgets('VectorCanvasPainter paints line and arrows without throwing', (
      tester,
    ) async {
      final shapeWithArrows = VectorShape(
        id: 'arrow-test',
        name: 'Arrow Line',
        type: ShapeType.line,
        rect: Rect.fromLTRB(100, 200, 400, 100), // Directional line (up and right)
        isStroked: true,
        strokeWidth: 3.0,
        strokeColor: Colors.blue,
        startCap: LineCapStyle.arrow,
        endCap: LineCapStyle.arrow,
      );

      final painter = VectorCanvasPainter(
        shapes: [shapeWithArrows],
        selectedShapeIds: {'arrow-test'},
        currentMode: EditorMode.select,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(800, 600),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets(
      'VectorCanvasPainter paints curved line and arrows without throwing',
      (tester) async {
        final curvedShape = VectorShape(
          id: 'curved-arrow-test',
          name: 'Curved Arrow Line',
          type: ShapeType.line,
          rect: Rect.fromLTRB(100, 100, 400, 400),
          isStroked: true,
          strokeWidth: 4.0,
          strokeColor: Colors.green,
          isCurved: true,
          curvature: 40.0,
          startCap: LineCapStyle.circle,
          endCap: LineCapStyle.arrow,
        );

        final painter = VectorCanvasPainter(
          shapes: [curvedShape],
          selectedShapeIds: {'curved-arrow-test'},
          currentMode: EditorMode.select,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(800, 600),
                painter: painter,
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      },
    );
  });
}
