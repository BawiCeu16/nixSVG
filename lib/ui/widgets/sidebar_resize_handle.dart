import 'package:flutter/material.dart';

/// Interactive draggable divider for resizing sidebars smoothly with hover feedback,
/// macOS-style grab handle pill indicator, and double-tap to reset to default width.
class SidebarResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDoubleTapReset;

  const SidebarResizeHandle({
    super.key,
    required this.onDragUpdate,
    required this.onDoubleTapReset,
  });

  @override
  State<SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<SidebarResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleTapReset,
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) =>
            widget.onDragUpdate(details.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragCancel: () => setState(() => _isDragging = false),
        child: Tooltip(
          message: 'Drag to resize sidebar (double-tap to reset)',
          waitDuration: const Duration(milliseconds: 700),
          child: Container(
            width: 10,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hairline Divider
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: (_isHovered || _isDragging) ? 2.0 : 0.8,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? colorScheme.primary
                        : _isHovered
                        ? colorScheme.primary.withValues(alpha: 0.7)
                        : colorScheme.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                // macOS Mini Grab Handle Pill
                AnimatedOpacity(
                  opacity: (_isHovered || _isDragging) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 4,
                    height: _isDragging ? 36 : 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
