// ignore_for_file: invalid_use_of_protected_member
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/widgets/layers_sidebar.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M3PhysicsPressable UX Spring Tests', () {
    testWidgets('Renders child and triggers onTap callback cleanly', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: M3PhysicsPressable(
                onTap: () => tapped = true,
                tooltip: 'Test Button',
                enableHoverHighlight: true,
                child: const Text('Press Me'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);
      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('Delivers tactile scale feedback on pointer enter and exit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: M3PhysicsPressable(
                onTap: () {},
                hoverScale: 1.05,
                pressedScale: 0.95,
                enableHoverHighlight: true,
                child: const SizedBox(
                  width: 100,
                  height: 40,
                  child: Text('Hover Target'),
                ),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      // Move mouse over target
      await gesture.moveTo(tester.getCenter(find.text('Hover Target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hover Target'), findsOneWidget);

      // Exit mouse
      await gesture.moveTo(const Offset(500, 500));
      await tester.pump();
      await tester.pumpAndSettle();
    });
  });

  group('Compact Mode Drawer Slide & Scrim UX Tests', () {
    testWidgets('Compact mode shows scrim and allows tap-to-dismiss for Layers drawer', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final shape = VectorShape(
        id: 's1',
        name: 'Rectangle 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(50, 50, 100, 100),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FigmaWorkspace(
              initialProject: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final workspaceState = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Add a test shape
      workspaceState.shapes.add(shape);
      workspaceState.setState(() {});
      await tester.pumpAndSettle();

      // Open layers panel in compact mode
      workspaceState.setState(() {
        workspaceState.isLayersPanelOpen = true;
      });
      await tester.pumpAndSettle();

      // Drawer and Layers sidebar should be present
      expect(find.byType(LayersSidebar), findsOneWidget);

      // Scrim should be present (Backdrop scrim)
      final backdropFinder = find.byWidgetPredicate(
        (w) => w is Container && w.color != null && w.color!.a > 0.0,
      );
      expect(backdropFinder, findsWidgets);

      // Tap on scrim (e.g. at right edge of screen outside drawer)
      await tester.tapAt(const Offset(550, 400));
      await tester.pumpAndSettle();

      // Layers panel should now be dismissed
      expect(workspaceState.isLayersPanelOpen, isFalse);
    });

    testWidgets('Compact mode shows scrim and allows tap-to-dismiss for Properties drawer', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final shape = VectorShape(
        id: 's1',
        name: 'Rectangle 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(50, 50, 100, 100),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FigmaWorkspace(
              initialProject: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final workspaceState = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );

      // Select shape and open properties panel
      workspaceState.shapes.add(shape);
      workspaceState.selectedShapeIds.add('s1');
      workspaceState.setState(() {
        workspaceState.isPropertiesPanelOpen = true;
      });
      await tester.pumpAndSettle();

      // Properties sidebar should be visible
      expect(find.byType(PropertiesSidebar), findsOneWidget);

      // Tap on scrim (e.g. at left edge of screen outside right drawer)
      await tester.tapAt(const Offset(50, 400));
      await tester.pumpAndSettle();

      // Properties panel should now be dismissed
      expect(workspaceState.isPropertiesPanelOpen, isFalse);
    });
  });
}
