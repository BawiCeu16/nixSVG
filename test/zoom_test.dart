import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';

void main() {
  test('zoomAtCanvasPoint preserves screen position of cursor', () {
    Matrix4 matrix = Matrix4.identity();
    const cursorScreen = Offset(400, 300);
    final cursorCanvas = CanvasTransformHelper.screenToCanvas(matrix, cursorScreen);
    expect(cursorCanvas, const Offset(400, 300));

    matrix = CanvasTransformHelper.zoomAtCanvasPoint(matrix, cursorCanvas, 1.2);
    final screenAfter = CanvasTransformHelper.canvasToScreen(matrix, cursorCanvas);
    expect(screenAfter.dx, closeTo(cursorScreen.dx, 1e-4));
    expect(screenAfter.dy, closeTo(cursorScreen.dy, 1e-4));
  });

  testWidgets('InteractiveCanvas pointer scroll zoom preserves cursor focus', (tester) async {
    final controller = TransformationController();
    Offset? hoveredCanvasPos;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 60, left: 200),
            child: SizedBox(
              width: 800,
              height: 600,
              child: InteractiveCanvas(
                transformationController: controller,
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
                onPointerDown: (_) {},
                onPointerMove: (_) {},
                onPointerUp: (_) {},
                onPointerCancel: (_) {},
                onMatrixChanged: () {},
                onPointerHover: (pos) => hoveredCanvasPos = pos,
              ),
            ),
          ),
        ),
      ),
    );

    const globalCursor = Offset(400, 300);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(globalCursor);
    await tester.pump();

    expect(hoveredCanvasPos?.dx, closeTo(200.0, 1.0));
    expect(hoveredCanvasPos?.dy, closeTo(240.0, 1.0));

    // Send a scroll event with Ctrl key
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final scrollEvent = PointerScrollEvent(
      position: globalCursor,
      scrollDelta: const Offset(0, -100),
    );
    tester.binding.handlePointerEvent(scrollEvent);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    final scaleAfter = CanvasTransformHelper.getScale(controller.value);
    expect(scaleAfter, greaterThan(1.0));

    final canvasPointUnderCursorAfter = CanvasTransformHelper.screenToCanvas(
      controller.value,
      const Offset(200, 240),
    );
    expect(canvasPointUnderCursorAfter.dx, closeTo(200.0, 1.0));
    expect(canvasPointUnderCursorAfter.dy, closeTo(240.0, 1.0));

    // Repeat another zoom tick at the same cursor point
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    tester.binding.handlePointerEvent(scrollEvent);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    final canvasPointUnderCursorSecond = CanvasTransformHelper.screenToCanvas(
      controller.value,
      const Offset(200, 240),
    );
    expect(canvasPointUnderCursorSecond.dx, closeTo(200.0, 1.0));
    expect(canvasPointUnderCursorSecond.dy, closeTo(240.0, 1.0));

    // Verify Alt + wheel does NOT zoom (per user requirement)
    final scaleBeforeAlt = CanvasTransformHelper.getScale(controller.value);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    tester.binding.handlePointerEvent(scrollEvent);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    final scaleAfterAlt = CanvasTransformHelper.getScale(controller.value);
    expect(scaleAfterAlt, equals(scaleBeforeAlt));
  });
}
