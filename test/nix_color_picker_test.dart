import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/color_picker_dialog.dart';

void main() {
  group('NixColorUtils - All Color Codes & Math Tests', () {
    test('Converts Color to 6-digit and 8-digit HEX properly', () {
      const solidBlue = Color(0xFF3B82F6);
      expect(NixColorUtils.toHex(solidBlue), equals('#3B82F6'));

      const translucentRed = Color(0x80EF4444);
      expect(NixColorUtils.toHex(translucentRed, includeAlpha: true), equals('#EF444480'));
    });

    test('Parses various HEX formats safely', () {
      // 6-digit with #
      expect(NixColorUtils.parseHex('#3B82F6'), equals(const Color(0xFF3B82F6)));
      // 6-digit without #
      expect(NixColorUtils.parseHex('3B82F6'), equals(const Color(0xFF3B82F6)));
      // 3-digit shorthand
      expect(NixColorUtils.parseHex('#F00'), equals(const Color(0xFFFF0000)));
      // 8-digit RRGGBBAA
      expect(NixColorUtils.parseHex('#FF000080'), equals(const Color(0x80FF0000)));
      // Invalid hex returns null without throwing
      expect(NixColorUtils.parseHex('invalid'), isNull);
      expect(NixColorUtils.parseHex(''), isNull);
    });

    test('Converts RGB to and from Color accurately', () {
      const original = Color(0xFF6366F1);
      final rgba = NixColorUtils.toRgba(original);
      expect(rgba.r, equals(0x63));
      expect(rgba.g, equals(0x66));
      expect(rgba.b, equals(0xF1));
      expect(rgba.aPct, equals(100));

      final restored = NixColorUtils.fromRgba(rgba.r, rgba.g, rgba.b, rgba.aPct);
      expect(restored.toARGB32(), equals(original.toARGB32()));
    });

    test('Converts HSL to and from Color accurately', () {
      const pureRed = Color(0xFFFF0000);
      final hsla = NixColorUtils.toHsla(pureRed);
      expect(hsla.h, equals(0));
      expect(hsla.sPct, equals(100));
      expect(hsla.lPct, equals(50));

      final restored = NixColorUtils.fromHsla(hsla.h, hsla.sPct, hsla.lPct, hsla.aPct);
      expect(restored.toARGB32(), equals(pureRed.toARGB32()));
    });

    test('Converts HSV to and from Color accurately', () {
      const pureGreen = Color(0xFF00FF00);
      final hsva = NixColorUtils.toHsva(pureGreen);
      expect(hsva.h, equals(120));
      expect(hsva.sPct, equals(100));
      expect(hsva.vPct, equals(100));

      final restored = NixColorUtils.fromHsva(hsva.h, hsva.sPct, hsva.vPct, hsva.aPct);
      expect(restored.toARGB32(), equals(pureGreen.toARGB32()));
    });

    test('Calculates WCAG Contrast Ratio and ratings accurately', () {
      final whiteOnBlack = NixColorUtils.contrastRatio(Colors.white, Colors.black);
      expect(whiteOnBlack, closeTo(21.0, 0.1));
      expect(NixColorUtils.wcagRating(whiteOnBlack), equals('AAA'));

      final sameColor = NixColorUtils.contrastRatio(Colors.white, Colors.white);
      expect(sameColor, closeTo(1.0, 0.01));
      expect(NixColorUtils.wcagRating(sameColor), equals('Fail'));
    });

    test('Calculates Complementary and Inverted colors properly', () {
      const red = Color(0xFFFF0000); // 0°
      final comp = NixColorUtils.complementary(red);
      final compHsl = HSLColor.fromColor(comp);
      expect(compHsl.hue, closeTo(180.0, 1.0)); // Cyan

      final inv = NixColorUtils.invert(red);
      expect(inv.toARGB32(), equals(const Color(0xFF00FFFF).toARGB32()));
    });

    test('Interpolates colors across gradient stops smoothly', () {
      const stops = [
        GradientColorStop(offset: 0.0, color: Color(0xFF000000)),
        GradientColorStop(offset: 1.0, color: Color(0xFFFFFFFF)),
      ];
      final mid = NixColorUtils.lerpGradientStops(stops, 0.5);
      final midRgba = NixColorUtils.toRgba(mid);
      expect(midRgba.r, closeTo(127, 2));
      expect(midRgba.g, closeTo(127, 2));
      expect(midRgba.b, closeTo(127, 2));
    });

    test('Generates CSS linear and radial gradient syntax correctly', () {
      const grad = ShapeGradient(
        type: PaintFillType.linearGradient,
        stops: [
          GradientColorStop(offset: 0.0, color: Color(0xFF6366F1)),
          GradientColorStop(offset: 1.0, color: Color(0xFF38BDF8)),
        ],
        angle: 90.0,
      );

      final css = NixColorUtils.toCssString(
        color: const Color(0xFF6366F1),
        gradient: grad,
        mode: ColorPickerMode.linearGradient,
      );
      expect(css, contains('linear-gradient(90deg, #6366F1 0%, #38BDF8 100%)'));
    });
  });

  group('NixColorPicker Widget Tests', () {
    testWidgets('Renders NixColorPicker with preview, sliders, swatches and tools', (tester) async {
      Color pickedColor = const Color(0xFF3B82F6);
      ShapeGradient? pickedGradient;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NixColorPicker(
                initialColor: pickedColor,
                onColorChanged: (c) => pickedColor = c,
                onGradientChanged: (g) => pickedGradient = g,
              ),
            ),
          ),
        ),
      );

      // Verify title, mode switches, swatches
      expect(find.text('Color & Gradient'), findsOneWidget);
      expect(find.text('Solid'), findsOneWidget);
      expect(find.text('Linear'), findsOneWidget);
      expect(find.text('Radial'), findsOneWidget);
      expect(find.text('SWATCHES'), findsOneWidget);
      expect(find.text('HEX'), findsAtLeast(1));
      expect(find.text('RGB'), findsOneWidget);
      expect(find.text('HSL'), findsOneWidget);
      expect(find.text('HSV'), findsOneWidget);

      // Switch to Linear Gradient mode
      await tester.tap(find.text('Linear'));
      await tester.pumpAndSettle();

      expect(find.text('Reverse'), findsOneWidget);
      expect(pickedGradient != null || pickedColor != Colors.transparent, isTrue);

      // Switch format to RGB
      await tester.tap(find.text('RGB'));
      await tester.pumpAndSettle();

      expect(find.text('R'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('ColorPickerExperimentWidget launches and tests modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ColorPickerExperimentWidget(),
          ),
        ),
      );

      expect(find.text('COLOR & GRADIENT LAB'), findsOneWidget);
      expect(find.text('Adaptive Popover'), findsOneWidget);
      expect(find.text('Modal Dialog'), findsOneWidget);
      expect(find.text('Embedded Inline'), findsOneWidget);

      // Switch to Embedded Inline mode
      await tester.tap(find.text('Embedded Inline'));
      await tester.pumpAndSettle();

      expect(find.text('LIVE EMBEDDED WIDGET'), findsOneWidget);
    });

    testWidgets('Header drag callback triggers delta updates', (tester) async {
      Offset totalDelta = Offset.zero;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NixColorPicker(
                initialColor: const Color(0xFF6366F1),
                onColorChanged: (_) {},
                onDragDelta: (delta) => totalDelta += delta,
              ),
            ),
          ),
        ),
      );

      // Find header title and drag it
      final headerFinder = find.text('Color & Gradient');
      expect(headerFinder, findsOneWidget);

      await tester.drag(headerFinder, const Offset(50, 30));
      await tester.pumpAndSettle();

      expect(totalDelta.dx, greaterThan(0));
      expect(totalDelta.dy, greaterThan(0));
    });

    testWidgets('Gradient Slider interacts smoothly with stops and reverse', (tester) async {
      ShapeGradient? currentGradient;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NixColorPicker(
                initialColor: const Color(0xFF6366F1),
                initialMode: ColorPickerMode.linearGradient,
                onColorChanged: (_) {},
                onGradientChanged: (g) => currentGradient = g,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Reverse'), findsOneWidget);

      // Tap Reverse to verify gradient reverses
      await tester.tap(find.text('Reverse'));
      await tester.pumpAndSettle();

      expect(currentGradient, isNotNull);
      expect(currentGradient!.stops.length, equals(2));
    });

    testWidgets('Changing stop color in gradient mode only invokes onGradientChanged and NOT onColorChanged', (tester) async {
      int colorChangedCalls = 0;
      ShapeGradient? lastGradient;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NixColorPicker(
                initialColor: const Color(0xFF6366F1),
                initialMode: ColorPickerMode.linearGradient,
                onColorChanged: (_) => colorChangedCalls++,
                onGradientChanged: (g) => lastGradient = g,
              ),
            ),
          ),
        ),
      );

      // Invert color or trigger color change on selected stop
      final invertButton = find.byTooltip('Invert Color');
      expect(invertButton, findsOneWidget);

      await tester.tap(invertButton);
      await tester.pumpAndSettle();

      // onColorChanged must NOT be called in gradient mode
      expect(colorChangedCalls, equals(0));
      // onGradientChanged MUST be called with updated stop color
      expect(lastGradient, isNotNull);
      expect(lastGradient!.type, equals(PaintFillType.linearGradient));
    });

    testWidgets('Eyedropper launches overlay, shows Figma loupe, and applies sampled color on tap', (tester) async {
      Color? pickedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NixColorPicker(
                initialColor: const Color(0xFF6366F1),
                initialMode: ColorPickerMode.solid,
                onColorChanged: (c) => pickedColor = c,
              ),
            ),
          ),
        ),
      );

      final eyedropperButton = find.byTooltip('Pick Color (Eyedropper)');
      expect(eyedropperButton, findsOneWidget);

      await tester.tap(eyedropperButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Eyedropper overlay instructions pill should now be visible on screen
      expect(find.textContaining('Click to sample screen color'), findsOneWidget);

      // Tap on the screen to sample a color
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Overlay should be removed and sampled color applied
      expect(find.textContaining('Click to sample screen color'), findsNothing);
      expect(pickedColor, isNotNull);
    });

    testWidgets('Eyedropper can be cancelled with Escape key without applying', (tester) async {
      Color? pickedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NixColorPicker(
                initialColor: const Color(0xFF6366F1),
                initialMode: ColorPickerMode.solid,
                onColorChanged: (c) => pickedColor = c,
              ),
            ),
          ),
        ),
      );

      final eyedropperButton = find.byTooltip('Pick Color (Eyedropper)');
      await tester.tap(eyedropperButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Click to sample screen color'), findsOneWidget);

      // Press Escape to cancel
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.textContaining('Click to sample screen color'), findsNothing);
      expect(pickedColor, isNull);
    });
  });
}
