import 'package:flutter/material.dart';
import 'package:m3e_slider/m3e_slider.dart';

/// Unified Material 3 Expressive Slider for nixSVG Studio.
/// Standardizes all sliders and seekbars across the entire app with custom
/// motion, track height, corner radius, thumb dimensions, and expressive haptics.
class NixSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final bool enabled;

  const NixSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.enabled = true,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clampedValue = value.clamp(min, max);

    return M3ESlider(
      value: clampedValue,
      min: min,
      max: max,
      divisions: divisions,
      motion: M3EMotion.expressiveSpatialFast,
      decoration: M3ESliderDecoration(
        haptic: M3EHapticFeedback.light,
        trackHeight: 5.00,
        trackCornerRadius: 1.00,
        thumbWidth: 4.00,
        thumbHeight: 22.00,
        colors: M3ESliderColors(
          thumbColor: colorScheme.primary,
          activeTrackColor: colorScheme.primary,

          inactiveTrackColor: colorScheme.surfaceContainerHighest,
          disabledThumbColor: colorScheme.onSurface.withValues(alpha: 0.38),
          disabledActiveTrackColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          disabledInactiveTrackColor: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.38),
          activeTickColor: colorScheme.onPrimary,
          inactiveTickColor: colorScheme.onSurfaceVariant,
          disabledActiveTickColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          disabledInactiveTickColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
        ),
        hapticConfig: const M3EHapticConfig(
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
        ),
      ),
      onChanged: enabled ? onChanged : null,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );
  }
}

/// Alias for NixSlider to match M3E convention.
typedef M3EAppSlider = NixSlider;
