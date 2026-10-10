import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/floating_tool_bar.dart';
import 'package:nixsvg/widgets/layers_sidebar.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';
import 'package:remixicon/remixicon.dart';

void main() {
  testWidgets('inspect floating toolbar buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: FloatingToolBar(
            currentMode: EditorMode.select,
            onModeChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(FloatingToolBar), findsOneWidget);
  });

  testWidgets('inspect layers sidebar with M3EReorderableSegmentedList', (tester) async {
    final shapes = [
      VectorShape(
        id: '1',
        name: 'Rectangle 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 100, 100),
      ),
      VectorShape(
        id: '2',
        name: 'Circle 1',
        type: ShapeType.ellipse,
        rect: const Rect.fromLTWH(10, 10, 50, 50),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: LayersSidebar(
            shapes: shapes,
            selectedShapeIds: {'1'},
            onSelectShape: (_) {},
            onToggleVisibility: (_) {},
            onToggleLock: (_) {},
            onDeleteShape: (_) {},
            onBringForward: () {},
            onSendBackward: () {},
            onRenameShape: (_, _) {},
            onReorder: (oldIdx, newIdx) {},
          ),
        ),
      ),
    );

    expect(find.byType(LayersSidebar), findsOneWidget);
    expect(find.byType(M3EReorderableSegmentedList), findsOneWidget);
    expect(find.text('Rectangle 1'), findsOneWidget);
    expect(find.text('Circle 1'), findsOneWidget);
  });

  testWidgets('inspect properties sidebar with 2 connected alignment rows', (tester) async {
    String aligned = '';
    final shape = VectorShape(
      id: 'shape-1',
      name: 'Test Rectangle',
      type: ShapeType.rectangle,
      rect: const Rect.fromLTWH(50, 50, 100, 100),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PropertiesSidebar(
            selectedShape: shape,
            onShapeChanged: (_) {},
            onOpenColorPickerFill: () {},
            onOpenColorPickerStroke: () {},
            onDuplicateShape: () {},
            onDeleteSelected: () {},
            onAlignShape: (val) => aligned = val,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 2 connected M3ESegmentedRow instances for alignment
    expect(find.byType(M3ESegmentedRow), findsNWidgets(2));

    // Tap horizontal align center in row 1
    await tester.tap(find.byIcon(RemixIcons.align_center));
    expect(aligned, 'center');

    // Tap vertical align middle in row 2
    await tester.tap(find.byIcon(RemixIcons.align_vertically));
    expect(aligned, 'middle');
  });
}

