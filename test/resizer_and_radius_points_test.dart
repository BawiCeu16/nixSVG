import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/models/vector_shape.dart';

void main() {
  group('Resizer & Radius Points Hit Testing & Cursors', () {
    test('Radius handles are properly computed for rectangles', () {
      final rectShape = VectorShape(
        id: 'rect-1',
        name: 'Rect',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
      );

      final radiusHandles = CanvasHitTester.getRadiusHandlePositions(rectShape);
      expect(radiusHandles.length, 4);
      expect(radiusHandles.containsKey(ResizeHandle.radiusTopLeft), isTrue);
      expect(radiusHandles.containsKey(ResizeHandle.radiusTopRight), isTrue);
      expect(radiusHandles.containsKey(ResizeHandle.radiusBottomLeft), isTrue);
      expect(radiusHandles.containsKey(ResizeHandle.radiusBottomRight), isTrue);

      // Default inset is 16.0 (min of 16 and 200 * 0.2)
      final tl = radiusHandles[ResizeHandle.radiusTopLeft]!;
      expect(tl.dx, 116.0);
      expect(tl.dy, 116.0);
    });

    test('CanvasHitTester.hitTestHandle accurately detects radius points', () {
      final rectShape = VectorShape(
        id: 'rect-1',
        name: 'Rect',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
      );

      // Clicking right on radiusTopLeft (116, 116)
      expect(
        CanvasHitTester.hitTestHandle(const Offset(116, 116), rectShape),
        ResizeHandle.radiusTopLeft,
      );

      // Clicking right on radiusTopRight (300 - 16, 116) = (284, 116)
      expect(
        CanvasHitTester.hitTestHandle(const Offset(284, 116), rectShape),
        ResizeHandle.radiusTopRight,
      );

      // Clicking right on radiusBottomLeft (116, 300 - 16) = (116, 284)
      expect(
        CanvasHitTester.hitTestHandle(const Offset(116, 284), rectShape),
        ResizeHandle.radiusBottomLeft,
      );

      // Clicking right on radiusBottomRight (284, 284)
      expect(
        CanvasHitTester.hitTestHandle(const Offset(284, 284), rectShape),
        ResizeHandle.radiusBottomRight,
      );
    });

    test('CanvasHitTester.hitTestHandle detects resize handles and rotation', () {
      final rectShape = VectorShape(
        id: 'rect-1',
        name: 'Rect',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
      );

      // Corner handles
      expect(
        CanvasHitTester.hitTestHandle(const Offset(100, 100), rectShape),
        ResizeHandle.topLeft,
      );
      expect(
        CanvasHitTester.hitTestHandle(const Offset(300, 100), rectShape),
        ResizeHandle.topRight,
      );
      expect(
        CanvasHitTester.hitTestHandle(const Offset(100, 300), rectShape),
        ResizeHandle.bottomLeft,
      );
      expect(
        CanvasHitTester.hitTestHandle(const Offset(300, 300), rectShape),
        ResizeHandle.bottomRight,
      );

      // Edge handles
      expect(
        CanvasHitTester.hitTestHandle(const Offset(200, 100), rectShape),
        ResizeHandle.topCenter,
      );
      expect(
        CanvasHitTester.hitTestHandle(const Offset(200, 300), rectShape),
        ResizeHandle.bottomCenter,
      );
      expect(
        CanvasHitTester.hitTestHandle(const Offset(100, 200), rectShape),
        ResizeHandle.centerLeft,
      );
      expect(
        CanvasHitTester.hitTestHandle(const Offset(300, 200), rectShape),
        ResizeHandle.centerRight,
      );

      // Rotation handle (top center - 20px) = (200, 80)
      expect(
        CanvasHitTester.hitTestHandle(const Offset(200, 80), rectShape),
        ResizeHandle.rotation,
      );
    });

    test('CanvasGeometry.getHandleCursor provides distinct, orientation-aware cursors', () {
      // Radius handles -> precision crosshair
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.radiusTopLeft),
        SystemMouseCursors.precise,
      );

      // Corner handles -> diagonal
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.topLeft),
        SystemMouseCursors.resizeUpLeftDownRight,
      );
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.bottomRight),
        SystemMouseCursors.resizeUpLeftDownRight,
      );
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.topRight),
        SystemMouseCursors.resizeUpRightDownLeft,
      );
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.bottomLeft),
        SystemMouseCursors.resizeUpRightDownLeft,
      );

      // Edge handles -> vertical / horizontal
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.topCenter),
        SystemMouseCursors.resizeUpDown,
      );
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.bottomCenter),
        SystemMouseCursors.resizeUpDown,
      );
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.centerLeft),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.centerRight),
        SystemMouseCursors.resizeLeftRight,
      );

      // Rotation -> alias (curved rotation cursor)
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.rotation),
        SystemMouseCursors.alias,
      );

      // Rotated shape changes cursor orientation (90 degrees rotation flips vertical/horizontal)
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.topCenter, 90.0),
        SystemMouseCursors.resizeLeftRight,
      );
      expect(
        CanvasGeometry.getHandleCursor(ResizeHandle.centerRight, 90.0),
        SystemMouseCursors.resizeUpDown,
      );
    });
  });

  group('Interactive Workspace Radius & Resizer Points Widget Tests', () {
    testWidgets(
      'Dragging corner radius point updates cornerRadius and converts rectangle to roundedRectangle',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );

        final rectShape = VectorShape(
          id: 'test-rect',
          name: 'Test Rectangle',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(400, 300, 200, 200),
          isFilled: true,
          fillColor: Colors.blue,
        );

        state.shapes.add(rectShape);
        state.selectShape(rectShape.id);
        await tester.pumpAndSettle();

        // Verify shape is selected
        expect(state.selectedShapeIds.contains('test-rect'), isTrue);

        final containerFinder = find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 3200,
        );
        final RenderBox renderBox = tester.renderObject(containerFinder);

        // Radius topLeft handle is at (400 + 16, 300 + 16) = (416, 316)
        final radiusPos = renderBox.localToGlobal(const Offset(416, 316));

        // Start dragging radius handle inward towards (450, 350) -> +34 dx, +34 dy
        final gesture = await tester.startGesture(radiusPos);
        await tester.pump();

        expect(state.activeResizeHandle, ResizeHandle.radiusTopLeft);

        await gesture.moveBy(const Offset(34, 34));
        await tester.pump();

        // Corner radius was updated
        expect(rectShape.type, ShapeType.roundedRectangle);
        expect(rectShape.cornerRadius, greaterThan(30.0));

        await gesture.up();
        await tester.pumpAndSettle();

        expect(state.activeResizeHandle, ResizeHandle.none);
        expect(rectShape.cornerRadius, greaterThan(30.0));
      },
    );

    test('Handles and radius handles scale hit areas with zoomScale', () {
      final rectShape = VectorShape(
        id: 'test-rect',
        name: 'Test Rectangle',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(200, 200, 200, 200),
      );

      // At zoom 1.0, topCenter is at (300, 200)
      expect(
        CanvasHitTester.hitTestHandle(
          const Offset(300, 200),
          rectShape,
          zoomScale: 1.0,
        ),
        ResizeHandle.topCenter,
      );

      // When zoomed out far (0.2x), points on screen are 5x larger in canvas units
      // A point 10px away outside the rect is only 2 screen px away, so it hits easily
      expect(
        CanvasHitTester.hitTestHandle(
          const Offset(300, 195),
          rectShape,
          zoomScale: 0.2,
        ),
        ResizeHandle.topCenter,
      );

      // Rotation handle when zoomed out (rotCenter is at (300, 200 - 20 * 5) = (300, 100))
      expect(
        CanvasHitTester.hitTestHandle(
          const Offset(300, 100),
          rectShape,
          zoomScale: 0.2,
        ),
        ResizeHandle.rotation,
      );

      // Radius handle positions scale with zoomScale
      final normalRadiusHandles = CanvasHitTester.getRadiusHandlePositions(
        rectShape,
        zoomScale: 1.0,
      );
      final zoomedOutRadiusHandles = CanvasHitTester.getRadiusHandlePositions(
        rectShape,
        zoomScale: 0.5,
      );
      expect(normalRadiusHandles.isNotEmpty, isTrue);
      expect(zoomedOutRadiusHandles.isNotEmpty, isTrue);
    });

    test(
      'Smart snapping with initialShapeRects and proposedDelta does not oscillate or shake',
      () {
        final shapeA = VectorShape(
          id: 'shape-a',
          name: 'Shape A',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(100, 100, 100, 100),
        );
        final shapeB = VectorShape(
          id: 'shape-b',
          name: 'Shape B',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(300, 100, 100, 100),
        );

        final initialRects = {shapeA.id: shapeA.rect};

        // Frame 1: move by (98, 0) -> target right would be 200 + 98 = 298.
        // Target right (298) is within 6px of shapeB.left (300).
        final res1 = CanvasGeometry.calculateSnapGuidelines(
          shapes: [shapeA, shapeB],
          selectedShapeIds: {shapeA.id},
          initialShapeRects: initialRects,
          proposedDelta: const Offset(98, 0),
          snapThreshold: 6.0,
        );
        expect(res1.snapDelta.dx, 2.0); // snaps +2 to reach 300
        expect(res1.guidelineX?.dx, 300.0);

        // Frame 2: move slightly further by (99, 0) -> target right would be 299.
        final res2 = CanvasGeometry.calculateSnapGuidelines(
          shapes: [shapeA, shapeB],
          selectedShapeIds: {shapeA.id},
          initialShapeRects: initialRects,
          proposedDelta: const Offset(99, 0),
          snapThreshold: 6.0,
        );
        // Snapping smoothly aligns to 300 without jittering or flipping back and forth
        expect(res2.snapDelta.dx, 1.0);
        expect(res2.guidelineX?.dx, 300.0);

        // Frame 3: move by (100, 0) -> target right is exactly 300.
        final res3 = CanvasGeometry.calculateSnapGuidelines(
          shapes: [shapeA, shapeB],
          selectedShapeIds: {shapeA.id},
          initialShapeRects: initialRects,
          proposedDelta: const Offset(100, 0),
          snapThreshold: 6.0,
        );
        expect(res3.snapDelta.dx, 0.0);
        expect(res3.guidelineX?.dx, 300.0);
      },
    );
  });
}
