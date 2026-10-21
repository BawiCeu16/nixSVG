import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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

/// An interactive wrapper that delivers realistic, physics-based spring scale
/// and elevation feedback on hover and press, adhering to Material 3 Expressive standards.
class M3PhysicsPressable extends StatefulWidget {
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
    this.pressedScale = 0.94,
    this.hoverScale = 1.02,
    this.spring = M3PhysicsSpring.responsive,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<M3PhysicsPressable> createState() => _M3PhysicsPressableState();
}

class _M3PhysicsPressableState extends State<M3PhysicsPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateToTarget(double targetDelta) {
    if (!mounted) return;
    final simulation = SpringSimulation(
      widget.spring,
      _controller.value,
      targetDelta,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  double get _targetDelta {
    if (_isPressed) return widget.pressedScale - 1.0;
    if (_isHovered) return widget.hoverScale - 1.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _isHovered = true);
        _animateToTarget(_targetDelta);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
        _animateToTarget(_targetDelta);
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: (_) {
          if (!mounted) return;
          setState(() => _isPressed = true);
          _animateToTarget(_targetDelta);
        },
        onTapUp: (_) {
          if (!mounted) return;
          setState(() => _isPressed = false);
          _animateToTarget(_targetDelta);
          widget.onTap?.call();
        },
        onTapCancel: () {
          if (!mounted) return;
          setState(() => _isPressed = false);
          _animateToTarget(_targetDelta);
        },
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 1.0 + (_controller.value);
            return Transform.scale(
              scale: scale.clamp(0.7, 1.4),
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: content,
      );
    }

    return content;
  }
}
