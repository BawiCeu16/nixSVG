import 'package:flutter/material.dart';
import 'package:m3e_seekbar/m3e_seekbar.dart';
import 'package:nixsvg/theme/components/slider_theme.dart';

/// Unified Material 3 Expressive Seekbar for nixSVG Studio.
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
  final EdgeInsetsGeometry padding;

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
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clampedValue = value.clamp(min, max);

    return Padding(
      padding: padding,
      child: M3ESeekbar(
        value: clampedValue,
        min: min,
        max: max,
        enabled: enabled,
        decoration: AppSliderTheme.createDecoration(colorScheme),
        trackCornerRadius: 100.0,
        onChanged: enabled && onChanged != null
            ? (val) {
                if (divisions != null && divisions! > 0) {
                  final step = (max - min) / divisions!;
                  final snapped = ((val - min) / step).round() * step + min;
                  onChanged!(snapped.clamp(min, max));
                } else {
                  onChanged!(val);
                }
              }
            : null,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

/// Alias for NixSlider to match M3E convention.
typedef M3EAppSlider = NixSlider;
typedef M3EAppSeekbar = NixSlider;
