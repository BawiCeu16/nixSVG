import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/models/vector_shape.dart';

void main() {
  testWidgets('Pan canvas using Hand / Pan tool (H)', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NixSvgApp());
    await tester.pumpAndSettle();

    final ivFinder = find.byType(InteractiveViewer);
    final ivWidget = tester.widget<InteractiveViewer>(ivFinder);
    final controller = ivWidget.transformationController!;

    final initialX = controller.value.storage[12];
    final initialY = controller.value.storage[13];

    // Press 'H' to switch to Hand/Pan mode
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.pumpAndSettle();

    final state = tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));
    expect(state.currentMode, EditorMode.pan);

    // Drag canvas 150px right, 100px down with primary mouse
    final center = tester.getCenter(ivFinder);
    final gesture = await tester.startGesture(center);
    await tester.pump();

    await gesture.moveBy(const Offset(150, 100));
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.value.storage[12], initialX + 150);
    expect(controller.value.storage[13], initialY + 100);
  });

  testWidgets('Pan canvas by holding Spacebar and dragging', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NixSvgApp());
    await tester.pumpAndSettle();

    final ivFinder = find.byType(InteractiveViewer);
    final ivWidget = tester.widget<InteractiveViewer>(ivFinder);
    final controller = ivWidget.transformationController!;

    final initialX = controller.value.storage[12];
    final initialY = controller.value.storage[13];

    // Hold Spacebar down
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    // Drag with primary mouse
    final center = tester.getCenter(ivFinder);
    final gesture = await tester.startGesture(center);
    await tester.pump();

    await gesture.moveBy(const Offset(80, 60));
    await tester.pump();

    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(controller.value.storage[12], initialX + 80);
    expect(controller.value.storage[13], initialY + 60);
  });

  testWidgets('Pan canvas with middle mouse button drag', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NixSvgApp());
    await tester.pumpAndSettle();

    final ivFinder = find.byType(InteractiveViewer);
    final ivWidget = tester.widget<InteractiveViewer>(ivFinder);
    final controller = ivWidget.transformationController!;

    final initialX = controller.value.storage[12];
    final initialY = controller.value.storage[13];

    // Middle click and drag
    final center = tester.getCenter(ivFinder);
    final gesture = await tester.startGesture(
      center,
      buttons: kMiddleMouseButton,
    );
    await tester.pump();

    await gesture.moveBy(const Offset(-50, -40));
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.value.storage[12], initialX - 50);
    expect(controller.value.storage[13], initialY - 40);
  });
}
