import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:remixicon/remixicon.dart';

/// Redesigned macOS-style Layers Sidebar.
/// Features frosted glassmorphism, native macOS sidebar styling,
/// reorderable segments, layer ordering controls, and micro-interactions.
class LayersSidebar extends StatelessWidget {
  final List<VectorShape> shapes;
  final Set<String> selectedShapeIds;
  final ValueChanged<String> onSelectShape;
  final ValueChanged<String> onToggleVisibility;
  final ValueChanged<String> onToggleLock;
  final ValueChanged<String> onDeleteShape;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final Function(String id, String newName) onRenameShape;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final double? width;

  const LayersSidebar({
    super.key,
    required this.shapes,
    required this.selectedShapeIds,
    required this.onSelectShape,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onDeleteShape,
    required this.onBringForward,
    required this.onSendBackward,
    required this.onRenameShape,
    this.onReorder,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width ?? 270,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(
              alpha: isDark ? 0.75 : 0.88,
            ),
            border: Border(
              right: BorderSide(
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.25 : 0.35,
                ),
                width: 0.8,
              ),
            ),
          ),
          child: Column(
            children: [
              // --- macOS Sidebar Header ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(
                        alpha: isDark ? 0.2 : 0.3,
                      ),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      RemixIcons.stack_line,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Layers',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${shapes.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Layer Ordering Quick Action Buttons (shown when selection active)
                    if (selectedShapeIds.isNotEmpty) ...[
                      _MacHeaderAction(
                        icon: RemixIcons.arrow_up_s_line,
                        tooltip: 'Bring Forward',
                        onTap: onBringForward,
                      ),
                      const SizedBox(width: 2),
                      _MacHeaderAction(
                        icon: RemixIcons.arrow_down_s_line,
                        tooltip: 'Send Backward',
                        onTap: onSendBackward,
                      ),
                    ],
                  ],
                ),
              ),

              // --- Layer List View with M3EReorderableSegmentedList ---
              Expanded(
                child: shapes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  RemixIcons.shapes_line,
                                  size: 22,
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No vector layers',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Draw shapes using the dock tools.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final items = shapes.reversed.toList();
                          return Theme(
                            data: theme.copyWith(
                              scrollbarTheme: ScrollbarThemeData(
                                radius: const Radius.circular(4),
                                thickness: const WidgetStatePropertyAll(4),
                                thumbColor: WidgetStatePropertyAll(
                                  colorScheme.onSurface.withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                            child: M3EReorderableSegmentedList.builder(
                              keyBuilder: (index) => ValueKey(items[index].id),
                              itemCount: items.length,
                              buildDefaultDragHandles: false,
                              onTap: (index) => onSelectShape(items[index].id),
                              decoration: M3ESegmentedListDecoration(
                                outerRadius: 10.0,
                                innerRadius: 6.0,
                                pressedRadius: 8.0,
                                pressedScale: 0.98,
                                hoveredRadius: 10.0,
                                dragRadius: 12.0,
                                dragElevation: 4.0,
                                dragScale: 1.01,
                                gap: 2.0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 8.0,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.0,
                                ),
                                hoverColor: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.08),
                                dragPlaceholderColor:
                                    colorScheme.surfaceContainerHighest,
                                color: isDark
                                    ? colorScheme.surfaceContainerHigh
                                          .withValues(alpha: 0.3)
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.25),
                                selectedColor: colorScheme.primaryContainer
                                    .withValues(alpha: 0.65),
                              ),
                              onReorder: (oldIndex, newIndex) {
                                if (onReorder != null) {
                                  onReorder!(oldIndex, newIndex);
                                } else {
                                  if (newIndex > oldIndex) newIndex--;
                                  final item = items.removeAt(oldIndex);
                                  items.insert(newIndex, item);
                                  shapes.clear();
                                  shapes.addAll(items.reversed);
                                }
                              },
                              itemBuilder: (context, index) {
                                return _buildListItem(context, items[index]);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, VectorShape shape) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedShapeIds.contains(shape.id);

    return Row(
      children: [
        // Shape Type Icon with mini container
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(
            _getShapeIcon(shape.type),
            size: 13,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),

        // Layer Name with Double-Tap Rename
        Expanded(
          child: GestureDetector(
            onDoubleTap: () => _showRenameDialog(context, shape),
            child: Text(
              shape.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),

        // Visibility Toggle
        _MacLayerActionBtn(
          tooltip: shape.isVisible ? 'Hide Layer' : 'Show Layer',
          icon: shape.isVisible ? RemixIcons.eye_line : RemixIcons.eye_off_line,
          iconColor: shape.isVisible
              ? (isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7))
              : colorScheme.outline.withValues(alpha: 0.35),
          onTap: () => onToggleVisibility(shape.id),
        ),

        // Lock Toggle
        _MacLayerActionBtn(
          tooltip: shape.isLocked ? 'Unlock Layer' : 'Lock Layer',
          icon: shape.isLocked
              ? RemixIcons.lock_line
              : RemixIcons.lock_unlock_line,
          iconColor: shape.isLocked
              ? colorScheme.tertiary
              : colorScheme.outline.withValues(alpha: 0.35),
          onTap: () => onToggleLock(shape.id),
        ),

        // Delete Layer
        _MacLayerActionBtn(
          tooltip: 'Delete Layer',
          icon: RemixIcons.close_line,
          iconColor: colorScheme.error.withValues(alpha: 0.6),
          onTap: () => onDeleteShape(shape.id),
        ),
      ],
    );
  }

  void _showRenameDialog(BuildContext context, VectorShape shape) {
    final controller = TextEditingController(text: shape.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Layer'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Layer Name'),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                onRenameShape(shape.id, value.trim());
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            M3EFilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            M3EFilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onRenameShape(shape.id, controller.text.trim());
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  IconData _getShapeIcon(ShapeType type) {
    switch (type) {
      case ShapeType.rectangle:
        return RemixIcons.checkbox_blank_line;
      case ShapeType.roundedRectangle:
        return RemixIcons.rectangle_line;
      case ShapeType.ellipse:
        return RemixIcons.checkbox_blank_circle_line;
      case ShapeType.line:
        return RemixIcons.line_line;
      case ShapeType.star:
        return RemixIcons.star_line;
      case ShapeType.text:
        return RemixIcons.t_box_line;
      case ShapeType.image:
        return RemixIcons.image_line;
    }
  }
}

class _MacHeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MacHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _MacLayerActionBtn extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MacLayerActionBtn({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.all(3.5),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}
