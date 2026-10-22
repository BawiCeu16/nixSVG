import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/widgets/layers_sidebar.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VectorShape Grouping Model Tests', () {
    test('VectorShape stores groupId and groupName correctly', () {
      final shape = VectorShape(
        id: 's1',
        name: 'Rectangle 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 100, 100),
        groupId: 'grp-1',
        groupName: 'Group 1',
      );

      expect(shape.groupId, 'grp-1');
      expect(shape.groupName, 'Group 1');

      final copy = shape.copyWith(groupName: 'Updated Group');
      expect(copy.groupId, 'grp-1');
      expect(copy.groupName, 'Updated Group');

      final cleared = shape.copyWith(clearGroup: true);
      expect(cleared.groupId, isNull);
      expect(cleared.groupName, isNull);
    });

    test('VectorShape JSON serialization preserves group attributes', () {
      final shape = VectorShape(
        id: 's1',
        name: 'Circle 1',
        type: ShapeType.ellipse,
        rect: const Rect.fromLTWH(10, 20, 80, 80),
        groupId: 'g-123',
        groupName: 'Group 1',
      );

      final json = shape.toJson();
      expect(json['groupId'], 'g-123');
      expect(json['groupName'], 'Group 1');

      final restored = VectorShape.fromJson(json);
      expect(restored.groupId, 'g-123');
      expect(restored.groupName, 'Group 1');
    });
  });

  group('SvgExportService Grouping Serialization Tests', () {
    test('generateSvg serializes grouped shapes inside <g id="..."> tag', () {
      final s1 = VectorShape(
        id: 's1',
        name: 'Rect A',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 50, 50),
        groupId: 'grp-header',
        groupName: 'Header Group',
      );
      final s2 = VectorShape(
        id: 's2',
        name: 'Rect B',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(60, 0, 50, 50),
        groupId: 'grp-header',
        groupName: 'Header Group',
      );
      final s3 = VectorShape(
        id: 's3',
        name: 'Standalone',
        type: ShapeType.ellipse,
        rect: const Rect.fromLTWH(200, 200, 40, 40),
      );

      final svg = SvgExportService.generateSvg(
        [s1, s2, s3],
        scope: SvgExportScope.artwork,
        includeXmlHeader: false,
      );

      expect(svg, contains('<g id="Header Group">'));
      expect(svg, contains('</g>'));
    });
  });

  group('PropertiesSidebar Grouping UI Tests', () {
    testWidgets('PropertiesSidebar displays Group and Ungroup buttons and group badge', (
      WidgetTester tester,
    ) async {
      bool groupTriggered = false;
      bool ungroupTriggered = false;

      final groupedShape = VectorShape(
        id: 's1',
        name: 'Card Bg',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 200, 100),
        groupId: 'g1',
        groupName: 'Hero Group',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: PropertiesSidebar(
                width: 320,
                selectedShape: groupedShape,
                onShapeChanged: (_) {},
                onOpenColorPickerFill: ([_]) {},
                onOpenColorPickerStroke: ([_]) {},
                onDuplicateShape: () {},
                onDeleteSelected: () {},
                onAlignShape: (_) {},
                onGroupShapes: () => groupTriggered = true,
                onUngroupShapes: () => ungroupTriggered = true,
                canGroup: true,
                canUngroup: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for group name pill
      expect(find.text('Hero Group'), findsOneWidget);

      // Check Group button
      final groupBtn = find.byTooltip('Group (Ctrl+G)');
      expect(groupBtn, findsOneWidget);
      await tester.tap(groupBtn);
      expect(groupTriggered, isTrue);

      // Check Ungroup button
      final ungroupBtn = find.byTooltip('Ungroup (Ctrl+Shift+G)');
      expect(ungroupBtn, findsOneWidget);
      await tester.tap(ungroupBtn);
      expect(ungroupTriggered, isTrue);
    });
  });

  group('LayersSidebar Grouping Interaction Tests', () {
    testWidgets('Clicking a grouped layer selects all group members', (
      WidgetTester tester,
    ) async {
      final s1 = VectorShape(
        id: 's1',
        name: 'Shape A',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 50, 50),
        groupId: 'grp-cards',
        groupName: 'Cards Group',
      );
      final s2 = VectorShape(
        id: 's2',
        name: 'Shape B',
        type: ShapeType.ellipse,
        rect: const Rect.fromLTWH(100, 0, 50, 50),
        groupId: 'grp-cards',
        groupName: 'Cards Group',
      );
      final s3 = VectorShape(
        id: 's3',
        name: 'Shape C',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(200, 0, 50, 50),
      );

      Set<String> selectedIds = {'s3'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LayersSidebar(
                  shapes: [s1, s2, s3],
                  selectedShapeIds: selectedIds,
                  onSelectShape: (id) {
                    setState(() => selectedIds = {id});
                  },
                  onSelectShapes: (ids) {
                    setState(() => selectedIds = Set<String>.from(ids));
                  },
                  onToggleVisibility: (_) {},
                  onToggleLock: (_) {},
                  onDeleteShape: (_) {},
                  onBringForward: () {},
                  onSendBackward: () {},
                  onRenameShape: (_, _) {},
                  onGroupShapes: () {},
                  onUngroupShapes: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check group pill indicator appears
      expect(find.text('Cards Group'), findsNWidgets(2));

      // Tap on Shape A row -> should select both s1 and s2
      await tester.tap(find.text('Shape A'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(selectedIds, contains('s1'));
      expect(selectedIds, contains('s2'));
      expect(selectedIds, isNot(contains('s3')));
    });

    testWidgets('LayersSidebar context menu has Group and Ungroup actions', (
      WidgetTester tester,
    ) async {
      bool ungroupCalled = false;

      final s1 = VectorShape(
        id: 's1',
        name: 'Shape A',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 50, 50),
        groupId: 'grp-cards',
        groupName: 'Cards Group',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayersSidebar(
              shapes: [s1],
              selectedShapeIds: {'s1'},
              onSelectShape: (_) {},
              onToggleVisibility: (_) {},
              onToggleLock: (_) {},
              onDeleteShape: (_) {},
              onBringForward: () {},
              onSendBackward: () {},
              onRenameShape: (_, _) {},
              onGroupShapes: () {},
              onUngroupShapes: () => ungroupCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Right-click layer row to open context menu
      await tester.tap(
        find.text('Shape A'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(find.text('Group Selection'), findsOneWidget);
      expect(find.text('Ungroup Selection'), findsOneWidget);

      await tester.tap(find.text('Ungroup Selection'));
      await tester.pumpAndSettle();

      expect(ungroupCalled, isTrue);
    });
  });

  group('FigmaWorkspace Grouping and Ungrouping Workflow Tests', () {
    testWidgets('FigmaWorkspace supports grouping via Ctrl+G and ungrouping via Ctrl+Shift+G', (
      WidgetTester tester,
    ) async {
      final s1 = VectorShape(
        id: 'shape-1',
        name: 'Rectangle 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(50, 50, 100, 100),
      );
      final s2 = VectorShape(
        id: 'shape-2',
        name: 'Rectangle 2',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(200, 50, 100, 100),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FigmaWorkspace(
              initialProject: ProjectModel.createNew(
                name: 'Test Project',
                shapes: [s1, s2],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select both shapes using Ctrl+A
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Press Ctrl+G to group them
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Expect snackbar feedback and group badges
      expect(find.text('Grouped as Group 1'), findsOneWidget);

      // Now press Ctrl+Shift+G to ungroup them
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.text('Ungrouped selection'), findsOneWidget);
    });
  });
}
