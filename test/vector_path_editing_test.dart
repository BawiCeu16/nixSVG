import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';

void main() {
  group('Vector Path Node Model & Geometry Tests', () {
    test('getOrGeneratePathNodes extracts nodes when pathNodes is null', () {
      final path = Path()
        ..moveTo(20, 30)
        ..lineTo(100, 30)
        ..lineTo(100, 150)
        ..close();

      final shape = VectorShape(
        id: 'p1',
        name: 'Path 1',
        type: ShapeType.path,
        rect: const Rect.fromLTWH(20, 30, 80, 120),
        customPath: path,
        isClosed: true,
      );

      final nodes = shape.getOrGeneratePathNodes();
      expect(nodes.length, greaterThanOrEqualTo(2));
      expect(nodes.first.position, equals(const Offset(20, 30)));
    });

    test('getOrGeneratePathNodes generates endpoints for line shape', () {
      final lineShape = VectorShape(
        id: 'l1',
        name: 'Line 1',
        type: ShapeType.line,
        rect: const Rect.fromLTRB(50, 60, 200, 180),
      );

      final nodes = lineShape.getOrGeneratePathNodes();
      expect(nodes.length, equals(2));
      expect(nodes[0].position, equals(const Offset(50, 60)));
      expect(nodes[1].position, equals(const Offset(200, 180)));
    });

    test('updateFromPathNodes recalculates path, bounds and updates nodes', () {
      final nodes = [
        PathNode(position: const Offset(10, 10), isCorner: true),
        PathNode(position: const Offset(80, 120), isCorner: true),
      ];
      final shape = VectorShape(
        id: 'p1',
        name: 'Path 1',
        type: ShapeType.path,
        rect: const Rect.fromLTWH(0, 0, 50, 50),
        pathNodes: nodes,
      );

      final updatedNodes = [
        PathNode(position: const Offset(50, 50), isCorner: true),
        PathNode(
          position: const Offset(200, 250),
          isCorner: false,
          handleIn: const Offset(180, 240),
          handleOut: const Offset(220, 260),
        ),
      ];

      shape.updateFromPathNodes(updatedNodes, closed: false);

      expect(shape.pathNodes!.length, equals(2));
      expect(shape.pathNodes![0].position, equals(const Offset(50, 50)));
      expect(shape.pathNodes![1].position, equals(const Offset(200, 250)));
      expect(shape.rect.left, closeTo(50, 1.0));
      expect(shape.rect.top, closeTo(50, 1.0));
      expect(shape.customPath, isNotNull);
    });

    test('shiftPosition shifts rect, customPath and pathNodes simultaneously', () {
      final nodes = [
        PathNode(
          position: const Offset(100, 100),
          handleIn: const Offset(90, 90),
          handleOut: const Offset(110, 110),
        ),
        PathNode(position: const Offset(200, 200)),
      ];
      final shape = VectorShape(
        id: 'p1',
        name: 'Path 1',
        type: ShapeType.path,
        rect: const Rect.fromLTWH(100, 100, 100, 100),
        pathNodes: nodes,
      );

      const delta = Offset(25, -15);
      shape.shiftPosition(delta);

      expect(shape.rect.left, equals(125));
      expect(shape.rect.top, equals(85));
      expect(shape.pathNodes![0].position, equals(const Offset(125, 85)));
      expect(shape.pathNodes![0].handleIn, equals(const Offset(115, 75)));
      expect(shape.pathNodes![0].handleOut, equals(const Offset(135, 95)));
      expect(shape.pathNodes![1].position, equals(const Offset(225, 185)));
    });

    test('scaleNodes scales anchor points and handles proportionally', () {
      final nodes = [
        PathNode(position: const Offset(100, 100)),
        PathNode(position: const Offset(200, 200)),
      ];
      final shape = VectorShape(
        id: 'p1',
        name: 'Path 1',
        type: ShapeType.path,
        rect: const Rect.fromLTWH(100, 100, 100, 100),
        pathNodes: nodes,
      );

      // Scale to double width and double height
      shape.scaleNodes(
        const Rect.fromLTWH(100, 100, 100, 100),
        const Rect.fromLTWH(100, 100, 200, 200),
      );

      expect(shape.pathNodes![0].position, equals(const Offset(100, 100)));
      expect(shape.pathNodes![1].position, equals(const Offset(300, 300)));
    });

    test('hitTestPathNodes detects anchor points with zoom tolerance', () {
      final nodes = [
        PathNode(position: const Offset(50, 50)),
        PathNode(position: const Offset(200, 150)),
      ];

      expect(
        CanvasGeometry.hitTestPathNodes(
          const Offset(52, 53),
          nodes,
          zoomScale: 1.0,
        ),
        equals(0),
      );
      expect(
        CanvasGeometry.hitTestPathNodes(
          const Offset(199, 151),
          nodes,
          zoomScale: 1.0,
        ),
        equals(1),
      );
      expect(
        CanvasGeometry.hitTestPathNodes(
          const Offset(100, 100),
          nodes,
          zoomScale: 1.0,
        ),
        isNull,
      );
    });

    test('hitTestPathHandle detects handleIn and handleOut knobs', () {
      final node = PathNode(
        position: const Offset(100, 100),
        isCorner: false,
        handleIn: const Offset(60, 100),
        handleOut: const Offset(140, 100),
      );

      // Hit handleIn knob
      expect(
        CanvasGeometry.hitTestPathHandle(
          const Offset(62, 101),
          node,
          zoomScale: 1.0,
        ),
        equals(1),
      );

      // Hit handleOut knob
      expect(
        CanvasGeometry.hitTestPathHandle(
          const Offset(139, 99),
          node,
          zoomScale: 1.0,
        ),
        equals(2),
      );

      // Hit far away
      expect(
        CanvasGeometry.hitTestPathHandle(
          const Offset(100, 100),
          node,
          zoomScale: 1.0,
        ),
        equals(0),
      );
    });

    test('calculateDefaultTangent generates smooth collinear tangent', () {
      final nodes = [
        PathNode(position: const Offset(0, 0)),
        PathNode(position: const Offset(100, 0)),
        PathNode(position: const Offset(200, 0)),
      ];

      final tangent = CanvasGeometry.calculateDefaultTangent(nodes, 1);
      // Tangent along X axis
      expect(tangent.dy, closeTo(0, 0.01));
      expect(tangent.dx, greaterThan(0));
    });

    test('findNearestSegmentIndex finds curve segment for node insertion', () {
      final nodes = [
        PathNode(position: const Offset(0, 0)),
        PathNode(position: const Offset(100, 0)),
      ];

      final seg = CanvasGeometry.findNearestSegmentIndex(
        const Offset(50, 1),
        nodes,
        isClosed: false,
        zoomScale: 1.0,
      );
      expect(seg, equals(0));
    });
  });

  group('Vector Edit Mode Workspace Widget Tests', () {
    testWidgets('Double-clicking a path enters Vector Edit Mode and Done commits it', (tester) async {
      final testPath = Path()
        ..moveTo(300, 300)
        ..lineTo(450, 300)
        ..lineTo(450, 450);

      final initialPathShape = VectorShape(
        id: 'test-edit-path',
        name: 'Editable Path',
        type: ShapeType.path,
        rect: const Rect.fromLTWH(300, 300, 150, 150),
        customPath: testPath,
        pathNodes: [
          PathNode(position: const Offset(300, 300), isCorner: true),
          PathNode(position: const Offset(450, 300), isCorner: true),
          PathNode(position: const Offset(450, 450), isCorner: true),
        ],
        isStroked: true,
        strokeWidth: 3.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(useMaterial3: true),
            home: Scaffold(
              body: FigmaWorkspace(
                initialProject: ProjectModel(
                  id: 'test-proj',
                  name: 'Test Project',
                  lastModified: DateTime.now(),
                  shapes: [initialPathShape],
                  canvasSize: const Size(2000, 2000),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final canvasOrigin = tester.getTopLeft(find.byType(InteractiveCanvas));
      final targetScreenPoint = canvasOrigin + initialPathShape.rect.center;

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: targetScreenPoint);
      addTearDown(gesture.removePointer);

      // First click
      await gesture.down(targetScreenPoint);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));

      // Second click (within 350ms window)
      await gesture.down(targetScreenPoint);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify the Vector Edit Mode floating banner appears
      expect(find.text('Vector Edit Mode'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap "Done" button to finish and exit Vector Edit Mode
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify Vector Edit Mode floating banner disappears
      expect(find.text('Vector Edit Mode'), findsNothing);
    });
  });
}
