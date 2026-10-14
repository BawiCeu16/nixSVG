import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m3e_slider/m3e_slider.dart';
import 'package:nixsvg/widgets/nix_slider.dart';

void main() {
  testWidgets('NixSlider renders with custom M3ESlider motion and decoration', (tester) async {
    double currentValue = 0.48;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: NixSlider(
            value: currentValue,
            min: 0.0,
            max: 1.0,
            onChanged: (val) {
              currentValue = val;
            },
          ),
        ),
      ),
    );

    final sliderFinder = find.byType(M3ESlider);
    expect(sliderFinder, findsOneWidget);

    final m3eSlider = tester.widget<M3ESlider>(sliderFinder);
    expect(m3eSlider.value, 0.48);
    expect(m3eSlider.motion, M3EMotion.expressiveSpatialFast);

    final dec = m3eSlider.decoration!;
    expect(dec.haptic, M3EHapticFeedback.light);
    expect(dec.trackHeight, 5.00);
    expect(dec.trackCornerRadius, 1.00);
    expect(dec.thumbWidth, 4.00);
    expect(dec.thumbHeight, 22.00);

    final haptic = dec.hapticConfig!;
    expect(haptic.enableContinuousDrag, isTrue);
    expect(haptic.deltaProgressForDragThreshold, 0.02);
    expect(haptic.vibrateOnLowerBookend, isTrue);
    expect(haptic.vibrateOnUpperBookend, isTrue);
    expect(haptic.lowerBookendThreshold, 0.01);
    expect(haptic.upperBookendThreshold, 0.99);
    expect(haptic.progressBasedDragMinScale, 0.10);
    expect(haptic.progressBasedDragMaxScale, 0.85);
    expect(haptic.additionalVelocityMaxBump, 0.10);
    expect(haptic.maxVelocityToScale, 200.00);
    expect(haptic.minimumDragInterval, const Duration(milliseconds: 10));
  });
}
