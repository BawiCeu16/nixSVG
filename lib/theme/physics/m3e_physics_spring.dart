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

  /// Expressive curves for transitions and slide animations.
  static const Curve expressiveCurve = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve smoothDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);
}

/// An interactive wrapper that delivers realistic, physics-based spring scale
/// and tactile feedback on hover and press, adhering to Material 3 Expressive standards.
class M3PhysicsPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final double pressedScale;
  final double hoverScale;
  final SpringDescription spring;
  final HitTestBehavior behavior;
  final bool enableHoverHighlight;
  final Color? hoverColor;
  final BorderRadius? borderRadius;

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
    this.enableHoverHighlight = false,
    this.hoverColor,
    this.borderRadius,
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
    if (widget.pressedScale == 1.0 && widget.hoverScale == 1.0) {
      if (_controller.value != 0.0) _controller.value = 0.0;
      return;
    }
    final simulation = SpringSimulation(
      widget.spring,
      _controller.value,
      targetDelta,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  double get _targetDelta {
    // Zero press shrink / smaller animations
    if (_isPressed) {
      return (widget.pressedScale > 1.0) ? widget.pressedScale - 1.0 : 0.0;
    }
    if (_isHovered) {
      return (widget.hoverScale > 1.0) ? widget.hoverScale - 1.0 : 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null || widget.onLongPress != null;
    final hasScale = widget.pressedScale > 1.0 || widget.hoverScale > 1.0;

    Widget content = MouseRegion(
      cursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _isHovered = true);
        if (hasScale) _animateToTarget(_targetDelta);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
        if (hasScale) _animateToTarget(_targetDelta);
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: isInteractive
            ? (_) {
                if (!mounted) return;
                setState(() => _isPressed = true);
                if (hasScale) _animateToTarget(_targetDelta);
              }
            : null,
        onTapUp: isInteractive
            ? (_) {
                if (!mounted) return;
                setState(() => _isPressed = false);
                if (hasScale) _animateToTarget(_targetDelta);
              }
            : null,
        onTapCancel: isInteractive
            ? () {
                if (!mounted) return;
                setState(() => _isPressed = false);
                if (hasScale) _animateToTarget(_targetDelta);
              }
            : null,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            Widget result = child!;
            if (widget.enableHoverHighlight && _isHovered && isInteractive) {
              final colorScheme = Theme.of(context).colorScheme;
              result = DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      widget.hoverColor ??
                      colorScheme.onSurface.withValues(alpha: 0.08),
                  borderRadius:
                      widget.borderRadius ?? BorderRadius.circular(100.0),
                ),
                child: result,
              );
            }
            if (hasScale) {
              final scale = (1.0 + _controller.value).clamp(0.85, 1.25);
              if ((scale - 1.0).abs() > 0.0001) {
                return Transform.scale(scale: scale, child: result);
              }
            }
            return result;
          },
          child: widget.child,
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 400),
        child: content,
      );
    }

    return content;
  }
}
