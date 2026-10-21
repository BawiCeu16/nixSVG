import 'package:flutter/material.dart';

/// Physics-based spring descriptions adhering to Material 3 Expressive motion specs.
class M3PhysicsSpring {
  const M3PhysicsSpring._();

  /// Standard responsive spring for button presses and micro-interactions.
  static const SpringDescription responsive = SpringDescription(
    mass: 1.0,
    stiffness: 420.0,
    damping: 26.0,
  );

  /// Gentle, smooth spring for modal dialogs and large panel expansions.
  static const SpringDescription smooth = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 28.0,
  );

  /// Bouncy, energetic spring for celebratory feedback or tool switching.
  static const SpringDescription bouncy = SpringDescription(
    mass: 1.0,
    stiffness: 480.0,
    damping: 22.0,
  );
}

/// An interactive wrapper that adheres to Material 3 Expressive standards
/// providing clean interaction feedback without press-shrink or scale-down animations.
class M3PhysicsPressable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final double pressedScale;
  final double hoverScale;
  final SpringDescription spring;
  final HitTestBehavior behavior;

  const M3PhysicsPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.tooltip,
    this.pressedScale = 1.0,
    this.hoverScale = 1.0,
    this.spring = M3PhysicsSpring.responsive,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: behavior,
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: content,
      );
    }

    return content;
  }
}
