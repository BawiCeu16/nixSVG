import 'package:flutter/material.dart';
import 'package:m3e_slider/m3e_slider.dart';

export 'package:nixsvg/widgets/nix_slider.dart';

/// Style configurations and token decorations for nixSVG sliders.
class AppSliderTheme {
  const AppSliderTheme._();

  static const double trackHeight = 5.0;
  static const double trackCornerRadius = 1.0;
  static const double thumbWidth = 4.0;
  static const double thumbHeight = 22.0;

  static const M3EHapticConfig defaultHapticConfig = M3EHapticConfig(
    enableContinuousDrag: true,
    deltaProgressForDragThreshold: 0.02,
    vibrateOnLowerBookend: true,
    vibrateOnUpperBookend: true,
    lowerBookendThreshold: 0.01,
    upperBookendThreshold: 0.99,
    progressBasedDragMinScale: 0.10,
    progressBasedDragMaxScale: 0.85,
    additionalVelocityMaxBump: 0.10,
    maxVelocityToScale: 200.00,
    minimumDragInterval: Duration(milliseconds: 10),
  );

  static M3ESliderDecoration createDecoration(ColorScheme colorScheme) {
    return M3ESliderDecoration(
      haptic: M3EHapticFeedback.light,
      trackHeight: trackHeight,
      trackCornerRadius: trackCornerRadius,
      thumbWidth: thumbWidth,
      thumbHeight: thumbHeight,
      colors: M3ESliderColors(
        thumbColor: colorScheme.primary,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        disabledThumbColor: colorScheme.onSurface.withValues(alpha: 0.38),
        disabledActiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.38),
        disabledInactiveTrackColor: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.38),
        activeTickColor: colorScheme.onPrimary,
        inactiveTickColor: colorScheme.onSurfaceVariant,
        disabledActiveTickColor: colorScheme.onSurface.withValues(alpha: 0.38),
        disabledInactiveTickColor: colorScheme.onSurface.withValues(
          alpha: 0.38,
        ),
      ),
      hapticConfig: defaultHapticConfig,
    );
  }
}
