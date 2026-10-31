import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/device_preset.dart';
import 'package:nixsvg/widgets/device_presets_dialog.dart';

void main() {
  group('Mobile Device Presets Catalog', () {
    test('contains full iPhone line (iPhone 12 to iPhone 18)', () {
      final applePresets = DevicePreset.applePresets;

      final expectedIphoneIds = [
        'iphone-18-pro-max',
        'iphone-18-pro',
        'iphone-18',
        'iphone-17-pro-max',
        'iphone-17-pro',
        'iphone-17-air',
        'iphone-17',
        'iphone-16-pro-max',
        'iphone-16-pro',
        'iphone-16-plus',
        'iphone-16',
        'iphone-15-pro-max',
        'iphone-15-pro',
        'iphone-15-plus',
        'iphone-15',
        'iphone-14-pro-max',
        'iphone-14-pro',
        'iphone-14-plus',
        'iphone-14',
        'iphone-13-pro-max',
        'iphone-13-pro',
        'iphone-13',
        'iphone-13-mini',
        'iphone-12-pro-max',
        'iphone-12-pro',
        'iphone-12',
        'iphone-12-mini',
      ];

      for (final id in expectedIphoneIds) {
        final match = applePresets.where((p) => p.id == id);
        expect(match.isNotEmpty, isTrue, reason: 'Missing iPhone preset: $id');
        final preset = match.first;
        expect(preset.brand, equals(DeviceBrand.apple));
        expect(preset.width, greaterThan(300.0));
        expect(preset.height, greaterThan(600.0));
        expect(preset.cornerRadius, greaterThan(30.0));
      }
    });

    test('contains full Google Pixel line (Pixel 7 to Pixel 11)', () {
      final googlePresets = DevicePreset.googlePresets;

      final expectedPixelIds = [
        'pixel-11-pro-xl',
        'pixel-11-pro',
        'pixel-11',
        'pixel-10-pro-xl',
        'pixel-10-pro',
        'pixel-10',
        'pixel-9-pro-xl',
        'pixel-9-pro',
        'pixel-9-pro-fold',
        'pixel-9',
        'pixel-8-pro',
        'pixel-8',
        'pixel-8a',
        'pixel-7-pro',
        'pixel-7',
        'pixel-7a',
      ];

      for (final id in expectedPixelIds) {
        final match = googlePresets.where((p) => p.id == id);
        expect(match.isNotEmpty, isTrue, reason: 'Missing Pixel preset: $id');
        final preset = match.first;
        expect(preset.brand, equals(DeviceBrand.google));
        expect(preset.width, greaterThan(350.0));
        expect(preset.height, greaterThan(700.0));
      }
    });

    test('contains all Nothing Phones line', () {
      final nothingPresets = DevicePreset.nothingPresets;

      final expectedNothingIds = [
        'nothing-phone-3',
        'nothing-phone-2a-plus',
        'nothing-phone-2a',
        'nothing-phone-2',
        'nothing-cmf-phone-1',
        'nothing-phone-1',
      ];

      for (final id in expectedNothingIds) {
        final match = nothingPresets.where((p) => p.id == id);
        expect(match.isNotEmpty, isTrue, reason: 'Missing Nothing preset: $id');
        final preset = match.first;
        expect(preset.brand, equals(DeviceBrand.nothing));
        expect(preset.width, greaterThan(350.0));
        expect(preset.height, greaterThan(800.0));
        expect(preset.cornerRadius, greaterThan(20.0));
      }
    });

    test('allPresets aggregates all 3 brands correctly', () {
      final all = DevicePreset.allPresets;
      expect(
        all.length,
        equals(
          DevicePreset.applePresets.length +
              DevicePreset.googlePresets.length +
              DevicePreset.nothingPresets.length,
        ),
      );
      expect(all.length, greaterThanOrEqualTo(48));
    });
  });

  group('Vector Frame & Template Shapes Generation', () {
    test('blank frame generation produces complete hardware shell (bezel, cutout, status bar, nav bar) and no mock content', () {
      final preset = DevicePreset.allPresets.firstWhere(
        (p) => p.id == 'iphone-16-pro',
      );

      final shapes = preset.generateTemplateShapes(
        origin: const Offset(100, 200),
        darkMode: true,
        isTemplate: false,
      );

      // Blank frame should have hardware shell: bezel + cutout + status bar + home nav bar
      // with zero mock template UI elements
      final bezel = shapes.first;
      expect(bezel.name, contains('iPhone 16 Pro Frame Bezel'));
      expect(bezel.rect.left, equals(100.0));
      expect(bezel.rect.top, equals(200.0));
      expect(bezel.rect.width, equals(preset.width));
      expect(bezel.rect.height, equals(preset.height));
      expect(bezel.cornerRadius, equals(preset.cornerRadius));
      expect(bezel.strokeWidth, equals(preset.frameThickness));

      final island = shapes.firstWhere((s) => s.name == 'Dynamic Island');
      expect(island.rect.center.dx, closeTo(bezel.rect.center.dx, 0.01));

      final time = shapes.firstWhere((s) => s.name == 'Status Time');
      expect(time.textContent, equals('9:41'));

      final homeBar = shapes.firstWhere((s) => s.name == 'Home Indicator Pill');
      expect(homeBar, isNotNull);

      // Verify no mock content
      final names = shapes.map((s) => s.name).toList();
      expect(names, isNot(contains('Screen Header Title')));
      expect(names, isNot(contains('Action Button')));
      expect(names, isNot(contains('Showcase Card')));
    });

    test('series categorizes all models properly and returns series list', () {
      expect(DevicePreset.getSeriesForBrand(DeviceBrand.apple), contains('iPhone 18'));
      expect(DevicePreset.getSeriesForBrand(DeviceBrand.apple), contains('iPhone 17'));
      expect(DevicePreset.getSeriesForBrand(DeviceBrand.apple), contains('iPhone 16'));
      expect(DevicePreset.getSeriesForBrand(DeviceBrand.google), contains('Pixel 11'));
      expect(DevicePreset.getSeriesForBrand(DeviceBrand.google), contains('Pixel 9'));
      expect(DevicePreset.getSeriesForBrand(DeviceBrand.nothing), contains('Phone (3)'));
      expect(DevicePreset.getSeriesForBrand(DeviceBrand.nothing), contains('Phone (2a)'));
    });

    test('full template generation produces complete mobile UI kit', () {
      final preset = DevicePreset.allPresets.firstWhere(
        (p) => p.id == 'pixel-9-pro-xl',
      );

      final shapes = preset.generateTemplateShapes(
        origin: Offset.zero,
        darkMode: false,
        isTemplate: true,
      );

      // Full template should generate frame, punch hole, status bar clock/battery/signal,
      // showcase card, title text, CTA button, and home gesture pill
      expect(shapes.length, greaterThanOrEqualTo(10));

      final names = shapes.map((s) => s.name).toList();
      expect(names, contains('Pixel 9 Pro XL Frame Bezel'));
      expect(names, contains('Camera Punch Hole'));
      expect(names, contains('Status Time'));
      expect(names, contains('Battery Indicator'));
      expect(names, contains('Screen Header Title'));
      expect(names, contains('Home Indicator Pill'));

      // All shapes in template must share the same groupId for single-click selection and movement
      final rootGroupId = shapes.first.groupId;
      expect(rootGroupId, isNotNull);
      for (final s in shapes) {
        expect(s.groupId, equals(rootGroupId));
      }
    });

    test('Nothing phone template generates signature Nothing branding & title', () {
      final preset = DevicePreset.allPresets.firstWhere(
        (p) => p.id == 'nothing-phone-2',
      );

      final shapes = preset.generateTemplateShapes(
        origin: const Offset(50, 50),
        darkMode: true,
        isTemplate: true,
      );

      final title = shapes.firstWhere((s) => s.name == 'Screen Header Title');
      expect(title.textContent, contains('Nothing Phone (2)'));
    });
  });

  group('DevicePresetsDialog Widget', () {
    testWidgets('renders brand filter tabs and search bar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DevicePresetsDialog(
              isWorkspaceMode: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Subtitle
      expect(find.text('Mobile Device Frames'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Filter tabs
      expect(find.textContaining('All Brands'), findsOneWidget);
      expect(find.textContaining('Apple (iPhone'), findsOneWidget);
      expect(find.textContaining('Google (Pixel'), findsOneWidget);
      expect(find.text('Nothing Phone (All)'), findsOneWidget);

      // Action buttons in workspace mode: only Insert Frame, no Template or Set Size!
      expect(find.text('Insert Frame'), findsWidgets);
      expect(find.text('Template'), findsNothing);
      expect(find.text('Set Size'), findsNothing);
    });

    testWidgets('searching filters devices dynamically', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DevicePresetsDialog(
              isWorkspaceMode: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query for "nothing"
      await tester.enterText(find.byType(TextField), 'Phone (2a)');
      await tester.pumpAndSettle();

      expect(find.text('Nothing Phone (2a)'), findsOneWidget);
      expect(find.text('Nothing Phone (2a) Plus'), findsOneWidget);
      expect(find.text('iPhone 16 Pro'), findsNothing);
    });

    testWidgets('tapping Insert Frame triggers insertOnCanvas action and no template/setSize exists', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      DevicePresetResult? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DevicePresetsDialog(
              isWorkspaceMode: true,
              onPresetSelected: (res) {
                selectedResult = res;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no Template or Set Size widgets exist
      expect(find.text('Template'), findsNothing);
      expect(find.text('Set Size'), findsNothing);

      // Filter to Apple
      await tester.tap(find.textContaining('Apple ('));
      await tester.pumpAndSettle();

      // Search specifically for iPhone 16 Pro Max
      await tester.enterText(find.byType(TextField), '16 Pro Max');
      await tester.pumpAndSettle();

      // Tap 'Insert Frame' on the first match
      final frameBtn = find.text('Insert Frame').first;
      await tester.tap(frameBtn);
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(selectedResult!.preset.id, equals('iphone-16-pro-max'));
      expect(selectedResult!.action, equals(DevicePresetAction.insertOnCanvas));
      expect(selectedResult!.withTemplate, isFalse);
    });
  });
}
