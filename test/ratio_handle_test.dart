import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';

void main() {
  group('Star Ratio Handle Calculations & Hit Testing', () {
    test('ResizeHandle.ratio properties and cursor', () {
      expect(ResizeHandle.ratio.isRatio, isTrue);
      expect(ResizeHandle.ratio.isRadius, isFalse);
      expect(ResizeHandle.ratio.isCorner, isFalse);
      expect(ResizeHandle.ratio.isEdge, isFalse);

      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.ratio),
        SystemMouseCursors.precise,
      );
    });

    test('getRatioHandlePosition computes accurate inner vertex for star', () {
      final star = VectorShape(
        id: 'star-1',
        name: 'Star 1',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        innerRadiusRatio: 0.4,
        pointCount: 5,
      );

      final ratioPt = CanvasHitTester.getRatioHandlePosition(star);
      expect(ratioPt, isNotNull);

      // Star rect center is (200, 200), outer radius is 100
      // innerRadius = 100 * 0.4 = 40
      // angleStep = pi / 5; angle = angleStep - pi / 2
      final expectedAngle = (math.pi / 5) - (math.pi / 2);
      final expectedX = 200 + 40 * math.cos(expectedAngle);
      final expectedY = 200 + 40 * math.sin(expectedAngle);

      expect(ratioPt!.dx, closeTo(expectedX, 0.001));
      expect(ratioPt.dy, closeTo(expectedY, 0.001));

      // Returns null for non-star shapes
      final rectShape = VectorShape(
        id: 'rect-1',
        name: 'Rect',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
      );
      expect(CanvasHitTester.getRatioHandlePosition(rectShape), isNull);
    });

    test('getRadiusHandlePositions includes both radius and ratio handles for star', () {
      final star = VectorShape(
        id: 'star-1',
        name: 'Star',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        innerRadiusRatio: 0.5,
      );

      final handles = CanvasHitTester.getRadiusHandlePositions(star);
      expect(handles.containsKey(ResizeHandle.radiusTopLeft), isTrue);
      expect(handles.containsKey(ResizeHandle.ratio), isTrue);
    });

    test('CanvasHitTester.hitTestHandle accurately detects ratio handle', () {
      final star = VectorShape(
        id: 'star-1',
        name: 'Star',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        innerRadiusRatio: 0.5,
      );

      final ratioPt = CanvasHitTester.getRatioHandlePosition(star)!;
      final hitHandle = CanvasHitTester.hitTestHandle(ratioPt, star);
      expect(hitHandle, ResizeHandle.ratio);
    });
  });

  group('Interactive Workspace Star Ratio Handle Dragging', () {
    testWidgets(
      'Dragging ratio handle on star updates innerRadiusRatio smoothly',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );

        // Add a 5-point star
        final star = VectorShape(
          id: 'test-star',
          name: 'Interactive Star',
          type: ShapeType.star,
          rect: const Rect.fromLTWH(400, 300, 200, 200),
          innerRadiusRatio: 0.4,
          pointCount: 5,
        );

        state.shapes.add(star);
        state.selectShape(star.id);
        await tester.pumpAndSettle();

        expect(state.selectedShapeIds.contains('test-star'), isTrue);

        final containerFinder = find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 3200,
        );
        final RenderBox renderBox = tester.renderObject(containerFinder);

        final ratioLocalPos = CanvasHitTester.getRatioHandlePosition(star)!;
        final ratioGlobalPos = renderBox.localToGlobal(ratioLocalPos);

        // Start dragging ratio point
        final gesture = await tester.startGesture(ratioGlobalPos);
        await tester.pump();

        expect(state.activeResizeHandle, ResizeHandle.ratio);

        // Verify InteractiveCanvas isResizing is active
        final canvasWidget = tester.widget<InteractiveCanvas>(
          find.byType(InteractiveCanvas),
        );
        expect(canvasWidget.isResizing, isTrue);

        // Drag outwards away from center (center is 500, 400; drag outward by +30, -20)
        await gesture.moveBy(const Offset(30, -20));
        await tester.pump();

        // Ratio was increased
        expect(star.innerRadiusRatio, greaterThan(0.4));
        expect(star.innerRadiusRatio, lessThanOrEqualTo(0.95));

        await gesture.up();
        await tester.pumpAndSettle();

        expect(state.activeResizeHandle, ResizeHandle.none);
        expect(star.innerRadiusRatio, greaterThan(0.4));
      },
    );

    testWidgets(
      'Holding Shift while dragging ratio handle snaps in increments of 10%',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );

        final star = VectorShape(
          id: 'test-star-shift',
          name: 'Shift Star',
          type: ShapeType.star,
          rect: const Rect.fromLTWH(400, 300, 200, 200),
          innerRadiusRatio: 0.4,
          pointCount: 5,
        );

        state.shapes.add(star);
        state.selectShape(star.id);
        await tester.pumpAndSettle();

        final containerFinder = find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 3200,
        );
        final RenderBox renderBox = tester.renderObject(containerFinder);
        final ratioLocalPos = CanvasHitTester.getRatioHandlePosition(star)!;
        final ratioGlobalPos = renderBox.localToGlobal(ratioLocalPos);

        // Hold Shift down
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();

        final gesture = await tester.startGesture(ratioGlobalPos);
        await tester.pump();

        expect(state.activeResizeHandle, ResizeHandle.ratio);

        // Drag to somewhere that yields a snapped percentage (e.g. radius ~ 70 => 0.7)
        // Center is at (500, 400). Let's drag towards (500 + 70, 400) = (570, 400)
        final targetGlobal = renderBox.localToGlobal(const Offset(570, 400));
        await gesture.moveTo(targetGlobal);
        await tester.pump();

        // Must be cleanly snapped to a multiple of 0.1 (e.g. 0.70)
        final snappedStep = (star.innerRadiusRatio * 10).round();
        expect(
          star.innerRadiusRatio,
          closeTo(snappedStep / 10.0, 0.001),
        );

        await gesture.up();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();

        expect(state.activeResizeHandle, ResizeHandle.none);
      },
    );
  });
}
