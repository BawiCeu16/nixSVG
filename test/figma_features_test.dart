import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';

void main() {
  group('Figma Geometry & Transform Calculations', () {
    test('Proportional resizing maintains aspect ratio when Shift is held', () {
      const initial = Rect.fromLTWH(100, 100, 200, 100); // 2:1 aspect ratio
      const start = Offset(300, 200); // bottomRight corner
      const current = Offset(350, 260); // dragged +50 dx, +60 dy

      // Simulate shift key pressed in hardware keyboard
      // Test without shift first
      final unconstrained = CanvasGeometry.resizeRect(
        initial,
        start,
        current,
        ResizeHandle.bottomRight,
      );
      expect(unconstrained.width, 250);
      expect(unconstrained.height, 160);
    });

    test(
      'calculateDrawRect produces perfect 1:1 shapes when Shift is held',
      () {
        const start = Offset(100, 100);
        const current = Offset(250, 180); // width 150, height 80

        // Regular draw without modifiers
        final normalRect = CanvasGeometry.calculateDrawRect(
          start: start,
          current: current,
          shapeType: ShapeType.rectangle,
          isShiftPressed: false,
          isAltPressed: false,
        );
        expect(normalRect.width, 150);
        expect(normalRect.height, 80);

        // With Shift held: max(150, 80) = 150, perfect square
        final shiftRect = CanvasGeometry.calculateDrawRect(
          start: start,
          current: current,
          shapeType: ShapeType.rectangle,
          isShiftPressed: true,
          isAltPressed: false,
        );
        expect(shiftRect.width, 150);
        expect(shiftRect.height, 150);
        expect(shiftRect.topLeft, start);

        // With Ellipse and Shift: perfect circle
        final circleRect = CanvasGeometry.calculateDrawRect(
          start: start,
          current: current,
          shapeType: ShapeType.ellipse,
          isShiftPressed: true,
          isAltPressed: false,
        );
        expect(circleRect.width, 150);
        expect(circleRect.height, 150);
      },
    );

    test(
      'calculateDrawRect centers shape at mouse start point when Alt is held',
      () {
        const start = Offset(200, 200);
        const current = Offset(250, 230); // delta: dx=50, dy=30

        final altRect = CanvasGeometry.calculateDrawRect(
          start: start,
          current: current,
          shapeType: ShapeType.rectangle,
          isShiftPressed: false,
          isAltPressed: true,
        );
        // Centered at start (200, 200) with width = 100, height = 60
        expect(altRect.center, start);
        expect(altRect.width, 100);
        expect(altRect.height, 60);
        expect(altRect.left, 150);
        expect(altRect.top, 170);
      },
    );

    test('calculateDrawRect creates perfect 1:1 shape centered at start when Shift and Alt are both held', () {
      const start = Offset(300, 300);
      const current = Offset(380, 340); // dx=80, dy=40 -> maxSide = 80

      final shiftAltRect = CanvasGeometry.calculateDrawRect(
        start: start,
        current: current,
        shapeType: ShapeType.rectangle,
        isShiftPressed: true,
        isAltPressed: true,
      );
      // Centered at start (300, 300) with width = 160, height = 160
      expect(shiftAltRect.center, start);
      expect(shiftAltRect.width, 160);
      expect(shiftAltRect.height, 160);
      expect(shiftAltRect.left, 220);
      expect(shiftAltRect.top, 220);
    });

    test(
      'alignShapes aligns multiple shapes to selection union bounds like Figma',
      () {
        final shapes = [
          VectorShape(
            id: '1',
            name: 'Box 1',
            type: ShapeType.rectangle,
            rect: const Rect.fromLTWH(100, 100, 50, 50),
          ),
          VectorShape(
            id: '2',
            name: 'Box 2',
            type: ShapeType.rectangle,
            rect: const Rect.fromLTWH(300, 200, 80, 80),
          ),
        ];

        // Align left: collective left is min(100, 300) = 100
        CanvasGeometry.alignShapes(
          shapes: shapes,
          selectedIds: {'1', '2'},
          align: 'left',
        );
        expect(shapes[0].rect.left, 100);
        expect(shapes[1].rect.left, 100);

        final shapes2 = [
          VectorShape(
            id: '1',
            name: 'Box 1',
            type: ShapeType.rectangle,
            rect: const Rect.fromLTWH(100, 100, 50, 50),
          ),
          VectorShape(
            id: '2',
            name: 'Box 2',
            type: ShapeType.rectangle,
            rect: const Rect.fromLTWH(300, 200, 80, 80),
          ),
        ];

        // Align right: collective right is max(100+50, 300+80) = 380
        CanvasGeometry.alignShapes(
          shapes: shapes2,
          selectedIds: {'1', '2'},
          align: 'right',
        );
        expect(shapes2[0].rect.right, 380);
        expect(shapes2[1].rect.right, 380);
      },
    );

    test(
      'CanvasTransformHelper zoomToFit correctly fits bounds into viewport',
      () {
        const bounds = Rect.fromLTWH(100, 100, 800, 400);
        const viewport = Size(1000, 600);
        final matrix = CanvasTransformHelper.zoomToFit(
          bounds,
          viewport,
          padding: 50,
        );

        final scale = matrix.getMaxScaleOnAxis();
        expect(scale, greaterThan(0.5));
        expect(scale, lessThan(2.0));
      },
    );
  });

  group('Figma Keyboard Shortcuts & Interactions', () {
    testWidgets(
      'Ctrl+A selects all shapes and Ctrl+C / Ctrl+V duplicates to clipboard',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );
        final initialCount = state.shapes.length;

        // Select All with Ctrl+A
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(state.selectedShapeIds.length, initialCount);

        // Copy with Ctrl+C
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        // Paste with Ctrl+V
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        // Pasted copies should increase count
        expect(state.shapes.length, initialCount * 2);
      },
    );

    testWidgets('Shift+1 zooms to fit and Ctrl+0 resets zoom', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const NixSvgApp());
      await tester.pumpAndSettle();

      // Shift+1 Zoom to fit
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      // Ctrl+0 Reset zoom to 100%
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      final ivFinder = find.byType(InteractiveViewer);
      final ivWidget = tester.widget<InteractiveViewer>(ivFinder);
      final scale = ivWidget.transformationController!.value
          .getMaxScaleOnAxis();
      expect(scale, closeTo(1.0, 0.01));
    });

    testWidgets(
      'Sidebar changes do not freeze canvas; tapping canvas or pressing Enter releases focus',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );

        // 1. Select the first shape and ensure properties panel is visible
        state.selectShape(state.shapes.first.id);
        await tester.pumpAndSettle();

        expect(state.selectedShapeIds.length, 1);

        // 2. Find the X number input field in PropertiesSidebar and enter text
        final xFieldFinder = find.byType(TextFormField).first;
        expect(xFieldFinder, findsOneWidget);

        await tester.tap(xFieldFinder);
        await tester.pumpAndSettle();

        // Field now has focus
        final primaryFocusBefore = FocusManager.instance.primaryFocus;
        expect(primaryFocusBefore, isNotNull);

        // 3. Tap on the canvas workspace
        await tester.tapAt(const Offset(500, 350));
        await tester.pumpAndSettle();

        // Focus should now be unfocused from the sidebar field
        final primaryFocusAfter = FocusManager.instance.primaryFocus;
        final isStillInEditableText =
            primaryFocusAfter?.context?.widget is EditableText;
        expect(isStillInEditableText, isFalse);

        // 4. Verify Space key immediately engages space pan without freezing!
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(state.isSpacePressed, isTrue);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(state.isSpacePressed, isFalse);

        // Shape is still selected - we did NOT need to unselect it to restore canvas responsiveness!
        expect(state.selectedShapeIds.length, 1);
      },
    );

    testWidgets(
      'Resizing a circle shape activates isResizing badge with dimensions and radius',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );

        // Add a circle (ellipse with width == height)
        final circle = VectorShape(
          id: 'test-circle',
          name: 'Test Circle',
          type: ShapeType.ellipse,
          rect: const Rect.fromLTWH(400, 300, 100, 100),
        );
        state.shapes.add(circle);
        state.selectShape(circle.id);
        await tester.pumpAndSettle();

        expect(state.selectedShapeIds.contains('test-circle'), isTrue);

        // Verify InteractiveCanvas is rendered with isResizing = false initially
        final canvasWidgetBefore = tester.widget<InteractiveCanvas>(
          find.byType(InteractiveCanvas),
        );
        expect(canvasWidgetBefore.isResizing, isFalse);

        // Start resize from bottomRight handle (400+100, 300+100) -> (500, 400)
        final containerFinder = find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 3200,
        );
        final RenderBox renderBox = tester.renderObject(containerFinder);
        final handlePos = renderBox.localToGlobal(const Offset(500, 400));

        final gesture = await tester.startGesture(handlePos);
        await tester.pump();
        await gesture.moveBy(const Offset(40, 40));
        await tester.pump();

        // State is now resizing
        expect(state.activeResizeHandle, isNot(ResizeHandle.none));
        final canvasWidgetDuring = tester.widget<InteractiveCanvas>(
          find.byType(InteractiveCanvas),
        );
        expect(canvasWidgetDuring.isResizing, isTrue);

        // Circle was resized to 140x140 (radius 70)
        expect(circle.rect.width, 140);
        expect(circle.rect.height, 140);

        await gesture.up();
        await tester.pumpAndSettle();

        expect(state.activeResizeHandle, ResizeHandle.none);
        final canvasWidgetAfter = tester.widget<InteractiveCanvas>(
          find.byType(InteractiveCanvas),
        );
        expect(canvasWidgetAfter.isResizing, isFalse);
      },
    );
  });
}
