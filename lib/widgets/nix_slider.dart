import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:nixsvg/theme/components/slider_theme.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';

/// Pure Material 3 Expressive Custom Slider for nixSVG Element Properties.
///
/// Features:
/// - 20px height rounded capsule track.
/// - Full-height 20px rectangular thumb (not rounded): 2px width at rest,
///   smoothly expanding to 5px on hover, press, and slide drag.
/// - Fluid spring-animated expansion of thumb width on hover and press
///   powered by Material 3 Expressive responsive spring physics ([M3PhysicsSpring.responsive]).
/// - Highly optimized 60/120 FPS CustomPainter rendering with zero layout thrashing.
/// - Supports continuous scrubbing, discrete step divisions, and arrow key navigation.
class NixSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final bool enabled;
  final EdgeInsetsGeometry padding;
  final double trackHeight;
  final double thumbWidth;
  final double thumbHeight;
  final double hoverThumbWidth;
  final double hoverThumbHeight;
  final double pressedThumbWidth;
  final double pressedThumbHeight;
  final double thumbCornerRadiusFactor;
  final bool isThumbRounded;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;
  final SpringDescription spring;

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
    this.padding = const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
    this.trackHeight = AppSliderTheme.trackHeight,
    this.thumbWidth = AppSliderTheme.thumbWidth,
    this.thumbHeight = AppSliderTheme.thumbHeight,
    this.hoverThumbWidth = AppSliderTheme.hoverThumbWidth,
    this.hoverThumbHeight = AppSliderTheme.hoverThumbHeight,
    this.pressedThumbWidth = AppSliderTheme.pressedThumbWidth,
    this.pressedThumbHeight = AppSliderTheme.pressedThumbHeight,
    this.thumbCornerRadiusFactor = AppSliderTheme.thumbCornerRadiusFactor,
    this.isThumbRounded = AppSliderTheme.isThumbRounded,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.spring = AppSliderTheme.defaultSpring,
  }) : assert(max > min, 'max must be greater than min');

  @override
  State<NixSlider> createState() => _NixSliderState();
}

class _NixSliderState extends State<NixSlider> with TickerProviderStateMixin {
  late final AnimationController _widthController;
  late final AnimationController _heightController;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _widthController = AnimationController.unbounded(
      vsync: this,
      value: widget.thumbWidth,
    );
    _heightController = AnimationController.unbounded(
      vsync: this,
      value: widget.thumbHeight,
    );
  }

  @override
  void didUpdateWidget(covariant NixSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isHovered && !_isPressed) {
      if (oldWidget.thumbWidth != widget.thumbWidth &&
          _widthController.value == oldWidget.thumbWidth) {
        _widthController.value = widget.thumbWidth;
      }
      if (oldWidget.thumbHeight != widget.thumbHeight &&
          _heightController.value == oldWidget.thumbHeight) {
        _heightController.value = widget.thumbHeight;
      }
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _updateAnimationTargets() {
    if (!mounted) return;
    double targetWidth = widget.thumbWidth;
    double targetHeight = widget.thumbHeight;

    if (_isPressed) {
      targetWidth = widget.pressedThumbWidth;
      targetHeight = widget.pressedThumbHeight;
    } else if (_isHovered) {
      targetWidth = widget.hoverThumbWidth;
      targetHeight = widget.hoverThumbHeight;
    }

    final simW = SpringSimulation(
      widget.spring,
      _widthController.value,
      targetWidth,
      _widthController.velocity,
    );
    final simH = SpringSimulation(
      widget.spring,
      _heightController.value,
      targetHeight,
      _heightController.velocity,
    );
    _widthController.animateWith(simW);
    _heightController.animateWith(simH);
  }

  void _handleDrag(Offset localPosition, double totalWidth) {
    if (!widget.enabled || widget.onChanged == null) return;
    final maxThumbWidth = widget.pressedThumbWidth;
    final trackMargin = (maxThumbWidth / 2) + 1.0;
    final trackWidth = totalWidth - (trackMargin * 2);
    if (trackWidth <= 0) return;

    final dx = (localPosition.dx - trackMargin).clamp(0.0, trackWidth);
    final fraction = dx / trackWidth;
    final rawValue = widget.min + fraction * (widget.max - widget.min);

    double finalValue = rawValue;
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = (widget.max - widget.min) / widget.divisions!;
      finalValue = ((rawValue - widget.min) / step).round() * step + widget.min;
    }
    final clamped = finalValue.clamp(widget.min, widget.max);
    if (clamped != widget.value) {
      widget.onChanged?.call(clamped);
    }
  }

  void _step(bool forward) {
    if (!widget.enabled || widget.onChanged == null) return;
    final step = (widget.divisions != null && widget.divisions! > 0)
        ? (widget.max - widget.min) / widget.divisions!
        : (widget.max - widget.min) / 100;
    final next = forward ? widget.value + step : widget.value - step;
    widget.onChanged?.call(next.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInteractive = widget.enabled && widget.onChanged != null;

    final effectiveActiveColor = isInteractive
        ? (widget.activeTrackColor ?? colorScheme.primary)
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final effectiveInactiveColor = isInteractive
        ? (widget.inactiveTrackColor ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.55))
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38);

    final effectiveThumbColor = isInteractive
        ? (widget.thumbColor ?? colorScheme.onPrimary)
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final effectiveBorderColor =
        colorScheme.outlineVariant.withValues(alpha: 0.35);

    final fraction = ((widget.value - widget.min) / (widget.max - widget.min))
        .clamp(0.0, 1.0);

    return Padding(
      padding: widget.padding,
      child: Focus(
        onKeyEvent: (node, event) {
          if (!isInteractive) return KeyEventResult.ignored;
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _step(false);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _step(true);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: isInteractive
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: isInteractive
              ? (_) {
                  setState(() => _isHovered = true);
                  _updateAnimationTargets();
                }
              : null,
          onExit: isInteractive
              ? (_) {
                  setState(() => _isHovered = false);
                  _updateAnimationTargets();
                }
              : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widgetHeight = math.max(
                widget.trackHeight,
                20.0,
              );

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: isInteractive
                    ? (details) {
                        setState(() => _isPressed = true);
                        _updateAnimationTargets();
                        widget.onChangeStart?.call(widget.value);
                        _handleDrag(
                          details.localPosition,
                          constraints.maxWidth,
                        );
                      }
                    : null,
                onTapUp: isInteractive
                    ? (_) {
                        setState(() => _isPressed = false);
                        _updateAnimationTargets();
                        widget.onChangeEnd?.call(widget.value);
                      }
                    : null,
                onTapCancel: () {
                  if (_isPressed) {
                    setState(() => _isPressed = false);
                    _updateAnimationTargets();
                  }
                },
                onHorizontalDragStart: isInteractive
                    ? (details) {
                        setState(() => _isPressed = true);
                        _updateAnimationTargets();
                        widget.onChangeStart?.call(widget.value);
                        _handleDrag(
                          details.localPosition,
                          constraints.maxWidth,
                        );
                      }
                    : null,
                onHorizontalDragUpdate: isInteractive
                    ? (details) {
                        _handleDrag(
                          details.localPosition,
                          constraints.maxWidth,
                        );
                      }
                    : null,
                onHorizontalDragEnd: isInteractive
                    ? (_) {
                        setState(() => _isPressed = false);
                        _updateAnimationTargets();
                        widget.onChangeEnd?.call(widget.value);
                      }
                    : null,
                onHorizontalDragCancel: () {
                  if (_isPressed) {
                    setState(() => _isPressed = false);
                    _updateAnimationTargets();
                  }
                },
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: widgetHeight,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _widthController,
                      _heightController,
                    ]),
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, widgetHeight),
                        painter: _NixSliderPainter(
                          value: fraction,
                          thumbWidth: _widthController.value,
                          thumbHeight: _heightController.value,
                          maxThumbWidth: widget.pressedThumbWidth,
                          trackHeight: widget.trackHeight,
                          activeTrackColor: effectiveActiveColor,
                          inactiveTrackColor: effectiveInactiveColor,
                          thumbColor: effectiveThumbColor,
                          borderColor: effectiveBorderColor,
                          thumbCornerRadiusFactor: widget.thumbCornerRadiusFactor,
                          isThumbRounded: widget.isThumbRounded,
                          enabled: widget.enabled,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NixSliderPainter extends CustomPainter {
  final double value;
  final double thumbWidth;
  final double thumbHeight;
  final double maxThumbWidth;
  final double trackHeight;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;
  final Color borderColor;
  final double thumbCornerRadiusFactor;
  final bool isThumbRounded;
  final bool enabled;

  _NixSliderPainter({
    required this.value,
    required this.thumbWidth,
    required this.thumbHeight,
    required this.maxThumbWidth,
    required this.trackHeight,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.thumbColor,
    required this.borderColor,
    required this.thumbCornerRadiusFactor,
    required this.isThumbRounded,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final trackMargin = (maxThumbWidth / 2) + 1.0;
    final trackLeft = trackMargin;
    final trackRight = size.width - trackMargin;
    final trackWidth = trackRight - trackLeft;

    if (trackWidth <= 0) return;

    final thumbX = (trackLeft + value * trackWidth).clamp(
      trackLeft,
      trackRight,
    );

    // 1. Full 20px rounded capsule track
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        0.0,
        centerY - trackHeight / 2,
        size.width,
        centerY + trackHeight / 2,
      ),
      Radius.circular(trackHeight / 2),
    );

    // Draw Inactive Track Background (full capsule)
    final inactivePaint = Paint()
      ..color = inactiveTrackColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRRect(trackRect, inactivePaint);

    // Clip to capsule track so active track and full-height thumb conform to the 20px rounded bounds
    canvas.save();
    canvas.clipRRect(trackRect);

    // 2. Active Track (From start of capsule to thumb center)
    if (thumbX > 0) {
      final activePaint = Paint()
        ..color = activeTrackColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final activeRect = Rect.fromLTRB(
        0.0,
        centerY - trackHeight / 2,
        thumbX,
        centerY + trackHeight / 2,
      );
      canvas.drawRect(activeRect, activePaint);
    }

    // 3. Thumb: Full height (20px), width (2px at rest, 5px on hover/press/drag), 20% rounded
    final currentWidth = math.max(thumbWidth, 1.0);
    final currentHeight = math.max(thumbHeight, 1.0);

    if (isThumbRounded && thumbCornerRadiusFactor > 0.0) {
      // 20% rounded thumb (e.g. 1.0px at 5px active, 0.4px at 2px resting)
      final cornerRadius = Radius.circular(currentWidth * thumbCornerRadiusFactor);
      final thumbRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(thumbX, centerY),
          width: currentWidth,
          height: currentHeight,
        ),
        cornerRadius,
      );

      // Subtle physical drop shadow for tactile depth
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawRRect(thumbRRect.shift(const Offset(0, 0.5)), shadowPaint);

      // Thumb bar with 20% rounded corners
      final thumbPaint = Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawRRect(thumbRRect, thumbPaint);

      // Subtle crisp thumb border
      final thumbBorderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..isAntiAlias = true;
      canvas.drawRRect(thumbRRect, thumbBorderPaint);
    } else {
      // Straight rectangular vertical needle/bar (NOT rounded)
      final thumbRect = Rect.fromCenter(
        center: Offset(thumbX, centerY),
        width: currentWidth,
        height: currentHeight,
      );

      // Subtle physical drop shadow for tactile depth
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawRect(thumbRect.shift(const Offset(0, 0.5)), shadowPaint);

      // Thumb bar
      final thumbPaint = Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawRect(thumbRect, thumbPaint);

      // Subtle crisp thumb border
      final thumbBorderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..isAntiAlias = true;
      canvas.drawRect(thumbRect, thumbBorderPaint);
    }

    canvas.restore();

    // 4. Subtle Outer Border for the 20px rounded track
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    canvas.drawRRect(trackRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NixSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.thumbWidth != thumbWidth ||
        oldDelegate.thumbHeight != thumbHeight ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.activeTrackColor != activeTrackColor ||
        oldDelegate.inactiveTrackColor != inactiveTrackColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.thumbCornerRadiusFactor != thumbCornerRadiusFactor ||
        oldDelegate.isThumbRounded != isThumbRounded ||
        oldDelegate.enabled != enabled;
  }
}

/// Aliases for NixSlider to match M3E convention.
typedef M3EAppSlider = NixSlider;
typedef M3EAppSeekbar = NixSlider;
typedef NixCustomSlider = NixSlider;
typedef M3EPropertySlider = NixSlider;
