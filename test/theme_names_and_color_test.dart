import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/providers/preferences_provider.dart';
import 'package:nixsvg/services/preferences_service.dart';
import 'package:nixsvg/theme/app_theme.dart';
import 'package:nixsvg/ui/home/home_screen.dart';
import 'package:nixsvg/widgets/settings_dialog.dart';
import 'package:nixsvg/widgets/top_navigation_bar.dart';

void main() {
  group('Theme Names and Color Unit Tests', () {
    test('Theme presets are properly defined with correct names and colors', () {
      expect(ThemeController.presets.length, 8);
      expect(AppTheme.presets.length, 8);

      final expectedNames = [
        'Indigo',
        'Emerald',
        'Blue',
        'Violet',
        'Pink',
        'Amber',
        'Cyan',
        'Rose',
      ];

      final expectedColors = [
        const Color(0xFF6366F1),
        const Color(0xFF10B981),
        const Color(0xFF3B82F6),
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
        const Color(0xFFF59E0B),
        const Color(0xFF06B6D4),
        const Color(0xFFF43F5E),
      ];

      for (int i = 0; i < 8; i++) {
        expect(ThemeController.presets[i].name, expectedNames[i]);
        expect(ThemeController.presets[i].color, expectedColors[i]);
        expect(ThemeController.themePresets[i], expectedColors[i]);
        expect(ThemeController.getColorName(expectedColors[i]), expectedNames[i]);
        expect(AppTheme.getColorName(expectedColors[i]), expectedNames[i]);
      }
    });

    test('getColorName handles fallbacks, aliases, and custom colors correctly', () {
      expect(ThemeController.getColorName(const Color(0xFF0EA5E9)), 'Sky');
      expect(ThemeController.getColorName(const Color(0xFFE11D48)), 'Rose');
      expect(ThemeController.getColorName(const Color(0xFF123456)), 'Custom');
    });

    test('getThemeModeName returns proper descriptive strings', () {
      expect(ThemeController.getThemeModeName(ThemeMode.light), 'Light');
      expect(ThemeController.getThemeModeName(ThemeMode.dark), 'Dark');
      expect(ThemeController.getThemeModeName(ThemeMode.system), 'System');
    });
  });

  group('Theme Dropdown UI Widget Tests', () {
    testWidgets('TopNavigationBar theme dropdown displays all preset names correctly', (
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
            home: Scaffold(
              body: TopNavigationBar(
                fileName: 'Test Project',
                onFileNameChanged: (_) {},
                canUndo: false,
                canRedo: false,
                onUndo: () {},
                onRedo: () {},
                snapToGrid: false,
                onSnapToGridChanged: (_) {},
                onExportSvg: () {},
                onImportImage: () {},
                onShowShortcuts: () {},
                onClearCanvas: () {},
                zoomScale: 1.0,
                onZoomIn: () {},
                onZoomOut: () {},
                onResetZoom: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the palette popup menu button
      final paletteFinder = find.byTooltip('Theme Accent: Indigo');
      expect(paletteFinder, findsOneWidget);

      // Tap to open popup menu
      await tester.tap(paletteFinder);
      await tester.pumpAndSettle();

      // All 8 preset names must be present in the dropdown menu
      expect(find.text('Indigo'), findsOneWidget);
      expect(find.text('Emerald'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Violet'), findsOneWidget);
      expect(find.text('Pink'), findsOneWidget);
      expect(find.text('Amber'), findsOneWidget);
      expect(find.text('Cyan'), findsOneWidget);
      expect(find.text('Rose'), findsOneWidget);

      // Verify broken label 'Dynamic Seed' does not exist
      expect(find.text('Dynamic Seed'), findsNothing);
    });

    testWidgets('HomeScreen theme dropdown displays all preset names correctly', (
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
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final themeButton = find.byTooltip('Theme Accent: Indigo');
      expect(themeButton, findsOneWidget);

      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.text('Indigo'), findsOneWidget);
      expect(find.text('Emerald'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Violet'), findsOneWidget);
      expect(find.text('Pink'), findsOneWidget);
      expect(find.text('Amber'), findsOneWidget);
      expect(find.text('Cyan'), findsOneWidget);
      expect(find.text('Rose'), findsOneWidget);
    });

    testWidgets('SettingsDialog displays color tooltips and active accent name', (
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

      // Check active subtitle displays Indigo
      expect(
        find.textContaining('Active: Indigo'),
        findsOneWidget,
      );

      // Tooltips for color circles must be present
      expect(find.byTooltip('Indigo'), findsOneWidget);
      expect(find.byTooltip('Emerald'), findsOneWidget);
      expect(find.byTooltip('Blue'), findsOneWidget);
      expect(find.byTooltip('Violet'), findsOneWidget);
      expect(find.byTooltip('Pink'), findsOneWidget);
      expect(find.byTooltip('Amber'), findsOneWidget);
      expect(find.byTooltip('Cyan'), findsOneWidget);
      expect(find.byTooltip('Rose'), findsOneWidget);
    });
  });
}
