import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';

void main() {
  testWidgets('Canvas container retains full 3200x2400 size regardless of screen size', (tester) async {
    // 1. Large desktop screen (1600x1000)
    tester.view.physicalSize = const Size(1600, 1000);
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

    // Find the canvas container inside InteractiveCanvas
    final canvasFinder = find.descendant(
      of: find.byType(InteractiveCanvas),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color != null;
        }
        return false;
      }),
    );

    expect(canvasFinder, findsOneWidget);
    final renderBox1 = tester.renderObject<RenderBox>(canvasFinder);

    // 2. Smaller screen (600x500)
    tester.view.physicalSize = const Size(600, 500);
    await tester.pumpAndSettle();

    final renderBox2 = tester.renderObject<RenderBox>(canvasFinder);

    expect(renderBox1.size, const Size(3200, 2400));
    expect(renderBox2.size, const Size(3200, 2400));
  });
}
