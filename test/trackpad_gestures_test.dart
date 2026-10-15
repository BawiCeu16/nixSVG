import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Trackpad Pinch-to-Zoom and Panning Robustness Tests', () {
    test('CanvasTransformHelper guards against NaN and non-finite values', () {
      final identity = Matrix4.identity();

      // Pan with non-finite values should return unchanged matrix
      final panned = CanvasTransformHelper.panMatrix(
        identity,
        const Offset(double.nan, 20),
      );
      expect(panned.storage[12].isNaN, isFalse);

      // Zoom with non-finite values should return unchanged matrix
      final zoomed = CanvasTransformHelper.zoomAtScreenPoint(
        identity,
        const Offset(double.infinity, 100),
        1.5,
      );
      expect(zoomed.storage[0].isFinite, isTrue);

      final zeroScaleZoom = CanvasTransformHelper.zoomAtScreenPoint(
        identity,
        const Offset(100, 100),
        0.0,
      );
      expect(zeroScaleZoom.storage[0], equals(1.0));
    });

    testWidgets('Trackpad two-finger panning updates transformation matrix', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TransformationController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: InteractiveCanvas(
                transformationController: controller,
                shapes: const [],
                selectedShapeIds: const {},
                currentMode: EditorMode.select,
                draftShapeType: null,
                draftIsShiftPressed: false,
                draftIsAltPressed: false,
                panStartOffset: null,
                panCurrentOffset: null,
                marqueeRect: null,
                snapGuidelineX: null,
                snapGuidelineY: null,
                gridSpacing: 20.0,
                isPanningWithMouse: false,
                isSpacePressed: false,
                isResizing: false,
                onPointerDown: (_) {},
                onPointerMove: (_) {},
                onPointerUp: (_) {},
                onPointerCancel: (_) {},
                onMatrixChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialTx = controller.value.storage[12];
      final initialTy = controller.value.storage[13];

      // Simulate PointerPanZoomStart
      final startEvent = PointerPanZoomStartEvent(
        position: const Offset(400, 300),
      );
      tester.binding.handlePointerEvent(startEvent);
      await tester.pump();

      // Simulate PointerPanZoomUpdate with panDelta
      final updateEvent = PointerPanZoomUpdateEvent(
        position: const Offset(450, 330),
        pan: const Offset(50, 30),
        panDelta: const Offset(50, 30),
        scale: 1.0,
        rotation: 0.0,
      );
      tester.binding.handlePointerEvent(updateEvent);
      await tester.pump();

      expect(controller.value.storage[12], equals(initialTx + 50));
      expect(controller.value.storage[13], equals(initialTy + 30));

      // End gesture
      final endEvent = PointerPanZoomEndEvent(position: const Offset(450, 330));
      tester.binding.handlePointerEvent(endEvent);
      await tester.pump();
    });

    testWidgets('Trackpad pinch-to-zoom updates scale smoothly across 1.0 reversal', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TransformationController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: InteractiveCanvas(
                transformationController: controller,
                shapes: const [],
                selectedShapeIds: const {},
                currentMode: EditorMode.select,
                draftShapeType: null,
                draftIsShiftPressed: false,
                draftIsAltPressed: false,
                panStartOffset: null,
                panCurrentOffset: null,
                marqueeRect: null,
                snapGuidelineX: null,
                snapGuidelineY: null,
                gridSpacing: 20.0,
                isPanningWithMouse: false,
                isSpacePressed: false,
                isResizing: false,
                onPointerDown: (_) {},
                onPointerMove: (_) {},
                onPointerUp: (_) {},
                onPointerCancel: (_) {},
                onMatrixChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialScale = CanvasTransformHelper.getScale(controller.value);
      expect(initialScale, equals(1.0));

      // Start pinch
      tester.binding.handlePointerEvent(
        PointerPanZoomStartEvent(position: const Offset(600, 400)),
      );
      await tester.pump();

      // Zoom in to 1.25
      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(
          position: const Offset(600, 400),
          pan: Offset.zero,
          panDelta: Offset.zero,
          scale: 1.25,
          rotation: 0.0,
        ),
      );
      await tester.pump();

      final zoomedScale = CanvasTransformHelper.getScale(controller.value);
      expect(zoomedScale, closeTo(1.25, 0.01));

      // Reverse pinch back across 1.0 down to 0.90
      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(
          position: const Offset(600, 400),
          pan: Offset.zero,
          panDelta: Offset.zero,
          scale: 1.0,
          rotation: 0.0,
        ),
      );
      await tester.pump();

      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(
          position: const Offset(600, 400),
          pan: Offset.zero,
          panDelta: Offset.zero,
          scale: 0.90,
          rotation: 0.0,
        ),
      );
      await tester.pump();

      final reversedScale = CanvasTransformHelper.getScale(controller.value);
      expect(reversedScale, closeTo(0.90, 0.01));

      // Clean end
      tester.binding.handlePointerEvent(
        PointerPanZoomEndEvent(position: const Offset(600, 400)),
      );
      await tester.pump();
    });

    testWidgets('Trackpad simultaneous pan and zoom does not desync or corrupt matrix', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TransformationController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: InteractiveCanvas(
                transformationController: controller,
                shapes: const [],
                selectedShapeIds: const {},
                currentMode: EditorMode.select,
                draftShapeType: null,
                draftIsShiftPressed: false,
                draftIsAltPressed: false,
                panStartOffset: null,
                panCurrentOffset: null,
                marqueeRect: null,
                snapGuidelineX: null,
                snapGuidelineY: null,
                gridSpacing: 20.0,
                isPanningWithMouse: false,
                isSpacePressed: false,
                isResizing: false,
                onPointerDown: (_) {},
                onPointerMove: (_) {},
                onPointerUp: (_) {},
                onPointerCancel: (_) {},
                onMatrixChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.binding.handlePointerEvent(
        PointerPanZoomStartEvent(position: const Offset(500, 400)),
      );
      await tester.pump();

      // Combined panDelta + scale
      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(
          position: const Offset(520, 415),
          pan: const Offset(20, 15),
          panDelta: const Offset(20, 15),
          scale: 1.10,
          rotation: 0.0,
        ),
      );
      await tester.pump();

      final currentScale = CanvasTransformHelper.getScale(controller.value);
      expect(currentScale, closeTo(1.10, 0.01));
      expect(controller.value.storage[12].isFinite, isTrue);
      expect(controller.value.storage[13].isFinite, isTrue);

      tester.binding.handlePointerEvent(
        PointerPanZoomEndEvent(position: const Offset(520, 415)),
      );
      await tester.pump();
    });

    testWidgets('Trackpad pinch via PointerScrollEvent with Ctrl modifier zooms smoothly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = TransformationController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: InteractiveCanvas(
                transformationController: controller,
                shapes: const [],
                selectedShapeIds: const {},
                currentMode: EditorMode.select,
                draftShapeType: null,
                draftIsShiftPressed: false,
                draftIsAltPressed: false,
                panStartOffset: null,
                panCurrentOffset: null,
                marqueeRect: null,
                snapGuidelineX: null,
                snapGuidelineY: null,
                gridSpacing: 20.0,
                isPanningWithMouse: false,
                isSpacePressed: false,
                isResizing: false,
                onPointerDown: (_) {},
                onPointerMove: (_) {},
                onPointerUp: (_) {},
                onPointerCancel: (_) {},
                onMatrixChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialScale = CanvasTransformHelper.getScale(controller.value);

      // Simulate Ctrl key down
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      // Simulate trackpad pinch zoom (negative dy = zoom in)
      tester.binding.handlePointerEvent(
        const PointerScrollEvent(
          position: Offset(600, 400),
          scrollDelta: Offset(0, -10),
        ),
      );
      await tester.pump();

      final newScale = CanvasTransformHelper.getScale(controller.value);
      expect(newScale, greaterThan(initialScale));

      // Release Ctrl key
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: 'linux');
      await tester.pump();
    });
  });
}
