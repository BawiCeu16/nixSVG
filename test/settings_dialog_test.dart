import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/grid_painter.dart';
import 'package:nixsvg/providers/app_settings_provider.dart';
import 'package:nixsvg/providers/preferences_provider.dart';
import 'package:nixsvg/services/preferences_service.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/widgets/floating_tool_bar.dart';
import 'package:nixsvg/widgets/settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService Settings Unit Tests', () {
    test('Default values are initialized correctly', () {
      final prefs = PreferencesService.fallback();
      expect(prefs.getGridStyle(), 'dots');
      expect(prefs.getDefaultCanvasBgColor(), null);
      expect(prefs.getSmartGuides(), true);
      expect(prefs.getInvertZoom(), false);
      expect(prefs.getDefaultStrokeWidth(), 2.0);
      expect(prefs.getDefaultCornerRadius(), 8.0);
      expect(prefs.getAutoSwitchToSelect(), false);
      expect(prefs.getSvgPrettyPrint(), true);
      expect(prefs.getSvgIncludeXml(), true);
      expect(prefs.getExportScale(), 2.0);
      expect(prefs.getToolbarPosition(), 'bottom');
      expect(prefs.getOledDark(), false);
      expect(prefs.getUiScale(), 1.0);
    });

    test('Setters and getters update accurately', () async {
      final prefs = PreferencesService.fallback();
      await prefs.setGridStyle('lines');
      expect(prefs.getGridStyle(), 'lines');

      await prefs.setSmartGuides(false);
      expect(prefs.getSmartGuides(), false);

      await prefs.setInvertZoom(true);
      expect(prefs.getInvertZoom(), true);

      await prefs.setDefaultStrokeWidth(5.0);
      expect(prefs.getDefaultStrokeWidth(), 5.0);

      await prefs.setExportScale(3.0);
      expect(prefs.getExportScale(), 3.0);

      await prefs.setOledDark(true);
      expect(prefs.getOledDark(), true);
    });

    test('resetAllToDefaults restores all preferences', () async {
      final prefs = PreferencesService.fallback();
      await prefs.setGridStyle('crosses');
      await prefs.setSmartGuides(false);
      await prefs.setDefaultStrokeWidth(10.0);
      await prefs.setExportScale(4.0);

      await prefs.resetAllToDefaults();

      expect(prefs.getGridStyle(), 'dots');
      expect(prefs.getSmartGuides(), true);
      expect(prefs.getDefaultStrokeWidth(), 2.0);
      expect(prefs.getExportScale(), 2.0);
    });

    test('exportSettingsMap and importSettingsMap cycle properly', () async {
      final prefs = PreferencesService.fallback();
      await prefs.setGridStyle('lines');
      await prefs.setDefaultStrokeWidth(6.5);

      final exported = prefs.exportSettingsMap();
      expect(exported['gridStyle'], 'lines');
      expect(exported['defaultStrokeWidth'], 6.5);

      final newPrefs = PreferencesService.fallback();
      await newPrefs.importSettingsMap(exported);
      expect(newPrefs.getGridStyle(), 'lines');
      expect(newPrefs.getDefaultStrokeWidth(), 6.5);
    });
  });

  group('AppSettingsNotifier Riverpod Tests', () {
    test('State initializes from PreferencesService and updates reactively', () async {
      final prefs = PreferencesService.fallback();
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(appSettingsProvider);
      expect(initial.gridStyle, 'dots');
      expect(initial.smartGuides, true);
      expect(initial.defaultStrokeWidth, 2.0);

      final notifier = container.read(appSettingsProvider.notifier);
      notifier.setGridStyle('lines');
      expect(container.read(appSettingsProvider).gridStyle, 'lines');
      expect(prefs.getGridStyle(), 'lines');

      notifier.setDefaultStrokeWidth(4.0);
      expect(container.read(appSettingsProvider).defaultStrokeWidth, 4.0);
      expect(prefs.getDefaultStrokeWidth(), 4.0);

      notifier.setSnapToGrid(false);
      expect(container.read(appSettingsProvider).snapToGrid, false);
    });
  });

  group('SettingsDialog Widget Tests', () {
    testWidgets('Renders full screen SettingsDialog with categories on wide screen', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = PreferencesService.fallback();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header bar
      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search box
      expect(find.text('Reset Defaults'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Check wide-screen left navigation tabs
      expect(find.text('Appearance'), findsWidgets);
      expect(find.text('Canvas & Grid'), findsWidgets);
      expect(find.text('Panels & Workspace'), findsWidgets);
      expect(find.text('Vector Tools'), findsWidgets);
      expect(find.text('Export & Formats'), findsWidgets);
      expect(find.text('Projects & Storage'), findsWidgets);
      expect(find.text('About nixSVG'), findsWidgets);

      // Default tab is Appearance
      expect(find.text('Appearance & Styling'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
    });

    testWidgets('Switching categories updates right side content', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = PreferencesService.fallback();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Canvas & Grid tab
      await tester.tap(find.text('Canvas & Grid').first);
      await tester.pumpAndSettle();

      expect(find.text('Canvas & Grid Settings'), findsOneWidget);
      expect(find.text('Snap to Grid'), findsOneWidget);
      expect(find.text('Smart Alignment Guides'), findsOneWidget);

      // Tap on Vector Tools tab
      await tester.tap(find.text('Vector Tools').first);
      await tester.pumpAndSettle();

      expect(find.text('Vector Tools & Editing Experience'), findsOneWidget);
      expect(find.text('Default Stroke Width'), findsOneWidget);

      // Tap on About nixSVG tab
      await tester.tap(find.text('About nixSVG').first);
      await tester.pumpAndSettle();

      expect(find.text('nixSVG Studio'), findsOneWidget);
      expect(find.text('Version 1.0.0 (Material 3 Expressive & macOS Studio)'), findsOneWidget);
    });

    testWidgets('Toggling switch updates setting in real time', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = PreferencesService.fallback();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Canvas & Grid
      await tester.tap(find.text('Canvas & Grid').first);
      await tester.pumpAndSettle();

      // Toggle Snap to Grid switch (initially true, toggling makes it false)
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      expect(prefs.getSnapToGrid(), false);
    });

    testWidgets('Search query filters setting items across categories', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = PreferencesService.fallback();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type in search query: "pretty"
      await tester.enterText(find.byType(TextField), 'pretty');
      await tester.pumpAndSettle();

      expect(find.text('SVG Pretty-Printing'), findsOneWidget);
      // Other non-matching items should not appear
      expect(find.text('OLED High Contrast'), findsNothing);
    });

    testWidgets('Compact width displays horizontal category chips', (
      WidgetTester tester,
    ) async {
      // Small screen size (mobile / phone)
      await tester.binding.setSurfaceSize(const Size(400, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = PreferencesService.fallback();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Category chips should be present in ChoiceChip format
      expect(find.byType(ChoiceChip), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Pressing Done button dismisses the dialog', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = PreferencesService.fallback();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAppSettingsDialog(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsDialog), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsDialog), findsNothing);
    });
  });

  group('Settings Live Effects & App Integration Tests', () {
    test('GridPainter renders crosses, lines, and dots without errors', () {
      final dotsPainter = GridPainter(gridStyle: 'dots', gridSpacing: 40);
      final linesPainter = GridPainter(gridStyle: 'lines', gridSpacing: 40);
      final crossesPainter = GridPainter(gridStyle: 'crosses', gridSpacing: 40);

      expect(dotsPainter.shouldRepaint(linesPainter), isTrue);
      expect(linesPainter.shouldRepaint(crossesPainter), isTrue);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200, 200);

      dotsPainter.paint(canvas, size);
      linesPainter.paint(canvas, size);
      crossesPainter.paint(canvas, size);
      recorder.endRecording();
    });

    test('SvgExportService applies includeXmlHeader, prettyPrint, and exportScale', () {
      final shapes = [
        VectorShape(
          id: 'test-shape',
          name: 'Rect',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(10, 10, 100, 100),
        ),
      ];

      final withXml = SvgExportService.generateSvg(
        shapes,
        includeXmlHeader: true,
        prettyPrint: true,
        exportScale: 2.0,
      );
      expect(withXml.contains('<?xml version="1.0"'), isTrue);
      expect(withXml.contains('width="3840"'), isTrue);
      expect(withXml.contains('height="2160"'), isTrue);

      final withoutXml = SvgExportService.generateSvg(
        shapes,
        includeXmlHeader: false,
        prettyPrint: false,
        exportScale: 1.0,
      );
      expect(withoutXml.contains('<?xml'), isFalse);
      expect(withoutXml.contains('\n'), isFalse);
    });

    testWidgets('FigmaWorkspace dynamically repositions toolbar when toolbarPosition setting changes', (tester) async {
      final prefs = PreferencesService.fallback();
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FigmaWorkspace(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Positioned containing FloatingToolBar
      Positioned findToolbarPositioned() {
        return tester.widget<Positioned>(
          find.ancestor(
            of: find.byType(FloatingToolBar),
            matching: find.byType(Positioned),
          ).first,
        );
      }

      // Initial toolbar is at bottom
      expect(findToolbarPositioned().bottom, isNotNull);
      expect(findToolbarPositioned().top, isNull);

      // Change setting to top
      container.read(appSettingsProvider.notifier).setToolbarPosition('top');
      await tester.pumpAndSettle();

      // Toolbar is now positioned at top!
      expect(findToolbarPositioned().top, 16.0);
      expect(findToolbarPositioned().bottom, isNull);

      // Change back to bottom
      container.read(appSettingsProvider.notifier).setToolbarPosition('bottom');
      await tester.pumpAndSettle();

      expect(findToolbarPositioned().bottom, isNotNull);
      expect(findToolbarPositioned().top, isNull);
    });
  });
}
