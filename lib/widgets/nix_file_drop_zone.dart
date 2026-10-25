import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';

/// Callback when files are successfully dropped onto the [NixFileDropZone].
typedef OnNixFilesDropped = void Function(
  List<XFile> files,
  Offset localDropPosition,
);

/// A high-performance, cross-platform drag and drop container supporting
/// macOS, Windows, Linux, Web, Android, and iOS.
///
/// Performance Optimizations:
/// 1. Uses an isolated [ValueNotifier<bool>] for hover tracking—cursor motion
///    across the drop zone during hover does NOT trigger rebuilds of the child tree.
/// 2. The visual overlay is painted on a separate layer via [RepaintBoundary],
///    protecting underlying 60/120 FPS vector canvas rendering.
/// 3. Debounced drag status prevents hover flicker when passing over inner widget boundaries.
class NixFileDropZone extends StatefulWidget {
  final Widget child;
  final OnNixFilesDropped onFilesDropped;
  final bool enable;
  final String title;
  final String subtitle;
  final List<String> supportedBadges;

  const NixFileDropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.enable = true,
    this.title = 'Drop files to import onto canvas',
    this.subtitle = 'Supports standard vector & high-res raster formats',
    this.supportedBadges = const ['SVG', 'PNG', 'JPG', 'WEBP', 'GIF', 'JSON'],
  });

  @override
  State<NixFileDropZone> createState() => NixFileDropZoneState();
}

class NixFileDropZoneState extends State<NixFileDropZone> {
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier<bool>(false);

  @visibleForTesting
  ValueNotifier<bool> get isDraggingNotifier => _isDraggingNotifier;

  int _dragEnterCount = 0;

  @override
  void dispose() {
    _isDraggingNotifier.dispose();
    super.dispose();
  }

  void _onDragEntered(DropEventDetails details) {
    _dragEnterCount++;
    if (!_isDraggingNotifier.value) {
      _isDraggingNotifier.value = true;
    }
  }

  void _onDragExited(DropEventDetails details) {
    _dragEnterCount = (_dragEnterCount - 1).clamp(0, 999);
    if (_dragEnterCount == 0 && _isDraggingNotifier.value) {
      _isDraggingNotifier.value = false;
    }
  }

  void _onDragDone(DropDoneDetails details) {
    _dragEnterCount = 0;
    _isDraggingNotifier.value = false;
    if (details.files.isNotEmpty) {
      widget.onFilesDropped(details.files, details.localPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enable) {
      return widget.child;
    }

    return DropTarget(
      enable: widget.enable,
      onDragEntered: _onDragEntered,
      onDragExited: _onDragExited,
      onDragDone: _onDragDone,
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (details) {
          _isDraggingNotifier.value = true;
          return true;
        },
        onLeave: (_) {
          _isDraggingNotifier.value = false;
        },
        onAcceptWithDetails: (details) {
          _isDraggingNotifier.value = false;
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Primary Child (Canvas, Workspace, or Screen)
              widget.child,

              // 2. High-Performance Isolated Overlay (Only rebuilds on enter/exit)
              ValueListenableBuilder<bool>(
                valueListenable: _isDraggingNotifier,
                builder: (context, isDragging, _) {
                  if (!isDragging) {
                    return const SizedBox.shrink();
                  }

                  return Positioned.fill(
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        ignoring: true, // Let drop target capture the release
                        child: _M3EDropZoneOverlay(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          badges: widget.supportedBadges,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Material 3 Expressive frosted glass drop indicator overlay with spring animation.
class _M3EDropZoneOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> badges;

  const _M3EDropZoneOverlay({
    required this.title,
    required this.subtitle,
    required this.badges,
  });

  @override
  State<_M3EDropZoneOverlay> createState() => _M3EDropZoneOverlayState();
}

class _M3EDropZoneOverlayState extends State<_M3EDropZoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: M3PhysicsSpring.expressiveCurve,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Static full-screen frosted glass backdrop (NOT scaled, prevents blur glitching)
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: ColoredBox(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: isDark ? 0.22 : 0.18,
                ),
              ),
            ),
          ),
        ),

        // 2. Central Translucent Card (Animated scale & fade)
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                // Translucent gradient that avoids pure black in dark mode
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark
                            ? colorScheme.surfaceContainerHigh
                            : colorScheme.surface)
                        .withValues(alpha: isDark ? 0.68 : 0.85),
                    (isDark
                            ? colorScheme.surfaceContainer
                            : colorScheme.surfaceContainerLowest)
                        .withValues(alpha: isDark ? 0.52 : 0.72),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dynamic Primary Icon Capsule
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: isDark ? 0.90 : 0.96,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.fileUp,
                      size: 32,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.85,
                      ),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Supported Formats Pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: widget.badges.map((badge) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.6,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
