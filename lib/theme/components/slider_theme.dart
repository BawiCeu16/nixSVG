import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';

export 'package:nixsvg/widgets/nix_slider.dart';
export 'package:nixsvg/widgets/nix_property_slider.dart';

/// Style configurations and token decorations for nixSVG custom sliders.
class AppSliderTheme {
  const AppSliderTheme._();

  /// Rounded capsule track height: 20px.
  static const double trackHeight = 20.0;

  /// Default resting thumb dimensions: full height (20px) × 2px width (otherwise 2px).
  static const double thumbWidth = 2.0;
  static const double thumbHeight = 20.0;

  /// Expanded thumb dimensions on hover: 5px width.
  static const double hoverThumbWidth = 5.0;
  static const double hoverThumbHeight = 20.0;

  /// Expanded thumb dimensions on press / slide drag: 5px width.
  static const double pressedThumbWidth = 5.0;
  static const double pressedThumbHeight = 20.0;

  /// Corner radius factor for the thumb (0.20 = 20% rounded).
  static const double thumbCornerRadiusFactor = 0.20;

  /// Whether the thumb has rounded corners (20% rounded by default).
  static const bool isThumbRounded = true;

  /// Default Material 3 Expressive spring physics.
  static const SpringDescription defaultSpring = M3PhysicsSpring.responsive;
}
