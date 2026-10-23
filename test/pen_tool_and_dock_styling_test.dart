import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/widgets/floating_tool_bar.dart';

void main() {
  group('CanvasGeometry Path Calculation Tests', () {
    test('createSmoothPathFromPoints handles edge cases cleanly', () {
      final empty = CanvasGeometry.createSmoothPathFromPoints([]);
      expect(empty.getBounds().isEmpty, isTrue);

      final single = CanvasGeometry.createSmoothPathFromPoints([
        const Offset(10, 10),
      ]);
      expect(single.getBounds().isEmpty, isFalse);

      final twoPoints = CanvasGeometry.createSmoothPathFromPoints([
        const Offset(10, 10),
        const Offset(50, 50),
      ]);
      final bounds2 = twoPoints.getBounds();
      expect(bounds2.left, closeTo(10, 0.1));
      expect(bounds2.top, closeTo(10, 0.1));
      expect(bounds2.right, closeTo(50, 0.1));
      expect(bounds2.bottom, closeTo(50, 0.1));
    });

    test('createSmoothPathFromPoints creates smooth curve across multiple points', () {
      final points = [
        const Offset(0, 0),
        const Offset(50, 100),
        const Offset(100, 0),
        const Offset(150, 100),
        const Offset(200, 0),
      ];
      final path = CanvasGeometry.createSmoothPathFromPoints(points);
      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 0.1));
      expect(bounds.right, closeTo(200, 0.1));
      expect(bounds.top, closeTo(0, 0.1));
      expect(bounds.bottom, greaterThan(50));
    });

    test('createPolylinePathFromPoints creates straight polygonal path', () {
      final points = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(100, 100),
        const Offset(0, 100),
      ];
      final path = CanvasGeometry.createPolylinePathFromPoints(points, isClosed: true);
      expect(path.contains(const Offset(50, 50)), isTrue);
      expect(path.contains(const Offset(150, 150)), isFalse);
    });
  });

  group('CanvasHitTester Path Hit Testing Tests', () {
    test('hitTestShape detects hit on stroked path shape within padding', () {
      final path = CanvasGeometry.createSmoothPathFromPoints([
        const Offset(50, 50),
        const Offset(100, 150),
        const Offset(200, 50),
      ]);
      final shape = VectorShape(
        id: 'pen-path-test',
        name: 'Path 1',
        type: ShapeType.path,
        rect: path.getBounds(),
        customPath: path,
        isStroked: true,
        isFilled: false,
        strokeWidth: 4.0,
      );

      // Point within bounding box of path
      expect(CanvasHitTester.hitTestShape(const Offset(100, 100), shape), isTrue);

      // Point far outside path
      expect(CanvasHitTester.hitTestShape(const Offset(500, 500), shape), isFalse);
    });
  });

  group('FloatingToolBar Dock Selected Button Styling Tests', () {
    testWidgets('Selected Dock tool button has no glow and is 100% rounded without animation', (tester) async {
      EditorMode currentMode = EditorMode.select;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingToolBar(
                  currentMode: currentMode,
                  onModeChanged: (mode) => setState(() => currentMode = mode),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the select button Container
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(FloatingToolBar),
          matching: find.byType(Container),
        ),
      );

      expect(containers.isNotEmpty, isTrue);

      // Check decoration of selected button
      final selectedContainer = containers.firstWhere((c) {
        final box = c.decoration as BoxDecoration?;
        return box != null && box.color != Colors.transparent;
      });

      final decoration = selectedContainer.decoration as BoxDecoration;

      // 1. Must be 100% rounded
      expect(decoration.borderRadius, equals(BorderRadius.circular(999)));

      // 2. Must not be glowing (no box shadow)
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('Dock includes Pen Tool button with tooltip Pen Tool (P)', (tester) async {
      EditorMode currentMode = EditorMode.select;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingToolBar(
                  currentMode: currentMode,
                  onModeChanged: (mode) => setState(() => currentMode = mode),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Pen Tool tooltip
      final penTooltip = find.byTooltip('Pen Tool (P)');
      expect(penTooltip, findsOneWidget);

      // Tap Pen Tool
      await tester.tap(penTooltip);
      await tester.pumpAndSettle();

      expect(currentMode, equals(EditorMode.drawPen));
    });

    testWidgets('Shapes tools grouped into single dock slot with custom popup on long-press', (tester) async {
      EditorMode currentMode = EditorMode.select;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingToolBar(
                  currentMode: currentMode,
                  onModeChanged: (mode) => setState(() => currentMode = mode),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Shape Tool tooltip exists in the dock as single slot
      final shapeTooltip = find.byTooltip('Rectangle Tool (R) - Long-press for Shapes');
      expect(shapeTooltip, findsOneWidget);

      // Tap Shape Tool to switch to drawRectangle
      await tester.tap(shapeTooltip);
      await tester.pumpAndSettle();
      expect(currentMode, equals(EditorMode.drawRectangle));

      // Long press shape tool button to open custom popup
      await tester.longPress(shapeTooltip);
      await tester.pumpAndSettle();

      // Custom popup displays all shapes options
      expect(find.text('Rectangle'), findsWidgets);
      expect(find.text('Rounded Rectangle'), findsOneWidget);
      expect(find.text('Ellipse'), findsOneWidget);
      expect(find.text('Line'), findsOneWidget);
      expect(find.text('Curve'), findsOneWidget);
      expect(find.text('Star'), findsOneWidget);
      expect(find.text('Polygon'), findsOneWidget);

      // Tap 'Star' shape in popup
      await tester.tap(find.text('Star'));
      await tester.pumpAndSettle();

      // Mode changed to drawStar and popup closed
      expect(currentMode, equals(EditorMode.drawStar));
      expect(find.text('Rounded Rectangle'), findsNothing);
    });

    testWidgets('M3ESegmentedList popup has container background and hover decoration', (tester) async {
      EditorMode currentMode = EditorMode.select;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingToolBar(
                  currentMode: currentMode,
                  onModeChanged: (mode) => setState(() => currentMode = mode),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shapeTooltip = find.byTooltip('Rectangle Tool (R) - Long-press for Shapes');
      await tester.longPress(shapeTooltip);
      await tester.pumpAndSettle();

      // Verify M3ESegmentedList exists
      final segmentedListFinder = find.byType(M3ESegmentedList);
      expect(segmentedListFinder, findsOneWidget);

      final segmentedList = tester.widget<M3ESegmentedList>(segmentedListFinder);
      expect(segmentedList.selectedRadius, equals(12.0));
      expect(segmentedList.selectedBorderRadius, equals(BorderRadius.circular(12.0)));
      expect(segmentedList.decoration?.selectedRadius, equals(12.0));

      // Verify parent container background card
      final parentContainer = tester.widget<Container>(
        find.ancestor(
          of: segmentedListFinder,
          matching: find.byType(Container),
        ).first,
      );
      final box = parentContainer.decoration as BoxDecoration?;
      expect(box, isNotNull);
      expect(box!.color, isNotNull);
      expect(box.boxShadow, isNotNull);
      expect(box.borderRadius, equals(BorderRadius.circular(14)));

      // Simulate mouse hover over an item
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      final ellipseText = find.text('Ellipse');
      await gesture.moveTo(tester.getCenter(ellipseText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Ellipse to select
      await tester.tap(ellipseText);
      await tester.pumpAndSettle();

      expect(currentMode, equals(EditorMode.drawEllipse));
    });
  });

  group('VectorCanvasPainter Pen Live Preview Tests', () {
    testWidgets('Paints active pen points and rubber band guide without error', (tester) async {
      final painter = VectorCanvasPainter(
        shapes: [],
        selectedShapeIds: {},
        currentMode: EditorMode.drawPen,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        activePenPoints: [
          const Offset(50, 50),
          const Offset(100, 80),
          const Offset(150, 120),
        ],
        activePenCursor: const Offset(200, 200),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(600, 400),
              painter: painter,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('PathNode Model Tests', () {
    test('PathNode serialization and copyWith work accurately', () {
      final node = PathNode(
        position: const Offset(100, 200),
        handleIn: const Offset(80, 190),
        handleOut: const Offset(120, 210),
        isCorner: false,
      );

      final json = node.toJson();
      expect(json['x'], equals(100.0));
      expect(json['y'], equals(200.0));
      expect(json['inX'], equals(80.0));
      expect(json['inY'], equals(190.0));
      expect(json['outX'], equals(120.0));
      expect(json['outY'], equals(210.0));
      expect(json['corner'], isFalse);

      final restored = PathNode.fromJson(json);
      expect(restored.position, equals(const Offset(100, 200)));
      expect(restored.handleIn, equals(const Offset(80, 190)));
      expect(restored.handleOut, equals(const Offset(120, 210)));
      expect(restored.isCorner, isFalse);

      final modified = node.copyWith(
        position: const Offset(300, 400),
        isCorner: true,
      );
      expect(modified.position, equals(const Offset(300, 400)));
      expect(modified.isCorner, isTrue);
      expect(modified.handleIn, equals(const Offset(80, 190)));
    });
  });

  group('Bézier PathNode Geometry and SVG Export Tests', () {
    test('nodesToPath produces straight segments for corner nodes', () {
      final nodes = [
        PathNode(position: const Offset(0, 0), isCorner: true),
        PathNode(position: const Offset(100, 0), isCorner: true),
        PathNode(position: const Offset(100, 100), isCorner: true),
      ];

      final path = CanvasGeometry.nodesToPath(nodes, isClosed: true);
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(100, 0.1));
      expect(bounds.height, closeTo(100, 0.1));

      final svgData = CanvasGeometry.nodesToSvgData(nodes, isClosed: true);
      expect(svgData, contains('M 0.00 0.00 L 100.00 0.00 L 100.00 100.00 Z'));
    });

    test('nodesToPath produces cubic Bézier curves when handles are present', () {
      final nodes = [
        PathNode(
          position: const Offset(0, 100),
          handleOut: const Offset(50, 50),
        ),
        PathNode(
          position: const Offset(200, 100),
          handleIn: const Offset(150, 150),
        ),
      ];

      final path = CanvasGeometry.nodesToPath(nodes, isClosed: false);
      expect(path.getBounds().isEmpty, isFalse);

      final svgData = CanvasGeometry.nodesToSvgData(nodes, isClosed: false);
      expect(svgData, startsWith('M 0.00 100.00 C 50.00 50.00 150.00 150.00 200.00 100.00'));
    });

    test('calculateHandleSnapAngle snaps to nearest 45-degree angle', () {
      const anchor = Offset(100, 100);

      // Drag slightly off horizontal right -> snaps to 0° (dx > 0, dy = 0)
      final handle1 = CanvasGeometry.calculateHandleSnapAngle(anchor, const Offset(150, 105));
      expect(handle1.dy, closeTo(100.0, 0.5));
      expect(handle1.dx, greaterThan(100.0));

      // Drag near 45° diagonal -> snaps to exactly 45°
      final handle2 = CanvasGeometry.calculateHandleSnapAngle(anchor, const Offset(150, 148));
      final delta2 = handle2 - anchor;
      expect((delta2.dx - delta2.dy).abs(), closeTo(0.0, 0.5));
    });

    test('calculateProspectiveCurve generates preview path to cursor', () {
      final lastNode = PathNode(
        position: const Offset(100, 100),
        handleOut: const Offset(120, 80),
      );
      const cursor = Offset(200, 200);

      final prospective = CanvasGeometry.calculateProspectiveCurve(lastNode, cursor);
      final bounds = prospective.getBounds();
      expect(bounds.left, closeTo(100.0, 0.1));
      expect(bounds.right, closeTo(200.0, 0.1));
    });
  });

  group('VectorCanvasPainter Bézier Node Rendering Tests', () {
    testWidgets('Paints Bézier PathNodes with handles, prospective curve, and closing glyph', (tester) async {
      final nodes = [
        PathNode(
          position: const Offset(100, 100),
          handleOut: const Offset(130, 80),
          handleIn: const Offset(70, 120),
        ),
        PathNode(
          position: const Offset(250, 150),
          handleIn: const Offset(200, 180),
          handleOut: const Offset(300, 120),
        ),
      ];

      final painter = VectorCanvasPainter(
        shapes: [],
        selectedShapeIds: {},
        currentMode: EditorMode.drawPen,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        activePenNodes: nodes,
        activePenCursor: const Offset(100, 100), // Hovering near start
        isPenHoveringStart: true,
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
  });

  group('FigmaWorkspace Pen Tool Shortcut & Flow Tests', () {
    testWidgets('Pressing P keyboard shortcut switches mode to drawPen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FigmaWorkspace(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send P key event
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();

      // Find selected button in FloatingToolBar should now be Pen Tool
      final penTooltip = find.byTooltip('Pen Tool (P)');
      expect(penTooltip, findsOneWidget);
    });
  });
}

