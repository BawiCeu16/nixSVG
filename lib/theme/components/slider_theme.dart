import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';

export 'package:nixsvg/widgets/nix_slider.dart';

/// Style configurations and token decorations for nixSVG custom sliders.
class AppSliderTheme {
  const AppSliderTheme._();

  /// Rounded line track height.
  static const double trackHeight = 4.0;

  /// Default resting thumb dimensions: 20px height × 5px width.
  static const double thumbWidth = 4.0;
  static const double thumbHeight = 18.0;

  /// Expanded thumb dimensions on hover.
  static const double hoverThumbWidth = 5.0;
  static const double hoverThumbHeight = 18.0;

  /// Expanded thumb dimensions on press / dragging.
  static const double pressedThumbWidth = hoverThumbWidth;
  static const double pressedThumbHeight = hoverThumbHeight;

  /// Default Material 3 Expressive spring physics.
  static const SpringDescription defaultSpring = M3PhysicsSpring.responsive;
}
