import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:remixicon/remixicon.dart';

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

    return Container(
      width: width ?? 270,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Header M3 Expressive with RemixIcons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  RemixIcons.stack_line,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Layers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Badge.count(
                  count: shapes.length,
                  backgroundColor: colorScheme.secondaryContainer,
                  textColor: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),

          // Quick Layer Actions using M3EButtons
          // if (selectedShapeIds.isNotEmpty)
          //   Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //     color: colorScheme.surfaceContainer,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceAround,
          //       children: [
          //         M3EButton(
          //           onPressed: onBringForward,
          //           style: M3EButtonStyle.tonal,
          //           size: M3EButtonSize.sm,
          //           tooltip: 'Bring Forward',
          //           child: Icon(
          //             RemixIcons.arrow_up_s_line,
          //             size: 18,
          //             color: colorScheme.onSecondaryContainer,
          //           ),
          //         ),
          //         M3EButton(
          //           onPressed: onSendBackward,
          //           style: M3EButtonStyle.tonal,
          //           size: M3EButtonSize.sm,
          //           tooltip: 'Send Backward',
          //           child: Icon(
          //             RemixIcons.arrow_down_s_line,
          //             size: 18,
          //             color: colorScheme.onSecondaryContainer,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),

          // Layer List View M3 Expressive Cards
          Expanded(
            child: shapes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.shapes_line,
                          size: 36,
                          color: colorScheme.outline.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No vector layers',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final items = shapes.reversed.toList();
                      return M3EReorderableSegmentedList.builder(
                        keyBuilder: (index) => ValueKey(items[index].id),
                        itemCount: items.length,
                        buildDefaultDragHandles: false,
                        onTap: (index) => onSelectShape(items[index].id),
                        decoration: M3ESegmentedListDecoration(
                          outerRadius: 16.0,
                          innerRadius: 4.0,
                          pressedRadius: 8.0,
                          pressedScale: 0.98,
                          hoveredRadius: 16.0,
                          dragRadius: 24.0,
                          dragElevation: 8.0,
                          dragScale: 1.00,
                          gap: 2.0,
                          padding: const EdgeInsets.all(12.0),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          hoverColor: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.1,
                          ),
                          dragPlaceholderColor:
                              colorScheme.surfaceContainerHighest,
                          // dragPlaceholderBorder: BorderSide(
                          //   color: colorScheme.outline.withValues(alpha: 0.8),
                          //   width: 1,
                          // ),
                          color: colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.4,
                          ),
                          selectedColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.7),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, VectorShape shape) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedShapeIds.contains(shape.id);

    return Row(
      children: [
        Icon(
          _getShapeIcon(shape.type),
          size: 16,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),

        // Layer Name
        Expanded(
          child: GestureDetector(
            onDoubleTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  final controller = TextEditingController(text: shape.name);
                  return AlertDialog(
                    title: const Text('Rename Layer'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Layer Name',
                      ),
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
            },
            child: Text(
              shape.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),

        // Visibility toggle
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(2),
          iconSize: 15,
          icon: Icon(
            shape.isVisible ? RemixIcons.eye_line : RemixIcons.eye_off_line,
            color: shape.isVisible
                ? (isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant)
                : colorScheme.outline.withValues(alpha: 0.4),
          ),
          onPressed: () => onToggleVisibility(shape.id),
        ),

        // Lock toggle
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(2),
          iconSize: 15,
          icon: Icon(
            shape.isLocked ? RemixIcons.lock_line : RemixIcons.lock_unlock_line,
            color: shape.isLocked
                ? colorScheme.tertiary
                : colorScheme.outline.withValues(alpha: 0.4),
          ),
          onPressed: () => onToggleLock(shape.id),
        ),

        // Delete button
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(2),
          iconSize: 15,
          icon: Icon(
            RemixIcons.close_line,
            color: colorScheme.error.withValues(alpha: 0.7),
          ),
          onPressed: () => onDeleteShape(shape.id),
        ),
      ],
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
