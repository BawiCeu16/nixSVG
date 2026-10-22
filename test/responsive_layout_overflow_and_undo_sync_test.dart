import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/providers/project_provider.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/widgets/layers_sidebar.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';
import 'package:nixsvg/widgets/top_navigation_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Responsive Layout Overflow & Robustness Tests', () {
    testWidgets(
      'TopNavigationBar handles extremely narrow constraints without throwing AssertionError',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 10, // Less than 16px!
                  child: TopNavigationBar(
                    fileName: 'Test',
                    onFileNameChanged: (_) {},
                    zoomScale: 1.0,
                    onZoomIn: () {},
                    onZoomOut: () {},
                    onResetZoom: () {},
                    onUndo: () {},
                    onRedo: () {},
                    canUndo: true,
                    canRedo: true,
                    snapToGrid: false,
                    onSnapToGridChanged: (_) {},
                    onExportSvg: () {},
                    onImportImage: () {},
                    onClearCanvas: () {},
                    onShowShortcuts: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        // Expect pumpWidget to succeed without throwing an AssertionError for minWidth >= 0
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LayersSidebar at minimum width (160px) with long group name and multiple selections does not overflow',
      (WidgetTester tester) async {
        final shapes = [
          VectorShape(
            id: 's1',
            name: 'Layer With Very Long Title 1',
            type: ShapeType.rectangle,
            rect: const Rect.fromLTWH(0, 0, 100, 100),
            groupId: 'g1',
            groupName: 'Very Long Group Name That Could Overflow',
          ),
          VectorShape(
            id: 's2',
            name: 'Layer 2',
            type: ShapeType.ellipse,
            rect: const Rect.fromLTWH(50, 50, 80, 80),
            groupId: 'g1',
            groupName: 'Very Long Group Name That Could Overflow',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 160, // Minimum responsive width
                height: 600,
                child: LayersSidebar(
                  shapes: shapes,
                  selectedShapeIds: {'s1', 's2'},
                  onSelectShape: (_) {},
                  onToggleVisibility: (_) {},
                  onToggleLock: (_) {},
                  onDeleteShape: (_) {},
                  onBringForward: () {},
                  onSendBackward: () {},
                  onRenameShape: (_, _) {},
                  width: 160,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Layers'), findsOneWidget);
      },
    );

    testWidgets(
      'PropertiesSidebar at minimum width (180px) with long group name does not overflow',
      (WidgetTester tester) async {
        final shape = VectorShape(
          id: 's1',
          name: 'My Special Shape With Extended Title',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(0, 0, 100, 100),
          groupId: 'g1',
          groupName: 'Extremely Long Group Title Heading Here',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 180, // Minimum responsive width
                height: 800,
                child: PropertiesSidebar(
                  width: 180,
                  selectedShape: shape,
                  onShapeChanged: (_) {},
                  onOpenColorPickerFill: ([_]) {},
                  onOpenColorPickerStroke: ([_]) {},
                  onDuplicateShape: () {},
                  onDeleteSelected: () {},
                  onAlignShape: (_) {},
                  canGroup: true,
                  canUngroup: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('FigmaWorkspace Undo/Redo State Management Synchronization Tests', () {
    testWidgets('Undo and Redo synchronize changes to projectsProvider', (
      WidgetTester tester,
    ) async {
      final initialProject = ProjectModel.createNew(name: 'Sync Test');
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: FigmaWorkspace(
              initialProject: initialProject,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final workspaceState =
          tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));

      // Initially shapes has 6 default starter shapes
      final initialCount = workspaceState.shapes.length;

      // Select first shape and duplicate it via Ctrl+D
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Trigger duplicate via Ctrl+D
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(workspaceState.shapes.length, initialCount * 2);
      expect(
        container.read(projectsProvider).activeProject?.shapes.length,
        initialCount * 2,
      );

      // Perform Undo via Ctrl+Z
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(workspaceState.shapes.length, initialCount);
      // Verify projectsProvider active project was synchronized on undo!
      final activeProject = container.read(projectsProvider).activeProject;
      expect(activeProject, isNotNull);
      expect(activeProject!.shapes.length, initialCount);

      // Perform Redo via Ctrl+Shift+Z
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(workspaceState.shapes.length, initialCount * 2);
      final redoneProject = container.read(projectsProvider).activeProject;
      expect(redoneProject!.shapes.length, initialCount * 2);
    });
  });
}
