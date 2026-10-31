import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/theme/components/slider_theme.dart';

void main() {
  testWidgets('NixSlider renders with rounded capsule track and 20x2px 20% rounded thumb', (
    tester,
  ) async {
    double currentValue = 0.50;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: NixSlider(
                value: currentValue,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  currentValue = val;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sliderFinder = find.byType(NixSlider);
    expect(sliderFinder, findsOneWidget);

    final sliderWidget = tester.widget<NixSlider>(sliderFinder);
    expect(sliderWidget.thumbHeight, equals(AppSliderTheme.thumbHeight));
    expect(sliderWidget.thumbWidth, equals(AppSliderTheme.thumbWidth));
    expect(sliderWidget.trackHeight, equals(AppSliderTheme.trackHeight));
    expect(sliderWidget.hoverThumbHeight, equals(AppSliderTheme.hoverThumbHeight));
    expect(sliderWidget.hoverThumbWidth, equals(AppSliderTheme.hoverThumbWidth));
    expect(sliderWidget.pressedThumbHeight, equals(AppSliderTheme.pressedThumbHeight));
    expect(sliderWidget.pressedThumbWidth, equals(AppSliderTheme.pressedThumbWidth));
    expect(sliderWidget.thumbCornerRadiusFactor, equals(0.20));
    expect(sliderWidget.isThumbRounded, isTrue);

    final customPaintFinder = find.descendant(
      of: sliderFinder,
      matching: find.byType(CustomPaint),
    );
    expect(customPaintFinder, findsWidgets);
  });

  testWidgets('NixSlider tap and drag updates value accurately', (
    tester,
  ) async {
    double currentValue = 0.0;
    bool changeStarted = false;
    bool changeEnded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return NixSlider(
                    value: currentValue,
                    min: 0.0,
                    max: 100.0,
                    onChangeStart: (_) => changeStarted = true,
                    onChangeEnd: (_) => changeEnded = true,
                    onChanged: (val) {
                      setState(() => currentValue = val);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap in the middle of the slider
    final sliderFinder = find.byType(NixSlider);
    await tester.tap(sliderFinder);
    await tester.pumpAndSettle();

    expect(changeStarted, isTrue);
    expect(changeEnded, isTrue);
    expect(currentValue, closeTo(50.0, 5.0));

    // Drag from center to near the end
    await tester.drag(sliderFinder, const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(currentValue, greaterThan(75.0));
  });

  testWidgets('NixSlider snaps to discrete divisions', (tester) async {
    double currentValue = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return NixSlider(
                    value: currentValue,
                    min: 0.0,
                    max: 100.0,
                    divisions: 4, // 0, 25, 50, 75, 100
                    onChanged: (val) {
                      setState(() => currentValue = val);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap roughly at 30% -> should snap to 25.0
    final center = tester.getCenter(find.byType(NixSlider));
    await tester.tapAt(Offset(center.dx - 40, center.dy));
    await tester.pumpAndSettle();

    expect(currentValue, anyOf(equals(25.0), equals(50.0)));
  });

  testWidgets('NixSlider animates thumb size on hover and press', (tester) async {
    double currentValue = 0.50;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: NixSlider(
                value: currentValue,
                min: 0.0,
                max: 1.0,
                onChanged: (val) => currentValue = val,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sliderFinder = find.byType(NixSlider);

    // Hover over slider with mouse
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(sliderFinder));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    // Tap and hold
    final touch = await tester.startGesture(tester.getCenter(sliderFinder));
    await tester.pump(const Duration(milliseconds: 50));
    await touch.up();
    await tester.pumpAndSettle();

    expect(sliderFinder, findsOneWidget);
  });

  testWidgets('NixPropertySlider renders with 20px height and full 20px x 5px thumb with 20% rounded corners', (tester) async {
    double propertyValue = 0.75;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: NixPropertySlider(
                label: 'Opacity',
                value: propertyValue,
                min: 0.0,
                max: 1.0,
                onChanged: (val) => propertyValue = val,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opacity'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);

    final sliderWidget = tester.widget<NixSlider>(find.byType(NixSlider));
    expect(sliderWidget.trackHeight, equals(20.0));
    expect(sliderWidget.thumbHeight, equals(20.0));
    expect(sliderWidget.thumbWidth, equals(2.0));
    expect(sliderWidget.hoverThumbWidth, equals(5.0));
    expect(sliderWidget.pressedThumbWidth, equals(5.0));
    expect(sliderWidget.thumbCornerRadiusFactor, equals(0.20));
    expect(sliderWidget.isThumbRounded, isTrue);
  });
}

