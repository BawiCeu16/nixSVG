import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';

void main() {
  group('PropertiesSidebar Connected Header Action Buttons', () {
    testWidgets('Renders connected M3EToggleButtonGroup and triggers actions', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool groupCalled = false;
      bool duplicateCalled = false;
      bool deleteCalled = false;

      final shape = VectorShape(
        id: 'test-shape',
        name: 'Rectangle 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(10, 10, 100, 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: PropertiesSidebar(
                selectedShape: shape,
                selectedShapesCount: 2,
                canGroup: true,
                onGroupShapes: () => groupCalled = true,
                onDuplicateShape: () => duplicateCalled = true,
                onDeleteSelected: () => deleteCalled = true,
                onShapeChanged: (_) {},
                onOpenColorPickerFill: ([_]) {},
                onOpenColorPickerStroke: ([_]) {},
                onAlignShape: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(M3EToggleButtonGroup), findsWidgets);

      // Verify tooltips exist
      final groupBtn = find.byTooltip('Group (Ctrl+G)');
      final duplicateBtn = find.byTooltip('Duplicate (Ctrl+D)');
      final deleteBtn = find.byTooltip('Delete (Del)');

      expect(groupBtn, findsOneWidget);
      expect(duplicateBtn, findsOneWidget);
      expect(deleteBtn, findsOneWidget);

      // Tap duplicate button
      await tester.tap(duplicateBtn);
      await tester.pumpAndSettle();
      expect(duplicateCalled, isTrue);

      // Tap group button
      await tester.tap(groupBtn);
      await tester.pumpAndSettle();
      expect(groupCalled, isTrue);

      // Tap delete button
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();
      expect(deleteCalled, isTrue);
    });

    testWidgets('Ungroup button appears in connected group when canUngroup is true', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool ungroupCalled = false;

      final groupedShape = VectorShape(
        id: 'test-shape',
        name: 'Rectangle 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(10, 10, 100, 100),
        groupId: 'g-1',
        groupName: 'Cards Group',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: PropertiesSidebar(
                selectedShape: groupedShape,
                selectedShapesCount: 1,
                canUngroup: true,
                onUngroupShapes: () => ungroupCalled = true,
                onDuplicateShape: () {},
                onDeleteSelected: () {},
                onShapeChanged: (_) {},
                onOpenColorPickerFill: ([_]) {},
                onOpenColorPickerStroke: ([_]) {},
                onAlignShape: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ungroupBtn = find.byTooltip('Ungroup (Ctrl+Shift+G)');
      expect(ungroupBtn, findsOneWidget);

      await tester.tap(ungroupBtn);
      await tester.pumpAndSettle();
      expect(ungroupCalled, isTrue);
    });
  });
}
