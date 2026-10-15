import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';

void main() {
  group('Selection Area Live Hit-Testing Calculations', () {
    test('calculateMarqueeSelection returns only shapes currently overlapping the live marquee', () {
      final shapes = [
        VectorShape(
          id: 'shape-1',
          name: 'Box 1',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(50, 50, 100, 100),
        ),
        VectorShape(
          id: 'shape-2',
          name: 'Box 2',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(300, 50, 100, 100),
        ),
        VectorShape(
          id: 'shape-3',
          name: 'Box 3',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(600, 50, 100, 100),
        ),
      ];

      // 1. Marquee over Box 1 only
      final marquee1 = const Rect.fromLTWH(0, 0, 120, 120);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: marquee1,
          shapes: shapes,
        ),
        equals({'shape-1'}),
      );

      // 2. Marquee expands to include Box 1 and Box 2
      final marquee2 = const Rect.fromLTWH(0, 0, 350, 120);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: marquee2,
          shapes: shapes,
        ),
        equals({'shape-1', 'shape-2'}),
      );

      // 3. Selection area shifts live to only cover Box 2 (Box 1 is excluded)
      final marquee3 = const Rect.fromLTWH(250, 0, 200, 120);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: marquee3,
          shapes: shapes,
        ),
        equals({'shape-2'}),
      );

      // 4. Selection area over empty space selects nothing
      final marqueeEmpty = const Rect.fromLTWH(180, 0, 50, 50);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: marqueeEmpty,
          shapes: shapes,
        ),
        isEmpty,
      );

      // 5. Zero-size selection area (click without dragging) selects nothing
      final marqueeZero = const Rect.fromLTWH(75, 75, 0, 0);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: marqueeZero,
          shapes: shapes,
        ),
        isEmpty,
      );
    });

    test('calculateMarqueeSelection respects locked and hidden shapes', () {
      final shapes = [
        VectorShape(
          id: 'hidden-shape',
          name: 'Hidden',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(50, 50, 100, 100),
          isVisible: false,
        ),
        VectorShape(
          id: 'locked-shape',
          name: 'Locked',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(50, 50, 100, 100),
          isLocked: true,
        ),
        VectorShape(
          id: 'visible-unlocked',
          name: 'Normal',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(50, 50, 100, 100),
        ),
      ];

      final marquee = const Rect.fromLTWH(0, 0, 200, 200);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: marquee,
          shapes: shapes,
        ),
        equals({'visible-unlocked'}),
      );
    });

    test('calculateMarqueeSelection accurately accounts for rotated shape bounding boxes', () {
      // Shape centered at (200, 200), width=100, height=20.
      // Unrotated horizontal bounds: X in [150, 250], Y in [190, 210].
      // When rotated 90 degrees: vertical bounds: X in [190, 210], Y in [150, 250].
      final rotatedShape = VectorShape(
        id: 'rotated-shape',
        name: 'Rotated Bar',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(150, 190, 100, 20),
        rotation: 90.0,
      );

      // Marquee at top (Y in [140, 170], X in [180, 220]) intersects rotated shape,
      // but would NOT intersect unrotated rect.
      final topMarquee = const Rect.fromLTWH(180, 140, 40, 30);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: topMarquee,
          shapes: [rotatedShape],
        ),
        equals({'rotated-shape'}),
      );

      // Marquee far left (X in [140, 170], Y in [190, 210]) would intersect unrotated rect,
      // but does NOT intersect the 90-degree rotated shape!
      final leftMarquee = const Rect.fromLTWH(140, 190, 30, 20);
      expect(
        CanvasGeometry.calculateMarqueeSelection(
          marqueeRect: leftMarquee,
          shapes: [rotatedShape],
        ),
        isEmpty,
      );
    });
  });

  group('Interactive Live Selection Area UI in FigmaWorkspace', () {
    testWidgets('Live selection area only keeps currently intersected shapes during drag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const NixSvgApp());
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));

      // Reset shapes to 2 known rectangles on canvas
      state.shapes.clear();
      state.shapes.addAll([
        VectorShape(
          id: 'box-a',
          name: 'Box A',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(200, 200, 100, 100),
        ),
        VectorShape(
          id: 'box-b',
          name: 'Box B',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(500, 200, 100, 100),
        ),
      ]);
      state.selectedShapeIds.clear();
      await tester.pumpAndSettle();

      // Find canvas gesture surface
      final gestureFinder = find.byType(InteractiveCanvas);
      expect(gestureFinder, findsOneWidget);

      // Start drag at empty space (100, 100)
      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();

      // 1. Drag selection area to (350, 350) -> covers Box A
      await gesture.moveTo(const Offset(350, 350));
      await tester.pump();
      expect(state.selectedShapeIds, contains('box-a'));
      expect(state.selectedShapeIds, isNot(contains('box-b')));

      // 2. Drag selection area further to (650, 350) -> covers Box A and Box B
      await gesture.moveTo(const Offset(650, 350));
      await tester.pump();
      expect(state.selectedShapeIds, contains('box-a'));
      // 3. Shrink marquee to (150, 150) so it NO LONGER touches Box A or Box B
      await gesture.moveTo(const Offset(150, 150));
      await tester.pump();
      // Verifies the live selection area is strictly current (not sticky)
      expect(state.selectedShapeIds, isEmpty);

      // 4. Release gesture
      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.marqueeRect, isNull);
    });

    testWidgets('Holding Shift during marquee drag preserves initial selection while updating live marquee hits', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const NixSvgApp());
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));

      state.shapes.clear();
      state.shapes.addAll([
        VectorShape(
          id: 'box-a',
          name: 'Box A',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(200, 200, 100, 100),
        ),
        VectorShape(
          id: 'box-b',
          name: 'Box B',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(500, 200, 100, 100),
        ),
      ]);
      // Initially box-a is selected
      state.selectedShapeIds.clear();
      state.selectedShapeIds.add('box-a');
      await tester.pumpAndSettle();

      // Hold Shift
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      // Start drag at empty space (450, 150)
      final gesture = await tester.startGesture(const Offset(450, 150));
      await tester.pump();

      // Move into box-b: both box-a (from initial) and box-b (from live marquee) are selected
      await gesture.moveTo(const Offset(650, 350));
      await tester.pump();
      expect(state.selectedShapeIds, contains('box-a'));
      expect(state.selectedShapeIds, contains('box-b'));

      // Move away from box-b to empty space (460, 160): box-b is deselected live, box-a remains
      await gesture.moveTo(const Offset(460, 160));
      await tester.pump();
      expect(state.selectedShapeIds, contains('box-a'));
      expect(state.selectedShapeIds, isNot(contains('box-b')));

      await gesture.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(state.marqueeRect, isNull);
    });
  });
}
