import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Canvas Deletion and Background Inspector Tests', () {
    test('VectorCanvasPainter.shouldRepaint always returns true for responsive canvas', () {
      final shapes = [
        VectorShape(
          id: 'test-1',
          name: 'Rect 1',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(10, 10, 100, 100),
        ),
      ];
      final painter1 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {'test-1'},
        colorScheme: const ColorScheme.light(),
        currentMode: EditorMode.select,
      );
      final painter2 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {},
        colorScheme: const ColorScheme.light(),
        currentMode: EditorMode.select,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    testWidgets('Deleting an element immediately removes it without pressing canvas blank', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Add a test shape
      final shape = VectorShape(
        id: 'del-test-shape',
        name: 'Delete Target',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(300, 300, 120, 120),
      );
      state.shapes.add(shape);
      state.selectShape(shape.id);
      await tester.pumpAndSettle();

      expect(state.selectedShapeIds.contains('del-test-shape'), isTrue);
      expect(state.shapes.any((s) => s.id == 'del-test-shape'), isTrue);

      // Delete via deleteSelected
      state.deleteSelected();
      await tester.pump();

      // Shape is removed immediately
      expect(state.shapes.any((s) => s.id == 'del-test-shape'), isFalse);
      expect(state.selectedShapeIds.isEmpty, isTrue);

      // Verify canvas painter receives the updated shapes list
      final canvasWidget = tester.widget<InteractiveCanvas>(
        find.byType(InteractiveCanvas),
      );
      expect(canvasWidget.shapes.any((s) => s.id == 'del-test-shape'), isFalse);
    });

    testWidgets('PropertiesSidebar displays Page / Canvas Inspector when nothing is selected', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Ensure properties panel is open
      state.isPropertiesPanelOpen = true;
      state.clearSelection();
      await tester.pumpAndSettle();

      // Verify Canvas Background Inspector is shown with clean sections
      expect(find.text('PAGE / CANVAS'), findsOneWidget);
      expect(find.text('TOOL & NAVIGATION'), findsOneWidget);
      expect(find.text('ZOOM CONTROLS'), findsOneWidget);
      expect(find.text('Canvas Background'), findsOneWidget);
      expect(find.text('Grid & Snapping'), findsOneWidget);
      expect(find.text('CANVAS ACTIONS'), findsNothing);
      expect(find.text('Select (V)'), findsOneWidget);
      expect(find.text('Move (H)'), findsOneWidget);

      // Verify Select All button is enabled when shapes exist (3 sample shapes)
      expect(find.byTooltip('Select All (Ctrl+A)'), findsOneWidget);

      // Clear all shapes and verify Select All button becomes disabled
      state.shapes.clear();
      state.clearSelection();
      await tester.pumpAndSettle();

      final selectAllFinder = find.byTooltip('No layers to select');
      expect(selectAllFinder, findsOneWidget);
    });

    testWidgets('Changing canvas background color updates the canvas background container', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Change canvas background to Dark Slate
      const newCanvasColor = Color(0xFF1E1E1E);
      state.setCanvasBackgroundColor(newCanvasColor);
      await tester.pumpAndSettle();

      expect(state.canvasBackgroundColor, equals(newCanvasColor));

      final canvasWidget = tester.widget<InteractiveCanvas>(
        find.byType(InteractiveCanvas),
      );
      expect(canvasWidget.canvasBackgroundColor, equals(newCanvasColor));
    });

    testWidgets('Canvas zoom in, zoom out, reset, and center update viewport transform', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      state.resetZoom();
      await tester.pumpAndSettle();

      // Initial scale is 1.0
      state.zoomIn();
      await tester.pump();
      final canvasWidgetZoomedIn = tester.widget<InteractiveCanvas>(
        find.byType(InteractiveCanvas),
      );
      final scaleIn = canvasWidgetZoomedIn.transformationController.value.getMaxScaleOnAxis();
      expect(scaleIn, greaterThan(1.0));

      state.zoomOut();
      await tester.pump();
      final canvasWidgetZoomedOut = tester.widget<InteractiveCanvas>(
        find.byType(InteractiveCanvas),
      );
      final scaleOut = canvasWidgetZoomedOut.transformationController.value.getMaxScaleOnAxis();
      expect(scaleOut, lessThan(scaleIn));

      // Reset Zoom
      state.resetZoom();
      await tester.pump();
      final canvasWidgetReset = tester.widget<InteractiveCanvas>(
        find.byType(InteractiveCanvas),
      );
      expect(canvasWidgetReset.transformationController.value.getMaxScaleOnAxis(), closeTo(1.0, 0.001));

      // Center Canvas
      state.centerCanvas();
      await tester.pump();
      expect(state.mounted, isTrue);
    });

    testWidgets('Toggling Pan / Move mode switches between select and pan', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      expect(state.currentMode, equals(EditorMode.select));

      state.togglePanMode();
      await tester.pump();
      expect(state.currentMode, equals(EditorMode.pan));

      state.togglePanMode();
      await tester.pump();
      expect(state.currentMode, equals(EditorMode.select));
    });

    testWidgets('Clear canvas removes all shapes and clears selection', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      state.shapes.add(
        VectorShape(
          id: 'shape-to-clear',
          name: 'Clear Target',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(100, 100, 50, 50),
        ),
      );
      state.selectShape('shape-to-clear');
      await tester.pump();

      expect(state.shapes.isNotEmpty, isTrue);
      expect(state.selectedShapeIds.isNotEmpty, isTrue);

      state.clearCanvas();
      await tester.pump();

      expect(state.shapes.isEmpty, isTrue);
      expect(state.selectedShapeIds.isEmpty, isTrue);
    });

    testWidgets('Panning and zooming works outside the canvas on background pasteboard', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Translate canvas so (350, 200) is far outside canvas bounds in negative space
      final m = Matrix4.identity();
      m.storage[12] = 500.0;
      m.storage[13] = 400.0;
      final canvasWidget = tester.widget<InteractiveCanvas>(
        find.byType(InteractiveCanvas),
      );
      canvasWidget.transformationController.value = m;
      await tester.pumpAndSettle();

      // Switch to Pan Mode (H)
      state.currentMode = EditorMode.pan;
      await tester.pump();

      final initialTx = canvasWidget.transformationController.value.storage[12];
      final initialTy = canvasWidget.transformationController.value.storage[13];

      // Drag on outside background pasteboard at (350, 200)
      final gesture = await tester.startGesture(const Offset(350, 200));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 30));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Panning must update viewport matrix translation
      final newTx = canvasWidget.transformationController.value.storage[12];
      final newTy = canvasWidget.transformationController.value.storage[13];
      expect(newTx, equals(initialTx + 40));
      expect(newTy, equals(initialTy + 30));

      // Scroll zoom outside canvas bounds on pasteboard
      final initialScale = canvasWidget.transformationController.value.getMaxScaleOnAxis();
      // Simulate trackpad or wheel zoom at outside pasteboard point
      canvasWidget.transformationController.value = CanvasTransformHelper.scrollZoom(
        canvasWidget.transformationController.value,
        const Offset(100, 100),
        1.15,
      );
      await tester.pump();
      final zoomedScale = canvasWidget.transformationController.value.getMaxScaleOnAxis();
      expect(zoomedScale, greaterThan(initialScale));
    });

    testWidgets('Editable hex input and grid spacing M3EToggleButtonGroup update workspace state', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FigmaWorkspace(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Open properties panel and clear selection for Canvas Inspector
      state.isPropertiesPanelOpen = true;
      state.clearSelection();
      await tester.pumpAndSettle();

      // Test Grid Spacing toggle button (tap '20')
      final grid20Finder = find.widgetWithText(InkWell, '20');
      if (grid20Finder.evaluate().isNotEmpty) {
        await tester.tap(grid20Finder.first);
        await tester.pumpAndSettle();
        expect(state.gridSpacing, equals(20.0));
      }

      // Scroll canvas inspector to view background settings
      final inspectorFinder = find.byKey(const ValueKey('properties-sidebar-canvas-inspector'));
      expect(inspectorFinder, findsOneWidget);
      await tester.drag(inspectorFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      final hexFieldFinder = find.byKey(const ValueKey('canvas-hex-input-field'));
      expect(hexFieldFinder, findsOneWidget);

      // Enter a new hex color e.g. "3B82F6" (Blue)
      await tester.enterText(hexFieldFinder, '3B82F6');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(state.canvasBackgroundColor?.toARGB32(), equals(const Color(0xFF3B82F6).toARGB32()));
    });
  });
}
