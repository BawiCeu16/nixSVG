import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';
import 'package:nixsvg/widgets/settings_dialog.dart';
import 'package:remixicon/remixicon.dart';

/// Pure Material 3 Expressive Layers Sidebar for nixSVG.
/// Features tonal surface container styling, reorderable segments,
/// physics-based spring interactions, and layer hierarchy management.
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
  final VoidCallback? onOpenSettings;
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
    this.onOpenSettings,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width ?? 270,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.35 : 0.45,
            ),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // --- Material 3 Expressive Sidebar Header ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.25 : 0.35,
                  ),
                  width: 1.0,
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
                  _M3EHeaderAction(
                    icon: RemixIcons.arrow_up_s_line,
                    tooltip: 'Bring Forward',
                    onTap: onBringForward,
                  ),
                  const SizedBox(width: 4),
                  _M3EHeaderAction(
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
                              color: colorScheme.outline.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No vector layers',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Draw shapes using the dock tools.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
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
                            pressedScale: 1.0,
                            hoveredRadius: 10.0,
                            dragRadius: 12.0,
                            dragElevation: 4.0,
                            dragScale: 1.0,
                            gap: 2.0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 8.0,
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.0,
                            ),
                            hoverColor: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.08,
                            ),
                            dragPlaceholderColor:
                                colorScheme.surfaceContainerHighest,
                            color: isDark
                                ? colorScheme.surfaceContainerHigh.withValues(
                                    alpha: 0.3,
                                  )
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
          // --- Material 3 Expressive Sidebar Footer ---
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.25 : 0.35,
                  ),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                // Settings & Preferences
                _M3EIconButton(
                  icon: RemixIcons.settings_3_line,
                  tooltip: 'Settings & Preferences (Ctrl+,)',
                  enabled: true,
                  onTap: () {
                    if (onOpenSettings != null) {
                      onOpenSettings!();
                    } else {
                      showAppSettingsDialog(context);
                    }
                  },
                ),
                const Spacer(),
                if (selectedShapeIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.6,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedShapeIds.length} selected',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
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
        _M3ELayerActionBtn(
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
        _M3ELayerActionBtn(
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
        _M3ELayerActionBtn(
          tooltip: 'Delete Layer',
          icon: RemixIcons.close_line,
          iconColor: colorScheme.error.withValues(alpha: 0.7),
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
    ).then((_) {
      controller.dispose();
    });
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

class _M3EHeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _M3EHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return M3PhysicsPressable(
      tooltip: tooltip,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _M3ELayerActionBtn extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _M3ELayerActionBtn({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return M3PhysicsPressable(
      tooltip: tooltip,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 15, color: iconColor),
      ),
    );
  }
}

/// Material 3 Expressive Icon Button with spring physics.
class _M3EIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _M3EIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return M3PhysicsPressable(
      tooltip: tooltip,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 17,
          color: enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
