import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';
import 'package:nixsvg/widgets/context_menu/figma_context_menu.dart';
import 'package:nixsvg/widgets/settings_dialog.dart';
import 'package:remixicon/remixicon.dart';

/// Pure Material 3 Expressive Layers Sidebar for nixSVG.
/// Features tonal surface container styling, reorderable segments,
/// physics-based spring interactions, selection tool multi-select,
/// and full right-click / two-finger press Figma-style context menus.
class LayersSidebar extends StatefulWidget {
  final List<VectorShape> shapes;
  final Set<String> selectedShapeIds;
  final ValueChanged<String> onSelectShape;
  final ValueChanged<Set<String>>? onSelectShapes;
  final ValueChanged<String> onToggleVisibility;
  final ValueChanged<String> onToggleLock;
  final ValueChanged<String> onDeleteShape;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final VoidCallback? onBringToFront;
  final VoidCallback? onSendToBack;
  final ValueChanged<String>? onDuplicateShape;
  final ValueChanged<String>? onCopySvg;
  final Function(String id, String newName) onRenameShape;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onGroupShapes;
  final VoidCallback? onUngroupShapes;
  final double? width;

  const LayersSidebar({
    super.key,
    required this.shapes,
    required this.selectedShapeIds,
    required this.onSelectShape,
    this.onSelectShapes,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onDeleteShape,
    required this.onBringForward,
    required this.onSendBackward,
    this.onBringToFront,
    this.onSendToBack,
    this.onDuplicateShape,
    this.onCopySvg,
    required this.onRenameShape,
    this.onReorder,
    this.onOpenSettings,
    this.onGroupShapes,
    this.onUngroupShapes,
    this.width,
  });

  @override
  State<LayersSidebar> createState() => _LayersSidebarState();
}

class _LayersSidebarState extends State<LayersSidebar> {
  int? _lastAnchorIndex;

  void _handleLayerTap(int index, List<VectorShape> items) {
    final shape = items[index];
    final isShiftPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftRight,
        );
    final isMetaOrCtrl =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.metaLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.metaRight,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.controlLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.controlRight,
        );

    final newSelection = Set<String>.from(widget.selectedShapeIds);

    if (isShiftPressed &&
        _lastAnchorIndex != null &&
        _lastAnchorIndex! < items.length) {
      // Range selection (Figma style)
      final start = math.min(_lastAnchorIndex!, index);
      final end = math.max(_lastAnchorIndex!, index);
      if (!isMetaOrCtrl) {
        newSelection.clear();
      }
      for (int i = start; i <= end; i++) {
        newSelection.add(items[i].id);
      }
    } else if (isMetaOrCtrl) {
      // Toggle selection (Figma style)
      final targetIds = (shape.groupId != null)
          ? items
                .where((s) => s.groupId == shape.groupId)
                .map((s) => s.id)
                .toSet()
          : {shape.id};
      if (newSelection.containsAll(targetIds)) {
        newSelection.removeAll(targetIds);
      } else {
        newSelection.addAll(targetIds);
      }
      _lastAnchorIndex = index;
    } else {
      // Single selection or Group selection
      newSelection.clear();
      if (shape.groupId != null) {
        for (final s in items) {
          if (s.groupId == shape.groupId) {
            newSelection.add(s.id);
          }
        }
      } else {
        newSelection.add(shape.id);
      }
      _lastAnchorIndex = index;
    }

    if (widget.onSelectShapes != null) {
      widget.onSelectShapes!(newSelection);
    } else {
      widget.onSelectShape(shape.id);
    }
  }

  void _selectAllLayers(List<VectorShape> items) {
    final allIds = items.map((s) => s.id).toSet();
    if (widget.onSelectShapes != null) {
      widget.onSelectShapes!(allIds);
    } else if (items.isNotEmpty) {
      widget.onSelectShape(items.first.id);
    }
  }

  void _deselectAllLayers() {
    if (widget.onSelectShapes != null) {
      widget.onSelectShapes!({});
    }
    _lastAnchorIndex = null;
  }

  void _invertSelection(List<VectorShape> items) {
    final current = widget.selectedShapeIds;
    final inverted = items
        .map((s) => s.id)
        .where((id) => !current.contains(id))
        .toSet();
    widget.onSelectShapes?.call(inverted);
  }

  void _showLayerContextMenu(
    BuildContext context,
    Offset globalPos,
    VectorShape shape,
  ) {
    // Select this shape (or its whole group) if not part of current selection
    if (!widget.selectedShapeIds.contains(shape.id)) {
      final newSelection = (shape.groupId != null)
          ? widget.shapes
                .where((s) => s.groupId == shape.groupId)
                .map((s) => s.id)
                .toSet()
          : {shape.id};
      widget.onSelectShapes?.call(newSelection);
      widget.onSelectShape(shape.id);
    }

    final hasSelection = widget.selectedShapeIds.isNotEmpty;
    final isLocked = shape.isLocked;
    final isVisible = shape.isVisible;
    final hasGroup = widget.shapes
        .where((s) => widget.selectedShapeIds.contains(s.id))
        .any((s) => s.groupId != null);

    showFigmaContextMenu(
      context: context,
      globalPosition: globalPos,
      items: [
        FigmaContextMenuEntry.action(
          title: 'Rename Layer',
          icon: RemixIcons.edit_line,
          shortcut: '↵',
          onTap: () => _showRenameDialog(context, shape),
        ),
        FigmaContextMenuEntry.action(
          title: 'Duplicate Layer',
          icon: RemixIcons.file_copy_2_line,
          shortcut: '⌘D',
          isEnabled: hasSelection,
          onTap: () => widget.onDuplicateShape?.call(shape.id),
        ),
        FigmaContextMenuEntry.action(
          title: 'Delete Layer',
          icon: RemixIcons.delete_bin_line,
          shortcut: '⌫',
          isDestructive: true,
          isEnabled: hasSelection,
          onTap: () => widget.onDeleteShape(shape.id),
        ),
        const FigmaContextMenuEntry.divider(),
        if (widget.onGroupShapes != null)
          FigmaContextMenuEntry.action(
            title: 'Group Selection',
            icon: Icons.folder_outlined,
            shortcut: '⌘G',
            isEnabled: hasSelection,
            onTap: widget.onGroupShapes,
          ),
        if (widget.onUngroupShapes != null && hasGroup)
          FigmaContextMenuEntry.action(
            title: 'Ungroup Selection',
            icon: Icons.folder_open_outlined,
            shortcut: '⇧⌘G',
            onTap: widget.onUngroupShapes,
          ),
        const FigmaContextMenuEntry.divider(),
        FigmaContextMenuEntry.action(
          title: 'Bring to Front',
          icon: RemixIcons.bring_to_front,
          shortcut: '⇧⌘]',
          isEnabled: hasSelection,
          onTap: widget.onBringToFront ?? widget.onBringForward,
        ),
        FigmaContextMenuEntry.action(
          title: 'Bring Forward',
          icon: RemixIcons.bring_forward,
          shortcut: '⌘]',
          isEnabled: hasSelection,
          onTap: widget.onBringForward,
        ),
        FigmaContextMenuEntry.action(
          title: 'Send Backward',
          icon: RemixIcons.send_backward,
          shortcut: '⌘[',
          isEnabled: hasSelection,
          onTap: widget.onSendBackward,
        ),
        FigmaContextMenuEntry.action(
          title: 'Send to Back',
          icon: RemixIcons.send_to_back,
          shortcut: '⇧⌘[',
          isEnabled: hasSelection,
          onTap: widget.onSendToBack ?? widget.onSendBackward,
        ),
        const FigmaContextMenuEntry.divider(),
        FigmaContextMenuEntry.action(
          title: isLocked ? 'Unlock Layer' : 'Lock Layer',
          icon: isLocked ? RemixIcons.lock_unlock_line : RemixIcons.lock_line,
          shortcut: '⇧⌘L',
          onTap: () => widget.onToggleLock(shape.id),
        ),
        FigmaContextMenuEntry.action(
          title: isVisible ? 'Hide Layer' : 'Show Layer',
          icon: isVisible ? RemixIcons.eye_off_line : RemixIcons.eye_line,
          shortcut: '⇧⌘H',
          onTap: () => widget.onToggleVisibility(shape.id),
        ),
        const FigmaContextMenuEntry.divider(),
        FigmaContextMenuEntry.action(
          title: 'Copy as SVG',
          icon: RemixIcons.code_s_slash_line,
          shortcut: '⇧⌘C',
          onTap: () => widget.onCopySvg?.call(shape.id),
        ),
      ],
    );
  }

  void _showEmptyLayersContextMenu(BuildContext context, Offset globalPos) {
    final items = widget.shapes.reversed.toList();
    showFigmaContextMenu(
      context: context,
      globalPosition: globalPos,
      items: [
        FigmaContextMenuEntry.action(
          title: 'Select All Layers',
          icon: RemixIcons.checkbox_multiple_line,
          shortcut: '⌘A',
          isEnabled: items.isNotEmpty,
          onTap: () => _selectAllLayers(items),
        ),
        FigmaContextMenuEntry.action(
          title: 'Deselect All',
          icon: RemixIcons.checkbox_blank_line,
          shortcut: 'Esc',
          isEnabled: widget.selectedShapeIds.isNotEmpty,
          onTap: _deselectAllLayers,
        ),
        const FigmaContextMenuEntry.divider(),
        FigmaContextMenuEntry.action(
          title: 'Invert Selection',
          icon: RemixIcons.arrow_left_right_line,
          isEnabled: items.isNotEmpty,
          onTap: () => _invertSelection(items),
        ),
        const FigmaContextMenuEntry.divider(),
        FigmaContextMenuEntry.action(
          title: 'Settings & Preferences',
          icon: RemixIcons.settings_3_line,
          shortcut: '⌘,',
          onTap: () {
            if (widget.onOpenSettings != null) {
              widget.onOpenSettings!();
            } else {
              showAppSettingsDialog(context);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final items = widget.shapes.reversed.toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) {
        _showEmptyLayersContextMenu(context, details.globalPosition);
      },
      child: Container(
        width: widget.width ?? 270,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
              child: LayoutBuilder(
                builder: (context, headerConstraints) {
                  final isCompactHeader = headerConstraints.maxWidth < 220;
                  final isVeryNarrow = headerConstraints.maxWidth < 180;
                  return Row(
                    children: [
                      Icon(
                        RemixIcons.stack_line,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Layers',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message:
                            '${items.length} total layers • Click to Select All',
                        child: InkWell(
                          onTap: items.isNotEmpty
                              ? () => _selectAllLayers(items)
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${items.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Selection Tool Quick Actions (Select All, Clear, Bring Forward, Send Backward)
                      if (items.isNotEmpty &&
                          (!isVeryNarrow ||
                              widget.selectedShapeIds.isEmpty)) ...[
                        _M3EHeaderAction(
                          icon: RemixIcons.checkbox_multiple_line,
                          tooltip: 'Select All Layers (⌘A)',
                          onTap: () => _selectAllLayers(items),
                        ),
                        if (widget.selectedShapeIds.isNotEmpty)
                          const SizedBox(width: 3),
                      ],

                      if (widget.selectedShapeIds.isNotEmpty) ...[
                        _M3EHeaderAction(
                          icon: RemixIcons.close_line,
                          tooltip: 'Deselect All (Esc)',
                          onTap: _deselectAllLayers,
                        ),
                        if (!isCompactHeader) ...[
                          const SizedBox(width: 3),
                          _M3EHeaderAction(
                            icon: RemixIcons.arrow_up_s_line,
                            tooltip: 'Bring Forward (⌘])',
                            onTap: widget.onBringForward,
                          ),
                          const SizedBox(width: 3),
                          _M3EHeaderAction(
                            icon: RemixIcons.arrow_down_s_line,
                            tooltip: 'Send Backward (⌘[)',
                            onTap: widget.onSendBackward,
                          ),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ),

            // --- Layer List View with M3EReorderableSegmentedList & Marquee Drag Select ---
            Expanded(
              child: widget.shapes.isEmpty
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Theme(
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
                        onTap: (index) => _handleLayerTap(index, items),
                        decoration: M3ESegmentedListDecoration(
                          outerRadius: 8.0,
                          innerRadius: 4.0,
                          pressedRadius: 6.0,
                          pressedScale: 1.0,
                          hoveredRadius: 8.0,
                          dragRadius: 8.0,
                          dragElevation: 3.0,
                          dragScale: 1.0,
                          gap: 1.5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 4.0,
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 1.0,
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
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.25,
                                ),
                          selectedColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.65),
                        ),
                        onReorder: (oldIndex, newIndex) {
                          if (widget.onReorder != null) {
                            widget.onReorder!(oldIndex, newIndex);
                          } else {
                            if (newIndex > oldIndex) newIndex--;
                            final item = items.removeAt(oldIndex);
                            items.insert(newIndex, item);
                            widget.shapes.clear();
                            widget.shapes.addAll(items.reversed);
                          }
                        },
                        itemBuilder: (context, index) {
                          return _buildListItem(
                            context,
                            items[index],
                            index,
                            items,
                          );
                        },
                      ),
                    ),
            ),

            // --- Material 3 Expressive Sidebar Footer ---
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      if (widget.onOpenSettings != null) {
                        widget.onOpenSettings!();
                      } else {
                        showAppSettingsDialog(context);
                      }
                    },
                  ),
                  const Spacer(),
                  if (widget.selectedShapeIds.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: InkWell(
                        onTap: _deselectAllLayers,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '${widget.selectedShapeIds.length} sel',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                RemixIcons.close_line,
                                size: 11,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    VectorShape shape,
    int index,
    List<VectorShape> items,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = widget.selectedShapeIds.contains(shape.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleLayerTap(index, items),
      onSecondaryTapDown: (details) {
        _showLayerContextMenu(context, details.globalPosition, shape);
      },
      child: Row(
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
              onTap: () => _handleLayerTap(index, items),
              onDoubleTap: () => _showRenameDialog(context, shape),
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      shape.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  if (shape.groupName != null) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          shape.groupName!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Visibility Toggle
          _M3ELayerActionBtn(
            tooltip: shape.isVisible ? 'Hide Layer' : 'Show Layer',
            icon: shape.isVisible
                ? RemixIcons.eye_line
                : RemixIcons.eye_off_line,
            iconColor: shape.isVisible
                ? (isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7))
                : colorScheme.outline.withValues(alpha: 0.35),
            onTap: () => widget.onToggleVisibility(shape.id),
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
            onTap: () => widget.onToggleLock(shape.id),
          ),

          // Delete Layer
          _M3ELayerActionBtn(
            tooltip: 'Delete Layer',
            icon: RemixIcons.close_line,
            iconColor: colorScheme.error.withValues(alpha: 0.7),
            onTap: () => widget.onDeleteShape(shape.id),
          ),
        ],
      ),
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
                widget.onRenameShape(shape.id, value.trim());
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  widget.onRenameShape(shape.id, controller.text.trim());
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
      case ShapeType.polygon:
        return RemixIcons.hexagon_line;
      case ShapeType.path:
        return RemixIcons.pen_nib_line;
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
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
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
        padding: const EdgeInsets.all(2.5),
        child: Icon(icon, size: 14, color: iconColor),
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
      enableHoverHighlight: true,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 15,
          color: enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
