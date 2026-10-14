import 'package:flutter/material.dart';

/// Interactive draggable divider for resizing sidebars smoothly with hover feedback
/// and double-tap to reset to default width.
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
            width: 8,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: (_isHovered || _isDragging) ? 3 : 1,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _isDragging
                    ? colorScheme.primary
                    : _isHovered
                    ? colorScheme.primary.withValues(alpha: 0.7)
                    : colorScheme.outlineVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
