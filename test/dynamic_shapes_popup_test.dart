import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/floating_tool_bar.dart';

void main() {
  group('Dynamic Shapes Tools Popup Placement Tests', () {
    testWidgets('Shapes popup position dynamically adapts when resizing from floating/small screen to fullscreen',
        (tester) async {
      // 1. Start with a small floating window size (500x400)
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      EditorMode currentMode = EditorMode.select;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16.0,
                  child: Center(
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return FloatingToolBar(
                          currentMode: currentMode,
                          onModeChanged: (mode) =>
                              setState(() => currentMode = mode),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Open popup in floating screen mode
      final shapeTooltip =
          find.byTooltip('Rectangle Tool (R) - Long-press for Shapes');
      expect(shapeTooltip, findsOneWidget);
      await tester.longPress(shapeTooltip);
      await tester.pumpAndSettle();

      // Popup is visible
      final segmentedListFinder = find.byType(M3ESegmentedList);
      expect(segmentedListFinder, findsOneWidget);

      final initialPopupTopLeft = tester.getTopLeft(segmentedListFinder);
      final initialPopupCenter = tester.getCenter(segmentedListFinder);
      final initialButtonCenter = tester.getCenter(shapeTooltip);

      // Popup should be centered horizontally on the button in small screen
      expect((initialPopupCenter.dx - initialButtonCenter.dx).abs(), lessThan(5.0));

      // 3. Make screen full screen (1920x1080)
      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pump();
      await tester.pumpAndSettle();

      // The toolbar moved because it is centered in the 1920px wide screen
      final fullScreenButtonCenter = tester.getCenter(shapeTooltip);
      final fullScreenPopupCenter = tester.getCenter(segmentedListFinder);
      final fullScreenPopupTopLeft = tester.getTopLeft(segmentedListFinder);

      // Button has moved horizontally by hundreds of pixels
      expect(fullScreenButtonCenter.dx, greaterThan(initialButtonCenter.dx + 400.0));

      // CRITICAL CHECK: The popup dynamically updated its position and is still centered on the button!
      expect(fullScreenPopupTopLeft.dx, isNot(equals(initialPopupTopLeft.dx)));
      expect((fullScreenPopupCenter.dx - fullScreenButtonCenter.dx).abs(), lessThan(5.0));
    });

    testWidgets('Shapes popup fits within compact/short screen height without overflow',
        (tester) async {
      // Small screen height (e.g. compact floating window or phone landscape)
      tester.view.physicalSize = const Size(360, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      EditorMode currentMode = EditorMode.select;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8.0,
                  child: Center(
                    child: FloatingToolBar(
                      currentMode: currentMode,
                      onModeChanged: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shapeTooltip =
          find.byTooltip('Rectangle Tool (R) - Long-press for Shapes');
      await tester.longPress(shapeTooltip);
      await tester.pumpAndSettle();

      // Ensure no flutter overflow exceptions occurred and segmented list exists
      expect(tester.takeException(), isNull);
      expect(find.byType(M3ESegmentedList), findsOneWidget);

      final popupRect = tester.getRect(find.byType(M3ESegmentedList));
      // Popup fits within screen bounds
      expect(popupRect.top, greaterThanOrEqualTo(0.0));
      expect(popupRect.bottom, lessThanOrEqualTo(320.0));
    });
  });
}
