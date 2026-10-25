import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_dropdown_menu/m3e_dropdown_menu.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PropertiesSidebar with line and curve renders and changes properties smoothly', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    VectorShape currentShape = VectorShape(
      id: 'line-1',
      name: 'Line 1',
      type: ShapeType.line,
      rect: const Rect.fromLTRB(100, 100, 300, 200),
      isStroked: true,
      strokeWidth: 2.0,
      startCap: LineCapStyle.none,
      endCap: LineCapStyle.arrow,
      isCurved: true,
      curvature: 30.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 320,
                height: 1000,
                child: PropertiesSidebar(
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
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('START & END POINTS'), findsOneWidget);
    expect(find.text('CURVE / BEND'), findsOneWidget);
    expect(find.text('Bend: 30 px'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Tap reset button
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(currentShape.curvature, 0.0);
    expect(find.text('Bend: 0 px'), findsOneWidget);

    // Toggle switch off
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(currentShape.isCurved, isFalse);

    // Toggle switch back on
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(currentShape.isCurved, isTrue);
    expect(currentShape.curvature, 30.0);

    // Find M3E dropdowns
    final m3eDropdowns = find.byType(M3EDropdownMenu<LineCapStyle>);
    expect(m3eDropdowns, findsNWidgets(2));
  });
}
