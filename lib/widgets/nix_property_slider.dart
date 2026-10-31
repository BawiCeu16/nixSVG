import 'package:flutter/material.dart';
import 'package:nixsvg/theme/components/slider_theme.dart';

/// Pure Material 3 Expressive Custom Slider for Element Properties.
///
/// Features:
/// - Exact 20px track height capsule.
/// - Full-height 20px × 5px width rounded capsule thumb at rest.
/// - All rounded corners (capsule track + pill thumb).
/// - Dynamic Material 3 Expressive theming & responsive spring physics.
/// - Optional property label, formatted value badge, and prefix icon.
class NixPropertySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final bool enabled;
  final String? label;
  final String Function(double value)? valueFormatter;
  final Widget? prefixIcon;
  final EdgeInsetsGeometry padding;
  final double thumbCornerRadiusFactor;
  final bool isThumbRounded;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;

  const NixPropertySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.enabled = true,
    this.label,
    this.valueFormatter,
    this.prefixIcon,
    this.onChangeStart,
    this.onChangeEnd,
    this.padding = const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
    this.thumbCornerRadiusFactor = AppSliderTheme.thumbCornerRadiusFactor,
    this.isThumbRounded = AppSliderTheme.isThumbRounded,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final slider = NixSlider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      enabled: enabled,
      trackHeight: AppSliderTheme.trackHeight, // 20.0px
      thumbHeight: AppSliderTheme.thumbHeight, // 20.0px (full height)
      thumbWidth: AppSliderTheme.thumbWidth, // 2.0px (otherwise 2px)
      hoverThumbWidth: AppSliderTheme.hoverThumbWidth, // 5.0px (hover)
      pressedThumbWidth: AppSliderTheme.pressedThumbWidth, // 5.0px (press & slide drag)
      thumbCornerRadiusFactor: thumbCornerRadiusFactor,
      isThumbRounded: isThumbRounded,
      padding: EdgeInsets.zero,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      thumbColor: thumbColor,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
    );

    if (label == null && valueFormatter == null) {
      return Padding(
        padding: padding,
        child: slider,
      );
    }

    final formattedValue = valueFormatter != null
        ? valueFormatter!(value)
        : (max <= 1.0
            ? '${(value * 100).round()}%'
            : value.toStringAsFixed(1));

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (prefixIcon != null) ...[
                prefixIcon!,
                const SizedBox(width: 6),
              ],
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  formattedValue,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          slider,
        ],
      ),
    );
  }
}
