import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';
import 'package:nixsvg/widgets/context_menu/figma_context_menu.dart';
import 'package:nixsvg/widgets/layers_sidebar.dart';
import 'package:nixsvg/widgets/top_navigation_bar.dart';

void main() {
  group('Figma Desktop Context Menu Tests', () {
    testWidgets('showFigmaContextMenu displays items with shortcuts and triggers onTap', (
      WidgetTester tester,
    ) async {
      bool cutTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showFigmaContextMenu(
                        context: context,
                        globalPosition: const Offset(100, 100),
                        items: [
                          FigmaMenuItem(
                            label: 'Cut',
                            icon: Icons.content_cut,
                            shortcut: '⌘X',
                            onTap: () => cutTapped = true,
                          ),
                          const FigmaMenuDivider(),
                          FigmaMenuItem(
                            label: 'Copy',
                            icon: Icons.content_copy,
                            shortcut: '⌘C',
                            onTap: () {},
                          ),
                        ],
                      );
                    },
                    child: const Text('Open Menu'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('⌘X'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('⌘C'), findsOneWidget);

      await tester.tap(find.text('Cut'));
      await tester.pumpAndSettle();

      expect(cutTapped, isTrue);
    });
  });

  group('LayersSidebar Selection Tool Tests', () {
    late List<VectorShape> shapes;

    setUp(() {
      shapes = [
        VectorShape(
          id: 'shape-1',
          name: 'Layer 1',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(0, 0, 100, 100),
        ),
        VectorShape(
          id: 'shape-2',
          name: 'Layer 2',
          type: ShapeType.ellipse,
          rect: const Rect.fromLTWH(50, 50, 100, 100),
        ),
        VectorShape(
          id: 'shape-3',
          name: 'Layer 3',
          type: ShapeType.star,
          rect: const Rect.fromLTWH(100, 100, 100, 100),
        ),
      ];
    });

    testWidgets('Single click on layer selects it exclusively', (
      WidgetTester tester,
    ) async {
      Set<String> selectedIds = {'shape-1'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LayersSidebar(
                  shapes: shapes,
                  selectedShapeIds: selectedIds,
                  onSelectShape: (id) {
                    setState(() {
                      selectedIds = {id};
                    });
                  },
                  onSelectShapes: (ids) {
                    setState(() {
                      selectedIds = Set.from(ids);
                    });
                  },
                  onToggleVisibility: (_) {},
                  onToggleLock: (_) {},
                  onDeleteShape: (_) {},
                  onBringForward: () {},
                  onSendBackward: () {},
                  onRenameShape: (_, _) {},
                );
              },
            ),
          ),
        ),
      );

      // In LayersSidebar display list is reversed: Layer 3 is top, Layer 2 is middle, Layer 1 is bottom
      expect(find.text('Layer 2'), findsOneWidget);

      await tester.tap(find.text('Layer 2'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(selectedIds, equals({'shape-2'}));
    });

    testWidgets('Shift+click performs range selection across layers', (
      WidgetTester tester,
    ) async {
      Set<String> selectedIds = {};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LayersSidebar(
                  shapes: shapes,
                  selectedShapeIds: selectedIds,
                  onSelectShape: (id) => setState(() => selectedIds = {id}),
                  onSelectShapes: (ids) => setState(() => selectedIds = Set.from(ids)),
                  onToggleVisibility: (_) {},
                  onToggleLock: (_) {},
                  onDeleteShape: (_) {},
                  onBringForward: () {},
                  onSendBackward: () {},
                  onRenameShape: (_, _) {},
                );
              },
            ),
          ),
        ),
      );

      // Single click Layer 3 (index 0 in reversed display list)
      await tester.tap(find.text('Layer 3'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(selectedIds, equals({'shape-3'}));

      // Hold Shift and click Layer 1 (index 2 in reversed display list)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.text('Layer 1'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      // Should select range: Layer 3, Layer 2, Layer 1
      expect(selectedIds, equals({'shape-3', 'shape-2', 'shape-1'}));
    });

    testWidgets('Meta/Control+click toggles individual layer in selection', (
      WidgetTester tester,
    ) async {
      Set<String> selectedIds = {'shape-3'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LayersSidebar(
                  shapes: shapes,
                  selectedShapeIds: selectedIds,
                  onSelectShape: (id) => setState(() => selectedIds = {id}),
                  onSelectShapes: (ids) => setState(() => selectedIds = Set.from(ids)),
                  onToggleVisibility: (_) {},
                  onToggleLock: (_) {},
                  onDeleteShape: (_) {},
                  onBringForward: () {},
                  onSendBackward: () {},
                  onRenameShape: (_, _) {},
                );
              },
            ),
          ),
        ),
      );

      // Hold Meta (Command) and click Layer 1
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.tap(find.text('Layer 1'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

      // Both Layer 3 and Layer 1 should now be selected
      expect(selectedIds, equals({'shape-3', 'shape-1'}));

      // Hold Meta again and click Layer 3 to deselect it
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.tap(find.text('Layer 3'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

      // Only Layer 1 should remain selected
      expect(selectedIds, equals({'shape-1'}));
    });

    testWidgets('Header Select All and Deselect All buttons work', (
      WidgetTester tester,
    ) async {
      Set<String> selectedIds = {'shape-1'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LayersSidebar(
                  shapes: shapes,
                  selectedShapeIds: selectedIds,
                  onSelectShape: (id) => setState(() => selectedIds = {id}),
                  onSelectShapes: (ids) => setState(() => selectedIds = Set.from(ids)),
                  onToggleVisibility: (_) {},
                  onToggleLock: (_) {},
                  onDeleteShape: (_) {},
                  onBringForward: () {},
                  onSendBackward: () {},
                  onRenameShape: (_, _) {},
                );
              },
            ),
          ),
        ),
      );

      // Tap "Select All (⌘A)" icon button in header
      final selectAllFinder = find.byTooltip('Select All Layers (⌘A)');
      expect(selectAllFinder, findsOneWidget);
      await tester.tap(selectAllFinder);
      await tester.pumpAndSettle();

      expect(selectedIds, equals({'shape-1', 'shape-2', 'shape-3'}));

      // Tap "Deselect All (Esc)" icon button in header
      final deselectAllFinder = find.byTooltip('Deselect All (Esc)');
      expect(deselectAllFinder, findsOneWidget);
      await tester.tap(deselectAllFinder);
      await tester.pumpAndSettle();

      expect(selectedIds, isEmpty);
    });

    testWidgets('Right click (secondary tap) on layer row opens layer context menu', (
      WidgetTester tester,
    ) async {
      bool duplicateCalled = false;
      bool bringToFrontCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayersSidebar(
              shapes: shapes,
              selectedShapeIds: {'shape-2'},
              onSelectShape: (_) {},
              onSelectShapes: (_) {},
              onToggleVisibility: (_) {},
              onToggleLock: (_) {},
              onDeleteShape: (_) {},
              onBringForward: () {},
              onSendBackward: () {},
              onBringToFront: () => bringToFrontCalled = true,
              onDuplicateShape: (_) => duplicateCalled = true,
              onRenameShape: (_, _) {},
            ),
          ),
        ),
      );

      // Secondary tap / right-click on Layer 2
      final layerFinder = find.text('Layer 2');
      await tester.tap(layerFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Verify layer context menu is shown with Figma actions
      expect(find.text('Bring to Front'), findsOneWidget);
      expect(find.text('Duplicate Layer'), findsOneWidget);

      await tester.tap(find.text('Bring to Front'));
      await tester.pumpAndSettle();

      expect(bringToFrontCalled, isTrue);

      // Re-open and verify Duplicate Layer
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(layerFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duplicate Layer'));
      await tester.pumpAndSettle();

      expect(duplicateCalled, isTrue);
    });

    testWidgets('Right click on empty layers area opens empty layers context menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayersSidebar(
              shapes: const [],
              selectedShapeIds: const {},
              onSelectShape: (_) {},
              onToggleVisibility: (_) {},
              onToggleLock: (_) {},
              onDeleteShape: (_) {},
              onBringForward: () {},
              onSendBackward: () {},
              onRenameShape: (_, _) {},
            ),
          ),
        ),
      );

      // Secondary tap on empty state area
      final emptyFinder = find.text('No vector layers');
      expect(emptyFinder, findsOneWidget);

      await tester.tap(emptyFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Empty context menu shows Select All Layers
      expect(find.text('Select All Layers'), findsOneWidget);
    });
  });

  group('InteractiveCanvas Secondary Tap Tests', () {
    testWidgets('Secondary tap on canvas invokes onSecondaryTap with coordinates', (
      WidgetTester tester,
    ) async {
      Offset? receivedGlobalPos;
      Offset? receivedCanvasPos;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCanvas(
              transformationController: TransformationController(),
              shapes: const [],
              selectedShapeIds: const {},
              currentMode: EditorMode.select,
              draftShapeType: ShapeType.rectangle,
              panStartOffset: null,
              panCurrentOffset: null,
              marqueeRect: null,
              snapGuidelineX: null,
              snapGuidelineY: null,
              gridSpacing: 40.0,
              isPanningWithMouse: false,
              isSpacePressed: false,
              canvasSize: const Size(800, 600),
              onPointerDown: (_) {},
              onPointerMove: (_) {},
              onPointerUp: (_) {},
              onPointerCancel: (_) {},
              onMatrixChanged: () {},
              onSecondaryTap: (globalPos, canvasPos) {
                receivedGlobalPos = globalPos;
                receivedCanvasPos = canvasPos;
              },
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(300, 250), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(receivedGlobalPos, isNotNull);
      expect(receivedCanvasPos, isNotNull);
    });
  });

  group('TopNavigationBar Document Capsule Context Menu Tests', () {
    testWidgets('Right click on document capsule opens document context menu', (
      WidgetTester tester,
    ) async {
      bool exportCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TopNavigationBar(
                fileName: 'MyProject',
                onFileNameChanged: (_) {},
                onUndo: () {},
                onRedo: () {},
                canUndo: true,
                canRedo: true,
                snapToGrid: false,
                onSnapToGridChanged: (_) {},
                onExportSvg: () => exportCalled = true,
                onImportImage: () {},
                onClearCanvas: () {},
                onShowShortcuts: () {},
                zoomScale: 1.0,
                onZoomIn: () {},
                onZoomOut: () {},
                onResetZoom: () {},
              ),
            ),
          ),
        ),
      );

      final capsuleFinder = find.text('.svg');
      expect(capsuleFinder, findsOneWidget);

      await tester.tap(capsuleFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('Rename Document'), findsOneWidget);
      expect(find.text('Export SVG...'), findsOneWidget);

      await tester.tap(find.text('Export SVG...'));
      await tester.pumpAndSettle();

      expect(exportCalled, isTrue);
    });
  });
}
