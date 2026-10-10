import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/main.dart';

void main() {
  testWidgets('NixSvgApp smoke test and button theme matching', (WidgetTester tester) async {
    // Build NixSvgApp and trigger a frame.
    await tester.pumpWidget(const NixSvgApp());

    // Verify that the title logo is displayed.
    expect(find.text('nixSVG'), findsOneWidget);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = materialApp.theme!;
    final darkTheme = materialApp.darkTheme!;

    // Verify light button themes
    expect(theme.filledButtonTheme.style, isNotNull);
    expect(theme.elevatedButtonTheme.style, isNotNull);
    expect(theme.outlinedButtonTheme.style, isNotNull);
    expect(theme.textButtonTheme.style, isNotNull);
    expect(theme.iconButtonTheme.style, isNotNull);
    expect(theme.segmentedButtonTheme.style, isNotNull);
    expect(theme.floatingActionButtonTheme.elevation, 0);
    expect(theme.chipTheme.elevation, 0);
    expect(theme.shadowColor, Colors.transparent);

    // Verify dark button themes
    expect(darkTheme.filledButtonTheme.style, isNotNull);
    expect(darkTheme.elevatedButtonTheme.style, isNotNull);
    expect(darkTheme.outlinedButtonTheme.style, isNotNull);
    expect(darkTheme.textButtonTheme.style, isNotNull);
    expect(darkTheme.iconButtonTheme.style, isNotNull);
    expect(darkTheme.segmentedButtonTheme.style, isNotNull);
    expect(darkTheme.floatingActionButtonTheme.elevation, 0);
    expect(darkTheme.chipTheme.elevation, 0);
    expect(darkTheme.shadowColor, Colors.transparent);
  });

  testWidgets('M3EButton resolves dark theme colors in dark mode', (WidgetTester tester) async {
    themeController.setThemeMode(ThemeMode.dark);
    await tester.pumpWidget(const NixSvgApp());
    await tester.pumpAndSettle();

    final m3eButtons = find.byType(M3EButton);
    expect(m3eButtons, findsWidgets);

    // Verify mui.Theme is present in the tree
    final muiThemes = find.byWidgetPredicate((w) => w is mui.Theme);
    expect(muiThemes, findsWidgets);

    final rootMuiTheme = tester.widget<mui.Theme>(muiThemes.first);
    expect(rootMuiTheme.data.brightness, Brightness.dark);
    expect(rootMuiTheme.data.shadowColor, Colors.transparent);
  });

  testWidgets('Select and move shapes on interactive canvas', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NixSvgApp());
    await tester.pumpAndSettle();

    // Verify FigmaWorkspace is present
    expect(find.byType(FigmaWorkspace), findsOneWidget);

    final state = tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));
    expect(state.shapes.isNotEmpty, isTrue);

    final firstShape = state.shapes.first;
    final initialTopLeft = firstShape.rect.topLeft;

    // Convert local canvas shape coordinate (top-left corner of shape-1: 215, 165) to global screen coordinate
    final containerFinder = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxWidth == 3200,
    );
    final RenderBox renderBox = tester.renderObject(containerFinder);
    final shapeScreenPos = renderBox.localToGlobal(const Offset(215, 165));

    // Simulate pointer down inside first shape
    final gesture = await tester.startGesture(shapeScreenPos);
    await tester.pump();

    // Verify first shape is selected
    expect(state.selectedShapeIds.contains(firstShape.id), isTrue);

    // Drag 60px right and 60px down
    await gesture.moveBy(const Offset(60, 60));
    await tester.pump();

    // End drag
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify shape position changed
    expect(state.shapes.first.rect.topLeft != initialTopLeft, isTrue);
  });

  testWidgets('Marquee drag selection selects shapes', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NixSvgApp());
    await tester.pumpAndSettle();

    final state = tester.state<FigmaWorkspaceState>(find.byType(FigmaWorkspace));

    final containerFinder = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxWidth == 3200,
    );
    final RenderBox renderBox = tester.renderObject(containerFinder);

    // Start marquee drag from empty space (100, 100) to (700, 500) enclosing multiple demo shapes
    final marqueeStart = renderBox.localToGlobal(const Offset(100, 100));
    final marqueeEnd = renderBox.localToGlobal(const Offset(700, 500));

    final gesture = await tester.startGesture(marqueeStart);
    await tester.pump();
    await gesture.moveTo(marqueeEnd);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify multiple shapes selected
    expect(state.selectedShapeIds.length, greaterThanOrEqualTo(2));
  });
}

