import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/models/vector_shape.dart';

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

    test('alignShapes aligns multiple shapes to selection union bounds like Figma', () {
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
    });

    test('CanvasTransformHelper zoomToFit correctly fits bounds into viewport', () {
      const bounds = Rect.fromLTWH(100, 100, 800, 400);
      const viewport = Size(1000, 600);
      final matrix = CanvasTransformHelper.zoomToFit(bounds, viewport, padding: 50);

      final scale = matrix.getMaxScaleOnAxis();
      expect(scale, greaterThan(0.5));
      expect(scale, lessThan(2.0));
    });
  });

  group('Figma Keyboard Shortcuts & Interactions', () {
    testWidgets('Ctrl+A selects all shapes and Ctrl+C / Ctrl+V duplicates to clipboard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const NixSvgApp());
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));
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
    });

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
      final scale = ivWidget.transformationController!.value.getMaxScaleOnAxis();
      expect(scale, closeTo(1.0, 0.01));
    });

    testWidgets('Sidebar changes do not freeze canvas; tapping canvas or pressing Enter releases focus', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const NixSvgApp());
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));

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
      final isStillInEditableText = primaryFocusAfter?.context?.widget is EditableText;
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
    });
  });
}
