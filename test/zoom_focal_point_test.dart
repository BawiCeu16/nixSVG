import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';

void main() {
  group('CanvasTransformHelper Focal Point Zoom Math', () {
    test('Focal canvas point remains strictly invariant on screen before and after zoom', () {
      final matrix = Matrix4.identity()
        ..storage[0] = 1.4
        ..storage[5] = 1.4
        ..storage[12] = 230.0
        ..storage[13] = 145.0;

      const focalCanvasPoint = Offset(450.0, 320.0);

      // Screen position before zoom: S = scale * C + T
      final scaleBefore = matrix.getMaxScaleOnAxis();
      final screenXBefore =
          scaleBefore * focalCanvasPoint.dx + matrix.storage[12];
      final screenYBefore =
          scaleBefore * focalCanvasPoint.dy + matrix.storage[13];

      // Zoom in by 1.35x
      final zoomedIn = CanvasTransformHelper.zoomAtCanvasPoint(
        matrix,
        focalCanvasPoint,
        1.35,
      );

      final scaleAfter = zoomedIn.getMaxScaleOnAxis();
      final screenXAfter =
          scaleAfter * focalCanvasPoint.dx + zoomedIn.storage[12];
      final screenYAfter =
          scaleAfter * focalCanvasPoint.dy + zoomedIn.storage[13];

      expect(screenXAfter, closeTo(screenXBefore, 1e-4));
      expect(screenYAfter, closeTo(screenYBefore, 1e-4));

      // Zoom out by 0.7x
      final zoomedOut = CanvasTransformHelper.zoomAtCanvasPoint(
        zoomedIn,
        focalCanvasPoint,
        0.7,
      );

      final scaleOut = zoomedOut.getMaxScaleOnAxis();
      final screenXOut = scaleOut * focalCanvasPoint.dx + zoomedOut.storage[12];
      final screenYOut = scaleOut * focalCanvasPoint.dy + zoomedOut.storage[13];

      expect(screenXOut, closeTo(screenXBefore, 1e-4));
      expect(screenYOut, closeTo(screenYBefore, 1e-4));
    });

    test('Zooming in and zooming out by reciprocal factors returns to identical matrix', () {
      final original = Matrix4.identity()
        ..storage[0] = 1.0
        ..storage[5] = 1.0
        ..storage[12] = 50.0
        ..storage[13] = -80.0;

      const focalPoint = Offset(600.0, 400.0);
      const factor = 1.25;

      final zoomed = CanvasTransformHelper.zoomAtCanvasPoint(
        original,
        focalPoint,
        factor,
      );
      final restored = CanvasTransformHelper.zoomAtCanvasPoint(
        zoomed,
        focalPoint,
        1.0 / factor,
      );

      expect(
        restored.getMaxScaleOnAxis(),
        closeTo(original.getMaxScaleOnAxis(), 1e-5),
      );
      expect(restored.storage[12], closeTo(original.storage[12], 1e-5));
      expect(restored.storage[13], closeTo(original.storage[13], 1e-5));
    });

    test(
      'Scale is strictly bounded between minScale (5%) and maxScale (3200%)',
      () {
        var matrix = Matrix4.identity();
        const focalPoint = Offset(300.0, 200.0);

        // Repeatedly zoom in 100 times
        for (int i = 0; i < 100; i++) {
          matrix = CanvasTransformHelper.zoomAtCanvasPoint(
            matrix,
            focalPoint,
            1.3,
          );
        }

        expect(
          CanvasTransformHelper.getScale(matrix),
          closeTo(CanvasTransformHelper.maxScale, 1e-5),
        );
        expect(matrix.storage[12].isFinite, isTrue);
        expect(matrix.storage[13].isFinite, isTrue);

        // Repeatedly zoom out 150 times
        for (int i = 0; i < 150; i++) {
          matrix = CanvasTransformHelper.zoomAtCanvasPoint(
            matrix,
            focalPoint,
            0.7,
          );
        }

        expect(
          CanvasTransformHelper.getScale(matrix),
          closeTo(CanvasTransformHelper.minScale, 1e-5),
        );
        expect(matrix.storage[12].isFinite, isTrue);
        expect(matrix.storage[13].isFinite, isTrue);
      },
    );

    test('zoomAtScreenPoint correctly converts screen coordinates to canvas coordinates', () {
      final matrix = Matrix4.identity()
        ..storage[0] = 2.0
        ..storage[5] = 2.0
        ..storage[12] = 100.0
        ..storage[13] = 50.0;

      const screenFocalPoint = Offset(500.0, 450.0);

      final zoomed = CanvasTransformHelper.zoomAtScreenPoint(
        matrix,
        screenFocalPoint,
        1.5,
      );

      // Canvas point under screen (500, 450) was: (500 - 100) / 2 = 200, (450 - 50) / 2 = 200
      // After zoom: scale is 3.0, new screen pos should be 3.0 * 200 + newT == 500
      final scaleNew = zoomed.getMaxScaleOnAxis();
      final screenXNew = scaleNew * 200.0 + zoomed.storage[12];
      final screenYNew = scaleNew * 200.0 + zoomed.storage[13];

      expect(screenXNew, closeTo(500.0, 1e-4));
      expect(screenYNew, closeTo(450.0, 1e-4));
    });
  });

  group('Interactive Canvas Zoom UI & Shortcuts', () {
    testWidgets('Ctrl + scroll wheel zooms canvas focused on cursor point', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const NixSvgApp());
      await tester.pumpAndSettle();

      final ivFinder = find.byType(InteractiveViewer);
      final ivWidget = tester.widget<InteractiveViewer>(ivFinder);
      final controller = ivWidget.transformationController!;

      final initialScale = controller.value.getMaxScaleOnAxis();
      expect(initialScale, 1.0);

      // Target mouse position on canvas
      final center = tester.getCenter(ivFinder);

      // Hold Ctrl and send scroll wheel (zoom in)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(center);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      final zoomedScale = controller.value.getMaxScaleOnAxis();
      expect(zoomedScale, greaterThan(initialScale));

      // Verify Alt + wheel does NOT zoom
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      expect(controller.value.getMaxScaleOnAxis(), equals(zoomedScale));

      // Canvas should still have valid finite translation and be visible
      expect(controller.value.storage[12].isFinite, isTrue);
      expect(controller.value.storage[13].isFinite, isTrue);
    });

    test('zoomToFit mathematically maps targetBounds.center precisely to viewportSize / 2', () {
      const bounds = Rect.fromLTWH(320, 150, 400, 260);
      const viewport = Size(800, 600);
      final matrix = CanvasTransformHelper.zoomToFit(
        bounds,
        viewport,
        padding: 60,
      );

      final scale = matrix.getMaxScaleOnAxis();
      final tx = matrix.storage[12];
      final ty = matrix.storage[13];

      // Screen position of the bounds center: S = scale * C + T
      final boundsCenter = bounds.center;
      final screenCenterX = boundsCenter.dx * scale + tx;
      final screenCenterY = boundsCenter.dy * scale + ty;

      // Must equal the viewport center
      expect(screenCenterX, closeTo(viewport.width / 2, 1e-4));
      expect(screenCenterY, closeTo(viewport.height / 2, 1e-4));
    });

    testWidgets(
      'Top Navigation Bar zoom in and zoom out updates zoom smoothly without losing canvas',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final ivFinder = find.byType(InteractiveViewer);
        final ivWidget = tester.widget<InteractiveViewer>(ivFinder);
        final controller = ivWidget.transformationController!;

        final initialScale = controller.value.getMaxScaleOnAxis();

        // Find Zoom In button in top navigation bar
        final zoomInFinder = find.byTooltip('Zoom In');
        expect(zoomInFinder, findsOneWidget);
        await tester.tap(zoomInFinder);
        await tester.pumpAndSettle();

        expect(
          controller.value.getMaxScaleOnAxis(),
          closeTo(initialScale * 1.2, 1e-4),
        );

        // Find Zoom Out button
        final zoomOutFinder = find.byTooltip('Zoom Out');
        expect(zoomOutFinder, findsOneWidget);
        await tester.tap(zoomOutFinder);
        await tester.pumpAndSettle();

        expect(
          controller.value.getMaxScaleOnAxis(),
          closeTo(initialScale, 1e-4),
        );
      },
    );

    testWidgets(
      'Zoom to Selection (Shift+2) centers selected shape at visible canvas center',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const NixSvgApp());
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );
        // Select the first shape
        final selectedShape = state.shapes.first;
        state.selectShape(selectedShape.id);
        await tester.pumpAndSettle();

        // Trigger Zoom to Selection using shortcut Shift+2
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();

        final ivFinder = find.byType(InteractiveCanvas);
        final canvasBox = tester.renderObject<RenderBox>(ivFinder);
        final canvasSize = canvasBox.size;

        final matrix = state.transformationController.value;
        final scale = matrix.getMaxScaleOnAxis();
        final tx = matrix.storage[12];
        final ty = matrix.storage[13];

        // Canvas local coordinate of shape center
        final shapeCenter = selectedShape.rect.center;
        // In InteractiveCanvas coordinate space, (x, y) after transformation is:
        final localCanvasScreenX = shapeCenter.dx * scale + tx;
        final localCanvasScreenY = shapeCenter.dy * scale + ty;

        // Must be at the center of the InteractiveCanvas RenderBox
        expect(localCanvasScreenX, closeTo(canvasSize.width / 2, 1.0));
        expect(localCanvasScreenY, closeTo(canvasSize.height / 2, 1.0));
      },
    );
  });
}
