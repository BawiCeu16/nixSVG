import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/widgets/top_navigation_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Figma UI Editor & Infinite Canvas Tests', () {
    test('CanvasTransformHelper.getVisibleRect computes accurate world bounds', () {
      final identityMatrix = Matrix4.identity();
      final visibleIdentity = CanvasTransformHelper.getVisibleRect(
        identityMatrix,
        const Size(400, 800),
      );
      expect(visibleIdentity.left, 0.0);
      expect(visibleIdentity.top, 0.0);
      expect(visibleIdentity.width, 400.0);
      expect(visibleIdentity.height, 800.0);

      // Panned matrix: translated by (100, 200)
      final pannedMatrix = Matrix4.identity()..translate(100.0, 200.0);
      final visiblePanned = CanvasTransformHelper.getVisibleRect(
        pannedMatrix,
        const Size(400, 800),
      );
      expect(visiblePanned.left, -100.0);
      expect(visiblePanned.top, -200.0);
      expect(visiblePanned.width, 400.0);
      expect(visiblePanned.height, 800.0);

      // Zoomed matrix: scaled 2x
      final zoomedMatrix = Matrix4.identity()..scale(2.0, 2.0);
      final visibleZoomed = CanvasTransformHelper.getVisibleRect(
        zoomedMatrix,
        const Size(400, 800),
      );
      expect(visibleZoomed.left, 0.0);
      expect(visibleZoomed.top, 0.0);
      expect(visibleZoomed.width, 200.0);
      expect(visibleZoomed.height, 400.0);
    });

    testWidgets('TopNavigationBar renders mobile bar cleanly on 390px mobile viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TopNavigationBar(
                fileName: 'Mobile Project',
                onFileNameChanged: (_) {},
                zoomScale: 1.0,
                onZoomIn: () {},
                onZoomOut: () {},
                onResetZoom: () {},
                onUndo: () {},
                onRedo: () {},
                canUndo: true,
                canRedo: true,
                snapToGrid: true,
                onSnapToGridChanged: (_) {},
                onExportSvg: () {},
                onImportImage: () {},
                onClearCanvas: () {},
                onShowShortcuts: () {},
                showLayers: false,
                onToggleLayers: (_) {},
                showProperties: false,
                onToggleProperties: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);

      // Verify compact document title is rendered
      expect(find.text('Mobile Project'), findsOneWidget);

      // Verify zoom indicator is present
      expect(find.text('100%'), findsOneWidget);

      // Verify more options menu is present
      expect(find.byTooltip('More Actions'), findsOneWidget);
    });

    testWidgets('FigmaWorkspace shows mobile contextual selection bar when shape is selected', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FigmaWorkspace(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final workspaceState = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Add a rectangle and select it
      final rectShape = VectorShape(
        id: 'mobile-rect',
        name: 'Card Container',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(50, 50, 120, 80),
        fillColor: Colors.blue,
      );

      workspaceState.shapes.add(rectShape);
      workspaceState.selectShape('mobile-rect');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify mobile contextual bar items
      expect(find.text('Card Container'), findsWidgets);
      expect(find.byTooltip('Fill Color'), findsOneWidget);
      expect(find.byTooltip('Duplicate'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byTooltip('Edit Properties'), findsOneWidget);
    });
  });
}
