import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Figma-like Property Scrubbing Tests (Press and Hold / Drag on Label)', () {
    testWidgets('Hovering on PTS and % labels shows resizeLeftRight mouse cursor', (tester) async {
      final star = VectorShape(
        id: 'star-scrub-1',
        name: 'Star Element',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        pointCount: 5,
        innerRadiusRatio: 0.4,
        cornerRadius: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertiesSidebar(
              selectedShape: star,
              onShapeChanged: (_) {},
              onOpenColorPickerFill: ([_]) {},
              onOpenColorPickerStroke: ([_]) {},
              onDuplicateShape: () {},
              onDeleteSelected: () {},
              onAlignShape: (_) {},
              totalShapesCount: 1,
              zoomScale: 1.0,
              isPanMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ptsFinder = find.text('PTS');
      expect(ptsFinder, findsOneWidget);

      final ptsMouseRegion = tester.widget<MouseRegion>(
        find.ancestor(of: ptsFinder, matching: find.byType(MouseRegion)).first,
      );
      expect(ptsMouseRegion.cursor, SystemMouseCursors.resizeLeftRight);

      final ratioLabelFinder = find.text('Ratio');
      expect(ratioLabelFinder, findsOneWidget);

      final ratioMouseRegion = tester.widget<MouseRegion>(
        find.ancestor(of: ratioLabelFinder, matching: find.byType(MouseRegion)).first,
      );
      expect(ratioMouseRegion.cursor, SystemMouseCursors.resizeLeftRight);
    });

    testWidgets('Dragging right on PTS increases points, dragging left decreases points', (tester) async {
      VectorShape currentShape = VectorShape(
        id: 'star-scrub-2',
        name: 'Star Element',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        pointCount: 5,
        innerRadiusRatio: 0.4,
        cornerRadius: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PropertiesSidebar(
                  selectedShape: currentShape,
                  onShapeChanged: (updated) {
                    setState(() {
                      currentShape = updated;
                    });
                  },
                  onOpenColorPickerFill: ([_]) {},
                  onOpenColorPickerStroke: ([_]) {},
                  onDuplicateShape: () {},
                  onDeleteSelected: () {},
                  onAlignShape: (_) {},
                  totalShapesCount: 1,
                  zoomScale: 1.0,
                  isPanMode: false,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ptsFinder = find.text('PTS');
      expect(ptsFinder, findsOneWidget);

      // Drag right by 40 pixels -> should increase points from 5 to higher
      await tester.drag(ptsFinder, const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(currentShape.pointCount, greaterThan(5));
      final increasedPoints = currentShape.pointCount;

      // Drag left by 80 pixels -> should decrease points back down
      await tester.drag(ptsFinder, const Offset(-80, 0));
      await tester.pumpAndSettle();

      expect(currentShape.pointCount, lessThan(increasedPoints));
      // Min limit test: points should never go below 3
      await tester.drag(ptsFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(currentShape.pointCount, equals(3));
    });

    testWidgets('Dragging on Ratio label adjusts inner radius ratio', (tester) async {
      VectorShape currentShape = VectorShape(
        id: 'star-scrub-3',
        name: 'Star Element',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        pointCount: 5,
        innerRadiusRatio: 0.4,
        cornerRadius: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PropertiesSidebar(
                  selectedShape: currentShape,
                  onShapeChanged: (updated) {
                    setState(() {
                      currentShape = updated;
                    });
                  },
                  onOpenColorPickerFill: ([_]) {},
                  onOpenColorPickerStroke: ([_]) {},
                  onDuplicateShape: () {},
                  onDeleteSelected: () {},
                  onAlignShape: (_) {},
                  totalShapesCount: 1,
                  zoomScale: 1.0,
                  isPanMode: false,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ratioFinder = find.text('Ratio');
      expect(ratioFinder, findsOneWidget);

      // Drag right on Ratio label to increase ratio
      await tester.drag(ratioFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(currentShape.innerRadiusRatio, greaterThan(0.4));

      // Drag left on Ratio label to decrease ratio
      await tester.drag(ratioFinder, const Offset(-100, 0));
      await tester.pumpAndSettle();

      expect(currentShape.innerRadiusRatio, lessThan(0.65));
      expect(currentShape.innerRadiusRatio, greaterThanOrEqualTo(0.05));
    });

    testWidgets('Dragging on W and H labels scrubs dimensions', (tester) async {
      VectorShape currentShape = VectorShape(
        id: 'rect-scrub',
        name: 'Rectangle',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(100, 100, 200, 150),
        cornerRadius: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PropertiesSidebar(
                  selectedShape: currentShape,
                  onShapeChanged: (updated) {
                    setState(() {
                      currentShape = updated;
                    });
                  },
                  onOpenColorPickerFill: ([_]) {},
                  onOpenColorPickerStroke: ([_]) {},
                  onDuplicateShape: () {},
                  onDeleteSelected: () {},
                  onAlignShape: (_) {},
                  totalShapesCount: 1,
                  zoomScale: 1.0,
                  isPanMode: false,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final wFinder = find.text('W').first;
      // Drag right on W -> increases width
      await tester.drag(wFinder, const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(currentShape.rect.width, greaterThan(200));

      final hFinder = find.text('H').first;
      // Drag left on H -> decreases height
      await tester.drag(hFinder, const Offset(-50, 0));
      await tester.pumpAndSettle();
      expect(currentShape.rect.height, lessThan(150));
    });

    testWidgets('Tapping on a property label focuses the input field', (tester) async {
      final star = VectorShape(
        id: 'star-tap',
        name: 'Star Element',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        pointCount: 5,
        innerRadiusRatio: 0.4,
        cornerRadius: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertiesSidebar(
              selectedShape: star,
              onShapeChanged: (_) {},
              onOpenColorPickerFill: ([_]) {},
              onOpenColorPickerStroke: ([_]) {},
              onDuplicateShape: () {},
              onDeleteSelected: () {},
              onAlignShape: (_) {},
              totalShapesCount: 1,
              zoomScale: 1.0,
              isPanMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ptsFinder = find.text('PTS');
      await tester.tap(ptsFinder);
      await tester.pumpAndSettle();

      // Find the TextFormField next to PTS in the same row and ensure focus is active
      final ptsRow = find.ancestor(of: ptsFinder, matching: find.byType(Row)).first;
      final textFormField = find.descendant(of: ptsRow, matching: find.byType(TextFormField));
      final editableText = tester.widget<EditableText>(
        find.descendant(of: textFormField, matching: find.byType(EditableText)),
      );
      expect(editableText.focusNode.hasFocus, isTrue);
    });
  });
}
