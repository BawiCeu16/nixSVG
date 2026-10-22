import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/color_picker_dialog.dart';
import 'package:nixsvg/widgets/nix_slider.dart';
import 'package:remixicon/remixicon.dart';

class PropertiesSidebar extends StatelessWidget {
  final VectorShape? selectedShape;
  final ValueChanged<VectorShape> onShapeChanged;
  final ValueChanged<VectorShape>? onShapeChangeEnd;
  final void Function([Rect? anchorRect]) onOpenColorPickerFill;
  final void Function([Rect? anchorRect]) onOpenColorPickerStroke;
  final VoidCallback onDuplicateShape;
  final VoidCallback onDeleteSelected;
  final Function(String align) onAlignShape;
  final VoidCallback? onGroupShapes;
  final VoidCallback? onUngroupShapes;
  final bool canGroup;
  final bool canUngroup;
  final double? width;
  final Color? canvasBackgroundColor;
  final Size? canvasSize;
  final ValueChanged<Size>? onCanvasSizeChanged;
  final ValueChanged<Color>? onCanvasBackgroundColorChanged;
  final bool? snapToGrid;
  final ValueChanged<bool>? onToggleSnapToGrid;
  final double? gridSpacing;
  final ValueChanged<double>? onGridSpacingChanged;
  final int totalShapesCount;
  final double zoomScale;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final ValueChanged<double>? onSetZoomScale;
  final bool isPanMode;
  final VoidCallback? onTogglePanMode;
  final VoidCallback? onCenterCanvas;
  final VoidCallback? onResetZoom;
  final VoidCallback? onZoomToFit;
  final VoidCallback? onZoomToSelection;
  final VoidCallback? onSelectAll;
  final VoidCallback? onExportSvg;
  final VoidCallback? onClearCanvas;

  const PropertiesSidebar({
    super.key,
    required this.selectedShape,
    required this.onShapeChanged,
    this.onShapeChangeEnd,
    required this.onOpenColorPickerFill,
    required this.onOpenColorPickerStroke,
    required this.onDuplicateShape,
    required this.onDeleteSelected,
    required this.onAlignShape,
    this.onGroupShapes,
    this.onUngroupShapes,
    this.canGroup = false,
    this.canUngroup = false,
    this.width,
    this.canvasSize,
    this.onCanvasSizeChanged,
    this.canvasBackgroundColor,
    this.onCanvasBackgroundColorChanged,
    this.snapToGrid,
    this.onToggleSnapToGrid,
    this.gridSpacing,
    this.onGridSpacingChanged,
    this.totalShapesCount = 0,
    this.zoomScale = 1.0,
    this.onZoomIn,
    this.onZoomOut,
    this.onSetZoomScale,
    this.isPanMode = false,
    this.onTogglePanMode,
    this.onCenterCanvas,
    this.onResetZoom,
    this.onZoomToFit,
    this.onZoomToSelection,
    this.onSelectAll,
    this.onExportSvg,
    this.onClearCanvas,
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
          width: width ?? 280,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(
              alpha: isDark ? 0.75 : 0.88,
            ),
            border: Border(
              left: BorderSide(
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.25 : 0.35,
                ),
                width: 0.8,
              ),
            ),
          ),
          child: selectedShape == null
              ? _buildCanvasProperties(context, theme, colorScheme, isDark)
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  children: [
                    // Header Card
                    _buildSectionCard(
                      context,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getShapeIcon(selectedShape!.type),
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  selectedShape!.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (selectedShape!.groupName != null) ...[
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 90),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.folder_outlined,
                                          size: 10,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            selectedShape!.groupName!,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (onGroupShapes != null) ...[
                                Expanded(
                                  child: M3EButton(
                                    onPressed: canGroup ? onGroupShapes : null,
                                    style: M3EButtonStyle.tonal,
                                    size: M3EButtonSize.sm,
                                    tooltip: 'Group (Ctrl+G)',
                                    child: Icon(
                                      Icons.folder_outlined,
                                      size: 15,
                                      color: canGroup
                                          ? colorScheme.onSecondaryContainer
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.38,
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (canUngroup && onUngroupShapes != null) ...[
                                Expanded(
                                  child: M3EButton(
                                    onPressed: onUngroupShapes,
                                    style: M3EButtonStyle.tonal,
                                    size: M3EButtonSize.sm,
                                    tooltip: 'Ungroup (Ctrl+Shift+G)',
                                    child: Icon(
                                      Icons.folder_open_outlined,
                                      size: 15,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: M3EButton(
                                  onPressed: onDuplicateShape,
                                  style: M3EButtonStyle.tonal,
                                  size: M3EButtonSize.sm,
                                  tooltip: 'Duplicate (Ctrl+D)',
                                  child: Icon(
                                    RemixIcons.file_copy_line,
                                    size: 15,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: M3EButton(
                                  onPressed: onDeleteSelected,
                                  style: M3EButtonStyle.tonal,
                                  size: M3EButtonSize.sm,
                                  tooltip: 'Delete (Del)',
                                  decoration: M3EButtonDecoration(
                                    backgroundColor: WidgetStatePropertyAll(
                                      colorScheme.errorContainer,
                                    ),
                                    foregroundColor: WidgetStatePropertyAll(
                                      colorScheme.onErrorContainer,
                                    ),
                                  ),
                                  child: Icon(
                                    RemixIcons.delete_bin_line,
                                    size: 15,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Alignment Card
                    _buildSectionCard(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALIGNMENT',
                            style: _getSectionHeaderStyle(theme),
                          ),
                          const SizedBox(height: 5),

                          // Row 1: Horizontal Alignment (Left, Center, Right - connected)
                          M3ESegmentedRow(
                            onTap: (index) {
                              const types = ['left', 'center', 'right'];
                              onAlignShape(types[index]);
                            },
                            equalWidth: true,
                            gap: 1.5,
                            decoration: M3ESegmentedListDecoration(
                              outerRadius: 8.0,
                              innerRadius: 3.0,
                              gap: 1.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              hoverColor: colorScheme.surfaceContainerHighest,
                              pressedRadius: 6.0,
                              pressedScale: 1.0,
                            ),
                            children: [
                              Tooltip(
                                message: 'Align Left',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.align_left,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Align Center',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.align_center,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Align Right',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.align_right,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Row 2: Vertical Alignment (Top, Middle, Bottom - connected)
                          M3ESegmentedRow(
                            onTap: (index) {
                              const types = ['top', 'middle', 'bottom'];
                              onAlignShape(types[index]);
                            },
                            equalWidth: true,
                            gap: 1.5,
                            decoration: M3ESegmentedListDecoration(
                              outerRadius: 8.0,
                              innerRadius: 3.0,
                              gap: 1.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              hoverColor: colorScheme.surfaceContainerHighest,
                              pressedRadius: 6.0,
                              pressedScale: 1.0,
                            ),
                            children: [
                              Tooltip(
                                message: 'Align Top',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.align_top,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Align Middle',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.align_vertically,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Align Bottom',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.align_bottom,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Transform Card
                    _buildSectionCard(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRANSFORM',
                            style: _getSectionHeaderStyle(theme),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField(
                                  context,
                                  'X',
                                  selectedShape!.rect.left,
                                  (val) {
                                    final isLine =
                                        selectedShape!.type == ShapeType.line;
                                    final newRect = isLine
                                        ? Rect.fromLTRB(
                                            val,
                                            selectedShape!.rect.top,
                                            val +
                                                (selectedShape!.rect.right -
                                                    selectedShape!.rect.left),
                                            selectedShape!.rect.bottom,
                                          )
                                        : Rect.fromLTWH(
                                            val,
                                            selectedShape!.rect.top,
                                            selectedShape!.rect.width,
                                            selectedShape!.rect.height,
                                          );
                                    final updated = selectedShape!.copyWith(
                                      rect: newRect,
                                    );
                                    onShapeChanged(updated);
                                    onShapeChangeEnd?.call(updated);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNumberField(
                                  context,
                                  'Y',
                                  selectedShape!.rect.top,
                                  (val) {
                                    final isLine =
                                        selectedShape!.type == ShapeType.line;
                                    final newRect = isLine
                                        ? Rect.fromLTRB(
                                            selectedShape!.rect.left,
                                            val,
                                            selectedShape!.rect.right,
                                            val +
                                                (selectedShape!.rect.bottom -
                                                    selectedShape!.rect.top),
                                          )
                                        : Rect.fromLTWH(
                                            selectedShape!.rect.left,
                                            val,
                                            selectedShape!.rect.width,
                                            selectedShape!.rect.height,
                                          );
                                    final updated = selectedShape!.copyWith(
                                      rect: newRect,
                                    );
                                    onShapeChanged(updated);
                                    onShapeChangeEnd?.call(updated);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (selectedShape!.type == ShapeType.line) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'L',
                                    math.sqrt(
                                      (selectedShape!.rect.right -
                                                  selectedShape!.rect.left) *
                                              (selectedShape!.rect.right -
                                                  selectedShape!.rect.left) +
                                          (selectedShape!.rect.bottom -
                                                  selectedShape!.rect.top) *
                                              (selectedShape!.rect.bottom -
                                                  selectedShape!.rect.top),
                                    ),
                                    (val) {
                                      final p1 = selectedShape!.rect.topLeft;
                                      final p2 =
                                          selectedShape!.rect.bottomRight;
                                      final dx = p2.dx - p1.dx;
                                      final dy = p2.dy - p1.dy;
                                      final currentLen = math.sqrt(
                                        dx * dx + dy * dy,
                                      );
                                      final angle = currentLen > 0
                                          ? math.atan2(dy, dx)
                                          : 0.0;
                                      final newLen = val.clamp(1.0, 10000.0);
                                      final newEnd =
                                          p1 +
                                          Offset(
                                            newLen * math.cos(angle),
                                            newLen * math.sin(angle),
                                          );
                                      final newRect = Rect.fromLTRB(
                                        p1.dx,
                                        p1.dy,
                                        newEnd.dx,
                                        newEnd.dy,
                                      );
                                      final updated = selectedShape!.copyWith(
                                        rect: newRect,
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'A°',
                                    (math.atan2(
                                              selectedShape!.rect.bottom -
                                                  selectedShape!.rect.top,
                                              selectedShape!.rect.right -
                                                  selectedShape!.rect.left,
                                            ) *
                                            180 /
                                            math.pi)
                                        .roundToDouble(),
                                    (val) {
                                      final p1 = selectedShape!.rect.topLeft;
                                      final p2 =
                                          selectedShape!.rect.bottomRight;
                                      final dx = p2.dx - p1.dx;
                                      final dy = p2.dy - p1.dy;
                                      final currentLen = math.max(
                                        1.0,
                                        math.sqrt(dx * dx + dy * dy),
                                      );
                                      final rad = val * math.pi / 180.0;
                                      final newEnd =
                                          p1 +
                                          Offset(
                                            currentLen * math.cos(rad),
                                            currentLen * math.sin(rad),
                                          );
                                      final newRect = Rect.fromLTRB(
                                        p1.dx,
                                        p1.dy,
                                        newEnd.dx,
                                        newEnd.dy,
                                      );
                                      final updated = selectedShape!.copyWith(
                                        rect: newRect,
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'W',
                                    selectedShape!.rect.width,
                                    (val) {
                                      final newRect = Rect.fromLTWH(
                                        selectedShape!.rect.left,
                                        selectedShape!.rect.top,
                                        val.clamp(5, 5000),
                                        selectedShape!.rect.height,
                                      );
                                      final updated = selectedShape!.copyWith(
                                        rect: newRect,
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'H',
                                    selectedShape!.rect.height,
                                    (val) {
                                      final newRect = Rect.fromLTWH(
                                        selectedShape!.rect.left,
                                        selectedShape!.rect.top,
                                        selectedShape!.rect.width,
                                        val.clamp(5, 5000),
                                      );
                                      final updated = selectedShape!.copyWith(
                                        rect: newRect,
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField(
                                  context,
                                  '°',
                                  selectedShape!.rotation,
                                  (val) {
                                    final updated = selectedShape!.copyWith(
                                      rotation: val % 360,
                                    );
                                    onShapeChanged(updated);
                                    onShapeChangeEnd?.call(updated);
                                  },
                                ),
                              ),
                              if (selectedShape!.type ==
                                      ShapeType.roundedRectangle ||
                                  selectedShape!.type == ShapeType.rectangle ||
                                  selectedShape!.type == ShapeType.star ||
                                  selectedShape!.type == ShapeType.image) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'R',
                                    selectedShape!.cornerRadius,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        cornerRadius: val.clamp(0, 200),
                                        clearIndependentCorners: true,
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                                if (selectedShape!.type ==
                                        ShapeType.rectangle ||
                                    selectedShape!.type ==
                                        ShapeType.roundedRectangle ||
                                    selectedShape!.type == ShapeType.image) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message:
                                        selectedShape!.hasIndependentCorners
                                        ? 'Link Corner Radii'
                                        : 'Independent Corner Radii',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        if (selectedShape!
                                            .hasIndependentCorners) {
                                          final updated = selectedShape!
                                              .copyWith(
                                                clearIndependentCorners: true,
                                              );
                                          onShapeChanged(updated);
                                          onShapeChangeEnd?.call(updated);
                                        } else {
                                          final cur =
                                              selectedShape!.cornerRadius;
                                          final updated = selectedShape!
                                              .copyWith(
                                                topLeftRadius: cur,
                                                topRightRadius: cur,
                                                bottomRightRadius: cur,
                                                bottomLeftRadius: cur,
                                              );
                                          onShapeChanged(updated);
                                          onShapeChangeEnd?.call(updated);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color:
                                              selectedShape!
                                                  .hasIndependentCorners
                                              ? colorScheme.primary.withValues(
                                                  alpha: 0.16,
                                                )
                                              : colorScheme
                                                    .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                selectedShape!
                                                    .hasIndependentCorners
                                                ? colorScheme.primary
                                                : colorScheme.outlineVariant
                                                      .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Icon(
                                          RemixIcons.corner_up_left_line,
                                          size: 15,
                                          color:
                                              selectedShape!
                                                  .hasIndependentCorners
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                          if ((selectedShape!.type == ShapeType.rectangle ||
                                  selectedShape!.type ==
                                      ShapeType.roundedRectangle ||
                                  selectedShape!.type == ShapeType.image) &&
                              selectedShape!.hasIndependentCorners) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'TL',
                                    selectedShape!.effectiveTopLeftRadius,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        topLeftRadius: val.clamp(0, 200),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'TR',
                                    selectedShape!.effectiveTopRightRadius,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        topRightRadius: val.clamp(0, 200),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'BL',
                                    selectedShape!.effectiveBottomLeftRadius,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        bottomLeftRadius: val.clamp(0, 200),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'BR',
                                    selectedShape!.effectiveBottomRightRadius,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        bottomRightRadius: val.clamp(0, 200),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    final updated = selectedShape!.copyWith(
                                      rotation:
                                          (-selectedShape!.rotation) % 360,
                                    );
                                    onShapeChanged(updated);
                                    onShapeChangeEnd?.call(updated);
                                  },
                                  icon: const Icon(
                                    RemixIcons.swap_line,
                                    size: 14,
                                  ),
                                  label: Text(
                                    'Flip H',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    final updated = selectedShape!.copyWith(
                                      rotation:
                                          (180 - selectedShape!.rotation) % 360,
                                    );
                                    onShapeChanged(updated);
                                    onShapeChangeEnd?.call(updated);
                                  },
                                  icon: const Icon(
                                    RemixIcons.swap_box_line,
                                    size: 14,
                                  ),
                                  label: Text(
                                    'Flip V',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Star Geometry Card (Sharp Points Count & Ratio)
                    if (selectedShape!.type == ShapeType.star)
                      _buildSectionCard(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'STAR',
                                    style: _getSectionHeaderStyle(theme),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${selectedShape!.pointCount} Points',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'PTS',
                                    selectedShape!.pointCount.toDouble(),
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        pointCount: val.round().clamp(3, 60),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                    min: 3,
                                    max: 60,
                                    isInteger: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    '%',
                                    (selectedShape!.innerRadiusRatio * 100)
                                        .roundToDouble(),
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        innerRadiusRatio: (val / 100.0).clamp(
                                          0.05,
                                          0.95,
                                        ),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                    min: 5,
                                    max: 95,
                                    isInteger: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _ScrubbableLabel(
                                  label: 'Ratio',
                                  value: (selectedShape!.innerRadiusRatio * 100)
                                      .clamp(5.0, 95.0),
                                  min: 5.0,
                                  max: 95.0,
                                  onChanged: (val) {
                                    final updated = selectedShape!.copyWith(
                                      innerRadiusRatio: (val / 100.0).clamp(
                                        0.05,
                                        0.95,
                                      ),
                                    );
                                    onShapeChanged(updated);
                                  },
                                  onEditingComplete: () {
                                    final updated = selectedShape!.copyWith(
                                      innerRadiusRatio:
                                          (selectedShape!.innerRadiusRatio)
                                              .clamp(0.05, 0.95),
                                    );
                                    onShapeChangeEnd?.call(updated);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: NixSlider(
                                    value:
                                        (selectedShape!.innerRadiusRatio * 100)
                                            .clamp(5.0, 95.0),
                                    min: 5.0,
                                    max: 95.0,
                                    onChanged: (val) {
                                      final updated = selectedShape!.copyWith(
                                        innerRadiusRatio: (val / 100.0).clamp(
                                          0.05,
                                          0.95,
                                        ),
                                      );
                                      onShapeChanged(updated);
                                    },
                                    onChangeEnd: (val) {
                                      final updated = selectedShape!.copyWith(
                                        innerRadiusRatio: (val / 100.0).clamp(
                                          0.05,
                                          0.95,
                                        ),
                                      );
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(selectedShape!.innerRadiusRatio * 100).round()}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Fill Color, Gradient & Opacity
                    if (selectedShape!.type != ShapeType.line &&
                        selectedShape!.type != ShapeType.image)
                      _buildSectionCard(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  selectedShape!.type == ShapeType.text
                                      ? 'TEXT COLOR'
                                      : 'FILL',
                                  style: _getSectionHeaderStyle(theme),
                                ),
                                const Spacer(),
                                Switch(
                                  value: selectedShape!.isFilled,
                                  activeTrackColor: colorScheme.primary,
                                  onChanged: (val) {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    final updated = selectedShape!.copyWith(
                                      isFilled: val,
                                    );
                                    onShapeChanged(updated);
                                    onShapeChangeEnd?.call(updated);
                                  },
                                ),
                              ],
                            ),
                            if (selectedShape!.isFilled) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTapUp: (details) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      onOpenColorPickerFill(
                                        Rect.fromCenter(
                                          center: details.globalPosition,
                                          width: 32,
                                          height: 32,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            selectedShape!.fillType ==
                                                PaintFillType.solid
                                            ? selectedShape!.fillColor
                                            : null,
                                        gradient:
                                            selectedShape!.fillType !=
                                                    PaintFillType.solid &&
                                                selectedShape!.fillGradient !=
                                                    null
                                            ? LinearGradient(
                                                colors: selectedShape!
                                                    .fillGradient!
                                                    .stops
                                                    .map((s) => s.color)
                                                    .toList(),
                                                stops: selectedShape!
                                                    .fillGradient!
                                                    .stops
                                                    .map((s) => s.offset)
                                                    .toList(),
                                              )
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTapUp: (details) {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        onOpenColorPickerFill(
                                          Rect.fromCenter(
                                            center: details.globalPosition,
                                            width: 60,
                                            height: 24,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          selectedShape!.fillType ==
                                                  PaintFillType.solid
                                              ? _colorToHex(
                                                  selectedShape!.fillColor,
                                                )
                                              : (selectedShape!.fillType ==
                                                        PaintFillType
                                                            .linearGradient
                                                    ? 'Linear'
                                                    : 'Radial'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontFamily:
                                                    selectedShape!.fillType ==
                                                        PaintFillType.solid
                                                    ? 'monospace'
                                                    : null,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(selectedShape!.fillOpacity * 100).round()}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _ScrubbableLabel(
                                    label: 'Opacity',
                                    value: (selectedShape!.fillOpacity * 100)
                                        .clamp(0.0, 100.0),
                                    min: 0.0,
                                    max: 100.0,
                                    onChanged: (val) {
                                      onShapeChanged(
                                        selectedShape!.copyWith(
                                          fillOpacity: (val / 100.0).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                        ),
                                      );
                                    },
                                    onEditingComplete: () {
                                      (onShapeChangeEnd ?? onShapeChanged)(
                                        selectedShape!,
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(selectedShape!.fillOpacity * 100).round()}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              NixSlider(
                                value: selectedShape!.fillOpacity,
                                min: 0.0,
                                max: 1.0,
                                onChangeStart: (_) => FocusManager
                                    .instance
                                    .primaryFocus
                                    ?.unfocus(),
                                onChanged: (val) {
                                  onShapeChanged(
                                    selectedShape!.copyWith(fillOpacity: val),
                                  );
                                },
                                onChangeEnd: (val) {
                                  (onShapeChangeEnd ?? onShapeChanged)(
                                    selectedShape!.copyWith(fillOpacity: val),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Stroke Color, Gradient, Opacity & Styles
                    if (selectedShape!.type != ShapeType.image &&
                        selectedShape!.type != ShapeType.text)
                      _buildSectionCard(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'STROKE',
                                  style: _getSectionHeaderStyle(theme),
                                ),
                                const Spacer(),
                                Switch(
                                  value: selectedShape!.isStroked,
                                  activeTrackColor: colorScheme.primary,
                                  onChanged: (val) {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    final updated = selectedShape!.copyWith(
                                      isStroked: val,
                                    );
                                    onShapeChanged(updated);
                                    onShapeChangeEnd?.call(updated);
                                  },
                                ),
                              ],
                            ),
                            if (selectedShape!.isStroked) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTapUp: (details) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      onOpenColorPickerStroke(
                                        Rect.fromCenter(
                                          center: details.globalPosition,
                                          width: 32,
                                          height: 32,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color:
                                            selectedShape!.strokeType ==
                                                PaintFillType.solid
                                            ? selectedShape!.strokeColor
                                            : null,
                                        gradient:
                                            selectedShape!.strokeType !=
                                                    PaintFillType.solid &&
                                                selectedShape!.strokeGradient !=
                                                    null
                                            ? LinearGradient(
                                                colors: selectedShape!
                                                    .strokeGradient!
                                                    .stops
                                                    .map((s) => s.color)
                                                    .toList(),
                                                stops: selectedShape!
                                                    .strokeGradient!
                                                    .stops
                                                    .map((s) => s.offset)
                                                    .toList(),
                                              )
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTapUp: (details) {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        onOpenColorPickerStroke(
                                          Rect.fromCenter(
                                            center: details.globalPosition,
                                            width: 60,
                                            height: 24,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          selectedShape!.strokeType ==
                                                  PaintFillType.solid
                                              ? _colorToHex(
                                                  selectedShape!.strokeColor,
                                                )
                                              : (selectedShape!.strokeType ==
                                                        PaintFillType
                                                            .linearGradient
                                                    ? 'Linear'
                                                    : 'Radial'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontFamily:
                                                    selectedShape!.strokeType ==
                                                        PaintFillType.solid
                                                    ? 'monospace'
                                                    : null,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${selectedShape!.strokeWidth.round()} px',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Stroke Width Slider
                              Row(
                                children: [
                                  _ScrubbableLabel(
                                    label: 'Width',
                                    value: selectedShape!.strokeWidth.clamp(
                                      1.0,
                                      30.0,
                                    ),
                                    min: 1.0,
                                    max: 30.0,
                                    onChanged: (val) {
                                      onShapeChanged(
                                        selectedShape!.copyWith(
                                          strokeWidth: val.clamp(1.0, 30.0),
                                        ),
                                      );
                                    },
                                    onEditingComplete: () {
                                      (onShapeChangeEnd ?? onShapeChanged)(
                                        selectedShape!,
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${selectedShape!.strokeWidth.round()} px',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              NixSlider(
                                value: selectedShape!.strokeWidth,
                                min: 1.0,
                                max: 30.0,
                                onChangeStart: (_) => FocusManager
                                    .instance
                                    .primaryFocus
                                    ?.unfocus(),
                                onChanged: (val) {
                                  onShapeChanged(
                                    selectedShape!.copyWith(strokeWidth: val),
                                  );
                                },
                                onChangeEnd: (val) {
                                  (onShapeChangeEnd ?? onShapeChanged)(
                                    selectedShape!.copyWith(strokeWidth: val),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              // Stroke Opacity Slider
                              Row(
                                children: [
                                  _ScrubbableLabel(
                                    label: 'Opacity',
                                    value: (selectedShape!.strokeOpacity * 100)
                                        .clamp(0.0, 100.0),
                                    min: 0.0,
                                    max: 100.0,
                                    onChanged: (val) {
                                      onShapeChanged(
                                        selectedShape!.copyWith(
                                          strokeOpacity: (val / 100.0).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                        ),
                                      );
                                    },
                                    onEditingComplete: () {
                                      (onShapeChangeEnd ?? onShapeChanged)(
                                        selectedShape!,
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(selectedShape!.strokeOpacity * 100).round()}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              NixSlider(
                                value: selectedShape!.strokeOpacity,
                                min: 0.0,
                                max: 1.0,
                                onChangeStart: (_) => FocusManager
                                    .instance
                                    .primaryFocus
                                    ?.unfocus(),
                                onChanged: (val) {
                                  onShapeChanged(
                                    selectedShape!.copyWith(strokeOpacity: val),
                                  );
                                },
                                onChangeEnd: (val) {
                                  (onShapeChangeEnd ?? onShapeChanged)(
                                    selectedShape!.copyWith(strokeOpacity: val),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              // Stroke Alignment: Inside, Center, Outside
                              Text(
                                'ALIGNMENT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildToggleGroup(
                                selectedIndex:
                                    switch (selectedShape!.strokeAlign) {
                                      StrokeAlign.inside => 0,
                                      StrokeAlign.center => 1,
                                      StrokeAlign.outside => 2,
                                    },
                                onChanged: (index) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  const aligns = [
                                    StrokeAlign.inside,
                                    StrokeAlign.center,
                                    StrokeAlign.outside,
                                  ];
                                  final updated = selectedShape!.copyWith(
                                    strokeAlign: aligns[index],
                                  );
                                  onShapeChanged(updated);
                                  onShapeChangeEnd?.call(updated);
                                },
                                actions: [
                                  M3EToggleButtonGroupAction(
                                    label: Text(
                                      'Inside',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Inside Stroke',
                                  ),
                                  M3EToggleButtonGroupAction(
                                    label: Text(
                                      'Center',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Center Stroke',
                                  ),
                                  M3EToggleButtonGroupAction(
                                    label: Text(
                                      'Outside',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Outside Stroke',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Stroke Style: Solid, Dashed, Dotted
                              Text(
                                'STYLE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildToggleGroup(
                                selectedIndex:
                                    switch (selectedShape!.strokeStyle) {
                                      StrokeStyle.solid => 0,
                                      StrokeStyle.dashed => 1,
                                      StrokeStyle.dotted => 2,
                                    },
                                onChanged: (index) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  final styles = [
                                    StrokeStyle.solid,
                                    StrokeStyle.dashed,
                                    StrokeStyle.dotted,
                                  ];
                                  final updated = selectedShape!.copyWith(
                                    strokeStyle: styles[index],
                                  );
                                  onShapeChanged(updated);
                                  onShapeChangeEnd?.call(updated);
                                },
                                actions: [
                                  M3EToggleButtonGroupAction(
                                    label: Text(
                                      'Solid',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Solid Style',
                                  ),
                                  M3EToggleButtonGroupAction(
                                    label: Text(
                                      'Dashed',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Dashed Style',
                                  ),
                                  M3EToggleButtonGroupAction(
                                    label: Text(
                                      'Dotted',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Dotted Style',
                                  ),
                                ],
                              ),
                              if (selectedShape!.strokeStyle ==
                                  StrokeStyle.dashed) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Dash Length',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${selectedShape!.strokeDashLength.round()} px',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                NixSlider(
                                  value: selectedShape!.strokeDashLength,
                                  min: 1.0,
                                  max: 40.0,
                                  onChangeStart: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  onChanged: (val) {
                                    onShapeChanged(
                                      selectedShape!.copyWith(
                                        strokeDashLength: val,
                                      ),
                                    );
                                  },
                                  onChangeEnd: (val) {
                                    (onShapeChangeEnd ?? onShapeChanged)(
                                      selectedShape!.copyWith(
                                        strokeDashLength: val,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      'Dash Gap',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${selectedShape!.strokeDashGap.round()} px',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                NixSlider(
                                  value: selectedShape!.strokeDashGap,
                                  min: 1.0,
                                  max: 40.0,
                                  onChangeStart: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  onChanged: (val) {
                                    onShapeChanged(
                                      selectedShape!.copyWith(
                                        strokeDashGap: val,
                                      ),
                                    );
                                  },
                                  onChangeEnd: (val) {
                                    (onShapeChangeEnd ?? onShapeChanged)(
                                      selectedShape!.copyWith(
                                        strokeDashGap: val,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],

                            if (selectedShape!.type == ShapeType.line) ...[
                              const SizedBox(height: 12),
                              Text(
                                'CAP STYLE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildToggleGroup(
                                selectedIndex:
                                    switch (selectedShape!.strokeCap) {
                                      StrokeCap.butt => 0,
                                      StrokeCap.round => 1,
                                      StrokeCap.square => 2,
                                    },
                                onChanged: (index) {
                                  final caps = [
                                    StrokeCap.butt,
                                    StrokeCap.round,
                                    StrokeCap.square,
                                  ];
                                  onShapeChanged(
                                    selectedShape!.copyWith(
                                      strokeCap: caps[index],
                                    ),
                                  );
                                },
                                actions: [
                                  M3EToggleButtonGroupAction(
                                    icon: const Icon(
                                      LucideIcons.minus,
                                      size: 14,
                                    ),
                                    label: Text(
                                      'Flat',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Butt / Flat Cap',
                                  ),
                                  M3EToggleButtonGroupAction(
                                    icon: const Icon(
                                      LucideIcons.circle,
                                      size: 12,
                                    ),
                                    label: Text(
                                      'Round',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Round Cap',
                                  ),
                                  M3EToggleButtonGroupAction(
                                    icon: const Icon(
                                      LucideIcons.square,
                                      size: 12,
                                    ),
                                    label: Text(
                                      'Square',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    tooltip: 'Square Cap',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'START & END POINTS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Start Point',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<LineCapStyle>(
                                              value: selectedShape!.startCap,
                                              isExpanded: true,
                                              isDense: true,
                                              icon: const Icon(
                                                LucideIcons.chevronDown,
                                                size: 14,
                                              ),
                                              items: [
                                                DropdownMenuItem(
                                                  value: LineCapStyle.none,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.minus,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'None',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: LineCapStyle.arrow,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.arrowLeft,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'Arrow',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: LineCapStyle.circle,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.circle,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'Circle',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: LineCapStyle.square,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.square,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'Square',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  onShapeChanged(
                                                    selectedShape!.copyWith(
                                                      startCap: val,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'End Point',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<LineCapStyle>(
                                              value: selectedShape!.endCap,
                                              isExpanded: true,
                                              isDense: true,
                                              icon: const Icon(
                                                LucideIcons.chevronDown,
                                                size: 14,
                                              ),
                                              items: [
                                                DropdownMenuItem(
                                                  value: LineCapStyle.none,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.minus,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'None',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: LineCapStyle.arrow,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.arrowRight,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'Arrow',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: LineCapStyle.circle,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.circle,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'Circle',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: LineCapStyle.square,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.square,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'Square',
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  onShapeChanged(
                                                    selectedShape!.copyWith(
                                                      endCap: val,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'CURVE / BEND',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: selectedShape!.isCurved,
                                    activeTrackColor: colorScheme.primary,
                                    onChanged: (val) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      final updated = selectedShape!.copyWith(
                                        isCurved: val,
                                        curvature:
                                            val &&
                                                selectedShape!.curvature == 0.0
                                            ? 30.0
                                            : selectedShape!.curvature,
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ],
                              ),
                              if (selectedShape!.isCurved ||
                                  selectedShape!.curvature != 0.0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.spline, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bend Offset: ${selectedShape!.curvature.round()} px',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          NixSlider(
                                            value: selectedShape!.curvature,
                                            min: -150.0,
                                            max: 150.0,
                                            onChangeStart: (_) => FocusManager
                                                .instance
                                                .primaryFocus
                                                ?.unfocus(),
                                            onChanged: (val) {
                                              onShapeChanged(
                                                selectedShape!.copyWith(
                                                  curvature: val,
                                                  isCurved: val != 0.0,
                                                ),
                                              );
                                            },
                                            onChangeEnd: (val) {
                                              (onShapeChangeEnd ??
                                                  onShapeChanged)(
                                                selectedShape!.copyWith(
                                                  curvature: val,
                                                  isCurved: val != 0.0,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                    // Text properties (If text shape selected)
                    if (selectedShape!.type == ShapeType.text)
                      _buildSectionCard(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TEXT CONTENT',
                              style: _getSectionHeaderStyle(theme),
                            ),
                            const SizedBox(height: 8),
                            _TextContentInputField(
                              key: ValueKey(
                                'text-content-${selectedShape!.id}',
                              ),
                              textContent: selectedShape!.textContent,
                              onChanged: (val) {
                                onShapeChanged(
                                  selectedShape!.copyWith(textContent: val),
                                );
                              },
                              onCommit: () {
                                (onShapeChangeEnd ?? onShapeChanged)(
                                  selectedShape!,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 14),
                            // Typography Header
                            Text(
                              'TYPOGRAPHY',
                              style: _getSectionHeaderStyle(theme),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _FontDropdown(
                                    selectedShape: selectedShape!,
                                    onShapeChanged: onShapeChanged,
                                    onShapeChangeEnd: onShapeChangeEnd,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _FontWeightDropdown(
                                    selectedShape: selectedShape!,
                                    onShapeChanged: onShapeChanged,
                                    onShapeChangeEnd: onShapeChangeEnd,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Font Styles (Bold, Italic, Underline, Strikethrough)
                            Row(
                              children: [
                                Expanded(
                                  child: Tooltip(
                                    message: 'Bold',
                                    child: M3EButton(
                                      onPressed: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        final isNowBold =
                                            !selectedShape!.isBold;
                                        final updated = selectedShape!.copyWith(
                                          isBold: isNowBold,
                                          fontWeight: isNowBold
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        );
                                        onShapeChanged(updated);
                                        onShapeChangeEnd?.call(updated);
                                      },
                                      style: selectedShape!.isBold
                                          ? M3EButtonStyle.filled
                                          : M3EButtonStyle.tonal,
                                      size: M3EButtonSize.sm,
                                      child: const Icon(
                                        RemixIcons.bold,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Tooltip(
                                    message: 'Italic',
                                    child: M3EButton(
                                      onPressed: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        final updated = selectedShape!.copyWith(
                                          isItalic: !selectedShape!.isItalic,
                                        );
                                        onShapeChanged(updated);
                                        onShapeChangeEnd?.call(updated);
                                      },
                                      style: selectedShape!.isItalic
                                          ? M3EButtonStyle.filled
                                          : M3EButtonStyle.tonal,
                                      size: M3EButtonSize.sm,
                                      child: const Icon(
                                        RemixIcons.italic,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Tooltip(
                                    message: 'Underline',
                                    child: M3EButton(
                                      onPressed: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        final updated = selectedShape!.copyWith(
                                          isUnderline:
                                              !selectedShape!.isUnderline,
                                        );
                                        onShapeChanged(updated);
                                        onShapeChangeEnd?.call(updated);
                                      },
                                      style: selectedShape!.isUnderline
                                          ? M3EButtonStyle.filled
                                          : M3EButtonStyle.tonal,
                                      size: M3EButtonSize.sm,
                                      child: const Icon(
                                        RemixIcons.underline,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Tooltip(
                                    message: 'Strikethrough',
                                    child: M3EButton(
                                      onPressed: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        final updated = selectedShape!.copyWith(
                                          isStrikethrough:
                                              !selectedShape!.isStrikethrough,
                                        );
                                        onShapeChanged(updated);
                                        onShapeChangeEnd?.call(updated);
                                      },
                                      style: selectedShape!.isStrikethrough
                                          ? M3EButtonStyle.filled
                                          : M3EButtonStyle.tonal,
                                      size: M3EButtonSize.sm,
                                      child: const Icon(
                                        RemixIcons.strikethrough,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Horizontal Text Alignment
                            Text(
                              'TEXT ALIGNMENT',
                              style: _getSectionHeaderStyle(theme),
                            ),
                            const SizedBox(height: 8),
                            _buildToggleGroup(
                              selectedIndex: switch (selectedShape!.textAlign) {
                                TextAlign.left => 0,
                                TextAlign.center => 1,
                                TextAlign.right => 2,
                                TextAlign.justify => 3,
                                _ => 0,
                              },
                              onChanged: (index) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                const aligns = [
                                  TextAlign.left,
                                  TextAlign.center,
                                  TextAlign.right,
                                  TextAlign.justify,
                                ];
                                final updated = selectedShape!.copyWith(
                                  textAlign: aligns[index],
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
                              actions: const [
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.align_left, size: 16),
                                  tooltip: 'Text Align Left',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.align_center, size: 16),
                                  tooltip: 'Text Align Center',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.align_right, size: 16),
                                  tooltip: 'Text Align Right',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(
                                    RemixIcons.align_justify,
                                    size: 16,
                                  ),
                                  tooltip: 'Text Justify',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Vertical Text Alignment
                            Text(
                              'VERTICAL ALIGNMENT',
                              style: _getSectionHeaderStyle(theme),
                            ),
                            const SizedBox(height: 8),
                            _buildToggleGroup(
                              selectedIndex:
                                  switch (selectedShape!.textVerticalAlign) {
                                    TextVerticalAlign.top => 0,
                                    TextVerticalAlign.center => 1,
                                    TextVerticalAlign.bottom => 2,
                                  },
                              onChanged: (index) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                const aligns = [
                                  TextVerticalAlign.top,
                                  TextVerticalAlign.center,
                                  TextVerticalAlign.bottom,
                                ];
                                final updated = selectedShape!.copyWith(
                                  textVerticalAlign: aligns[index],
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
                              actions: const [
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.align_top, size: 16),
                                  tooltip: 'Text Align Top',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(
                                    RemixIcons.align_vertically,
                                    size: 16,
                                  ),
                                  tooltip: 'Text Align Middle',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.align_bottom, size: 16),
                                  tooltip: 'Text Align Bottom',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Text Case Transformation
                            Text(
                              'TEXT CASE',
                              style: _getSectionHeaderStyle(theme),
                            ),
                            const SizedBox(height: 8),
                            _buildToggleGroup(
                              selectedIndex: switch (selectedShape!.textCase) {
                                TextCase.original => 0,
                                TextCase.uppercase => 1,
                                TextCase.lowercase => 2,
                                TextCase.titleCase => 3,
                              },
                              onChanged: (index) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                const cases = [
                                  TextCase.original,
                                  TextCase.uppercase,
                                  TextCase.lowercase,
                                  TextCase.titleCase,
                                ];
                                final updated = selectedShape!.copyWith(
                                  textCase: cases[index],
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
                              actions: [
                                M3EToggleButtonGroupAction(
                                  label: Text(
                                    'Aa',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  tooltip: 'As Typed',
                                ),
                                M3EToggleButtonGroupAction(
                                  label: Text(
                                    'AA',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  tooltip: 'UPPERCASE',
                                ),
                                M3EToggleButtonGroupAction(
                                  label: Text(
                                    'aa',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  tooltip: 'lowercase',
                                ),
                                M3EToggleButtonGroupAction(
                                  label: Text(
                                    'Ab',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  tooltip: 'Title Case',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Font Size
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Font Size: ${selectedShape!.fontSize.round()} px',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 64,
                                  child: _buildNumberField(
                                    context,
                                    'px',
                                    selectedShape!.fontSize,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        fontSize: val.clamp(8, 200),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            NixSlider(
                              value: selectedShape!.fontSize.clamp(8.0, 144.0),
                              min: 8.0,
                              max: 144.0,
                              onChangeStart: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              onChanged: (val) {
                                onShapeChanged(
                                  selectedShape!.copyWith(fontSize: val),
                                );
                              },
                              onChangeEnd: (val) {
                                (onShapeChangeEnd ?? onShapeChanged)(
                                  selectedShape!.copyWith(fontSize: val),
                                );
                              },
                            ),

                            const SizedBox(height: 12),
                            // Letter Spacing (Tracking)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Letter Spacing: ${selectedShape!.letterSpacing.toStringAsFixed(1)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 64,
                                  child: _buildNumberField(
                                    context,
                                    'sp',
                                    selectedShape!.letterSpacing,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        letterSpacing: val.clamp(-4, 30),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            NixSlider(
                              value: selectedShape!.letterSpacing.clamp(
                                -2.0,
                                20.0,
                              ),
                              min: -2.0,
                              max: 20.0,
                              onChangeStart: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              onChanged: (val) {
                                onShapeChanged(
                                  selectedShape!.copyWith(letterSpacing: val),
                                );
                              },
                              onChangeEnd: (val) {
                                (onShapeChangeEnd ?? onShapeChanged)(
                                  selectedShape!.copyWith(letterSpacing: val),
                                );
                              },
                            ),

                            const SizedBox(height: 12),
                            // Line Height (Leading)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Line Height: ${selectedShape!.lineHeight.toStringAsFixed(2)}x',
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 64,
                                  child: _buildNumberField(
                                    context,
                                    'lh',
                                    selectedShape!.lineHeight,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        lineHeight: val.clamp(0.5, 3.5),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            NixSlider(
                              value: selectedShape!.lineHeight.clamp(0.8, 3.0),
                              min: 0.8,
                              max: 3.0,
                              onChangeStart: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              onChanged: (val) {
                                onShapeChanged(
                                  selectedShape!.copyWith(lineHeight: val),
                                );
                              },
                              onChangeEnd: (val) {
                                (onShapeChangeEnd ?? onShapeChanged)(
                                  selectedShape!.copyWith(lineHeight: val),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    // Section: Export Selection (Figma-Exact Inspector Section)
                    _buildSectionCard(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'EXPORT',
                                style: _getSectionHeaderStyle(theme),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SVG',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                _getShapeIcon(selectedShape!.type),
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  selectedShape!.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '${selectedShape!.rect.width.round()} × ${selectedShape!.rect.height.round()} px',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: M3EButton.icon(
                              onPressed: onExportSvg,
                              style: M3EButtonStyle.tonal,
                              size: M3EButtonSize.sm,
                              icon: Icon(
                                RemixIcons.download_2_line,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              label: Text(
                                'Export SVG (${selectedShape!.name})',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(padding: padding, child: child),
    );
  }

  TextStyle _getSectionHeaderStyle(ThemeData theme) {
    return theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ) ??
        const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2);
  }

  Widget _buildToggleGroup({
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    required List<M3EToggleButtonGroupAction> actions,
    M3EButtonStyle style = M3EButtonStyle.filled,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final count = actions.length;
        final totalGaps = (count - 1) * 2.0;
        final itemWidth = ((constraints.maxWidth - totalGaps) / count)
            .floorToDouble();
        final size = M3EButtonSize.fromBase(
          M3EButtonSize.xs,
          hPadding: 2,
          width: itemWidth,
        );

        final groupDecoration = M3EToggleButtonDecoration(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            if (states.contains(WidgetState.hovered)) {
              return isDark
                  ? colorScheme.surfaceContainerHighest
                  : colorScheme.surfaceContainer;
            }
            return isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLow;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onSurfaceVariant;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(color: colorScheme.primary, width: 1);
            }
            return BorderSide(
              color: colorScheme.outlineVariant.withValues(
                alpha: isDark ? 0.4 : 0.25,
              ),
              width: 1,
            );
          }),
        );

        final mappedActions = actions.asMap().entries.map((entry) {
          final action = entry.value;

          Widget? uncheckedLabel = action.label;
          Widget? checkedLabel = action.checkedLabel;
          if (uncheckedLabel is Text) {
            final textStr = uncheckedLabel.data ?? '';
            final originalStyle = uncheckedLabel.style ??
                theme.textTheme.labelSmall ??
                const TextStyle();
            uncheckedLabel = Text(
              textStr,
              style: originalStyle.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            );
            checkedLabel ??= Text(
              textStr,
              style: originalStyle.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            );
          }

          Widget? uncheckedIcon = action.icon;
          Widget? checkedIcon = action.checkedIcon;
          if (uncheckedIcon is Icon) {
            checkedIcon ??= Icon(
              uncheckedIcon.icon,
              size: uncheckedIcon.size ?? 16,
              color: colorScheme.onPrimary,
            );
            uncheckedIcon = Icon(
              uncheckedIcon.icon,
              size: uncheckedIcon.size ?? 16,
              color: colorScheme.onSurfaceVariant,
            );
          }

          return M3EToggleButtonGroupAction(
            icon: uncheckedIcon,
            checkedIcon: checkedIcon,
            label: uncheckedLabel,
            checkedLabel: checkedLabel,
            checked: action.checked,
            enabled: action.enabled,
            decoration: action.decoration ?? groupDecoration,
            width: action.width,
            focusNode: action.focusNode,
            autofocus: action.autofocus,
            onFocusChange: action.onFocusChange,
            semanticLabel: action.semanticLabel,
            tooltip: action.tooltip,
            enableFeedback: action.enableFeedback,
          );
        }).toList();

        return M3EToggleButtonGroup(
          type: M3EButtonGroupType.connected,
          style: style,
          size: size,
          shape: M3EButtonShape.round,
          density: M3EButtonGroupDensity.compact,
          overflow: M3EButtonGroupOverflow.none,
          selectedIndex: selectedIndex,
          decoration: groupDecoration,
          onSelectedIndexChanged: (idx) {
            if (idx != null) {
              onChanged(idx);
            }
          },
          actions: mappedActions,
        );
      },
    );
  }

  Widget _buildNumberField(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged, {
    VoidCallback? onEditingComplete,
    double? min,
    double? max,
    double? step,
    bool? isInteger,
  }) {
    return _NumberInputField(
      key: ValueKey('$label-${selectedShape?.id}'),
      label: label,
      value: value,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      min: min,
      max: max,
      step: step,
      isInteger: isInteger,
    );
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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

  Widget _buildCanvasProperties(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final effectiveBg =
        canvasBackgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : colorScheme.surface);
    final opacityPct = (effectiveBg.a * 100).round();

    final canvasPresets = [
      const Color(0xFF121212), // Pure Dark
      const Color(0xFF1E1E1E), // Figma Dark
      const Color(0xFF0F172A), // Slate Navy
      const Color(0xFF262626), // Neutral Charcoal
      const Color(0xFFE2E8F0), // Cool Gray
      const Color(0xFFF8FAFC), // Pure Off-White
      const Color(0xFFFFFFFF), // Crisp White
    ];

    return ListView(
      key: const ValueKey('properties-sidebar-canvas-inspector'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        // Header M3 & Quick Actions
        _buildSectionCard(
          context,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  RemixIcons.artboard_line,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PAGE / CANVAS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      totalShapesCount == 1
                          ? '1 layer'
                          : '$totalShapesCount layers',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onSelectAll != null)
                M3EButton(
                  onPressed: totalShapesCount > 0 ? onSelectAll : null,
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.sm,
                  tooltip: totalShapesCount > 0
                      ? 'Select All (Ctrl+A)'
                      : 'No layers to select',
                  child: Icon(
                    RemixIcons.checkbox_multiple_line,
                    size: 16,
                    color: totalShapesCount > 0
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
            ],
          ),
        ),

        // Section: Navigation & Tools
        _buildSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOOL & NAVIGATION', style: _getSectionHeaderStyle(theme)),
              const SizedBox(height: 10),

              M3ESegmentedRow(
                onTap: (index) {
                  if (index == 0 && isPanMode) {
                    onTogglePanMode?.call();
                  } else if (index == 1 && !isPanMode) {
                    onTogglePanMode?.call();
                  }
                },
                equalWidth: true,
                gap: 2.0,
                decoration: M3ESegmentedListDecoration(
                  outerRadius: 10.0,
                  innerRadius: 4.0,
                  gap: 2.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  color: colorScheme.surfaceContainerHigh,
                  hoverColor: colorScheme.surfaceContainerHighest,
                  pressedRadius: 8.0,
                  pressedScale: 1.0,
                ),
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.cursor_line,
                          size: 14,
                          color: !isPanMode
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Select (V)',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: !isPanMode
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: !isPanMode
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.hand,
                          size: 14,
                          color: isPanMode
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Move (H)',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isPanMode
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isPanMode
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: M3EButton(
                      onPressed: onCenterCanvas,
                      style: M3EButtonStyle.tonal,
                      size: M3EButtonSize.sm,
                      tooltip: 'Center Canvas in Viewport',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(RemixIcons.focus_3_line, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Center',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: M3EButton(
                      onPressed: onZoomToFit,
                      style: M3EButtonStyle.tonal,
                      size: M3EButtonSize.sm,
                      tooltip: 'Zoom to Fit (Shift+1)',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(RemixIcons.aspect_ratio_line, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Fit',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Section: Zoom Controls
        _buildSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ZOOM CONTROLS', style: _getSectionHeaderStyle(theme)),
              const SizedBox(height: 10),

              // Zoom Out | % Pill | Zoom In
              Row(
                children: [
                  M3EButton(
                    onPressed: onZoomOut,
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    tooltip: 'Zoom Out (Ctrl+-)',
                    child: Icon(
                      RemixIcons.subtract_line,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: 'Reset to 100% (Ctrl+0)',
                      child: InkWell(
                        onTap: onResetZoom,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${(zoomScale * 100).round()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  M3EButton(
                    onPressed: onZoomIn,
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    tooltip: 'Zoom In (Ctrl++)',
                    child: Icon(
                      RemixIcons.add_line,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Presets: 50%, 100%, 200%, Fit
              M3ESegmentedRow(
                onTap: (index) {
                  switch (index) {
                    case 0:
                      onSetZoomScale?.call(0.5);
                      break;
                    case 1:
                      onResetZoom?.call();
                      break;
                    case 2:
                      onSetZoomScale?.call(2.0);
                      break;
                    case 3:
                      onZoomToFit?.call();
                      break;
                  }
                },
                equalWidth: true,
                gap: 2.0,
                decoration: M3ESegmentedListDecoration(
                  outerRadius: 10.0,
                  innerRadius: 4.0,
                  gap: 2.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  color: colorScheme.surfaceContainerHigh,
                  hoverColor: colorScheme.surfaceContainerHighest,
                ),
                children: [
                  Center(
                    child: Text(
                      '50%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: (zoomScale - 0.5).abs() < 0.05
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (zoomScale - 0.5).abs() < 0.05
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '100%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: (zoomScale - 1.0).abs() < 0.05
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (zoomScale - 1.0).abs() < 0.05
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '200%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: (zoomScale - 2.0).abs() < 0.05
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (zoomScale - 2.0).abs() < 0.05
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Fit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Interactive Zoom Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zoom Range',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(zoomScale * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              NixSlider(
                value: zoomScale.clamp(0.25, 4.0),
                min: 0.25,
                max: 4.0,
                onChanged: onSetZoomScale,
              ),
            ],
          ),
        ),

        // Section: Canvas Background
        _buildSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CANVAS BACKGROUND', style: _getSectionHeaderStyle(theme)),
              const SizedBox(height: 10),

              // Color Chip + Hex Field + Opacity
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTapUp: (details) {
                        showNixColorPicker(
                          context: context,
                          initialColor: effectiveBg,
                          title: 'Canvas Background',
                          anchorRect: Rect.fromCenter(
                            center: details.globalPosition,
                            width: 28,
                            height: 28,
                          ),
                          onColorChanged: (col) {
                            onCanvasBackgroundColorChanged?.call(col);
                          },
                        );
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: effectiveBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CanvasHexInputField(
                        effectiveBg: effectiveBg,
                        onColorChanged: onCanvasBackgroundColorChanged,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$opacityPct%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Quick Preset Swatches (No glow)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: canvasPresets.map((preset) {
                  final isSelected =
                      (effectiveBg.toARGB32() & 0x00FFFFFF) ==
                      (preset.toARGB32() & 0x00FFFFFF);
                  return GestureDetector(
                    onTap: () => onCanvasBackgroundColorChanged?.call(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: preset,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Section: Grid & Snapping
        _buildSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GRID & SNAPPING', style: _getSectionHeaderStyle(theme)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Snap to Grid',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: snapToGrid ?? true,
                    onChanged: onToggleSnapToGrid,
                  ),
                ],
              ),

              if (gridSpacing != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Spacing: ${gridSpacing!.round()} px',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 6),
                _buildToggleGroup(
                  selectedIndex: switch (gridSpacing!.round()) {
                    10 => 0,
                    20 => 1,
                    40 => 2,
                    80 => 3,
                    _ => 2,
                  },
                  onChanged: (idx) {
                    final spacings = [10.0, 20.0, 40.0, 80.0];
                    onGridSpacingChanged?.call(spacings[idx]);
                  },
                  actions: [
                    M3EToggleButtonGroupAction(
                      label: Text('10', style: theme.textTheme.labelSmall),
                      tooltip: '10px Grid',
                    ),
                    M3EToggleButtonGroupAction(
                      label: Text('20', style: theme.textTheme.labelSmall),
                      tooltip: '20px Grid',
                    ),
                    M3EToggleButtonGroupAction(
                      label: Text('40', style: theme.textTheme.labelSmall),
                      tooltip: '40px Grid',
                    ),
                    M3EToggleButtonGroupAction(
                      label: Text('80', style: theme.textTheme.labelSmall),
                      tooltip: '80px Grid',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Section: Artboard Dimensions (Figma Style)
        _buildSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ARTBOARD DIMENSIONS', style: _getSectionHeaderStyle(theme)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _NumberInputField(
                      key: const ValueKey('canvas-w'),
                      label: 'W',
                      value: canvasSize?.width ?? 3200,
                      min: 100.0,
                      max: 10000.0,
                      isInteger: true,
                      onChanged: (newW) {
                        final curH = canvasSize?.height ?? 2400.0;
                        onCanvasSizeChanged?.call(
                          Size(newW.clamp(100.0, 10000.0), curH),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberInputField(
                      key: const ValueKey('canvas-h'),
                      label: 'H',
                      value: canvasSize?.height ?? 2400,
                      min: 100.0,
                      max: 10000.0,
                      isInteger: true,
                      onChanged: (newH) {
                        final curW = canvasSize?.width ?? 3200.0;
                        onCanvasSizeChanged?.call(
                          Size(curW, newH.clamp(100.0, 10000.0)),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildArtboardPresetChip(
                    label: '3200 × 2400',
                    size: const Size(3200, 2400),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  _buildArtboardPresetChip(
                    label: '1920 × 1080',
                    size: const Size(1920, 1080),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  _buildArtboardPresetChip(
                    label: '1440 × 900',
                    size: const Size(1440, 900),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  _buildArtboardPresetChip(
                    label: '512 × 512',
                    size: const Size(512, 512),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  _buildArtboardPresetChip(
                    label: '390 × 844',
                    size: const Size(390, 844),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Section: Export Canvas (Figma-Exact Inspector Section)
        _buildSectionCard(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('EXPORT CANVAS', style: _getSectionHeaderStyle(theme)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SVG',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    RemixIcons.artboard_line,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Entire Canvas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${(canvasSize?.width ?? 3200).round()} × ${(canvasSize?.height ?? 2400).round()} px',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: M3EButton.icon(
                  onPressed: onExportSvg,
                  style: M3EButtonStyle.tonal,
                  size: M3EButtonSize.sm,
                  icon: Icon(
                    RemixIcons.download_2_line,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Export Canvas SVG',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtboardPresetChip({
    required String label,
    required Size size,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final cur = canvasSize ?? const Size(3200, 2400);
    final isSelected =
        (cur.width - size.width).abs() < 1 &&
        (cur.height - size.height).abs() < 1;
    return InkWell(
      onTap: () => onCanvasSizeChanged?.call(size),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Editable Hex input field for canvas background color
class _CanvasHexInputField extends StatefulWidget {
  final Color effectiveBg;
  final ValueChanged<Color>? onColorChanged;

  const _CanvasHexInputField({
    required this.effectiveBg,
    required this.onColorChanged,
  });

  @override
  State<_CanvasHexInputField> createState() => _CanvasHexInputFieldState();
}

class _CanvasHexInputFieldState extends State<_CanvasHexInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatHex(widget.effectiveBg));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitHex(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CanvasHexInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        (oldWidget.effectiveBg.toARGB32() & 0x00FFFFFF) !=
            (widget.effectiveBg.toARGB32() & 0x00FFFFFF)) {
      _controller.text = _formatHex(widget.effectiveBg);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatHex(Color col) {
    return col
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  void _commitHex(String text) {
    var raw = text.trim().replaceAll('#', '');
    if (raw.length == 3) {
      raw = raw.split('').map((c) => '$c$c').join();
    }
    if (raw.length == 6) {
      final value = int.tryParse(raw, radix: 16);
      if (value != null) {
        final newColor = Color(0xFF000000 | value);
        widget.onColorChanged?.call(newColor);
        return;
      }
    } else if (raw.length == 8) {
      final value = int.tryParse(raw, radix: 16);
      if (value != null) {
        final newColor = Color(value);
        widget.onColorChanged?.call(newColor);
        return;
      }
    }
    _controller.text = _formatHex(widget.effectiveBg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '#',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            key: const ValueKey('canvas-hex-input-field'),
            controller: _controller,
            focusNode: _focusNode,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(8),
            ],
            onSubmitted: _commitHex,
          ),
        ),
      ],
    );
  }
}

class _FontDropdown extends StatelessWidget {
  final VectorShape selectedShape;
  final ValueChanged<VectorShape> onShapeChanged;
  final ValueChanged<VectorShape>? onShapeChangeEnd;

  const _FontDropdown({
    required this.selectedShape,
    required this.onShapeChanged,
    this.onShapeChangeEnd,
  });

  static const List<String> _allFonts = [
    'Inter',
    'Roboto',
    'Google Sans',
    'Outfit',
    'Poppins',
    'Montserrat',
    'Open Sans',
    'Lato',
    'Oswald',
    'Fira Code',
    'Playfair Display',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          initialSelection: selectedShape.fontFamily,
          enableSearch: true,
          enableFilter: true,
          requestFocusOnTap: false,
          textStyle: Theme.of(context).textTheme.bodyMedium,
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownMenuEntries: _allFonts.map((font) {
            return DropdownMenuEntry<String>(value: font, label: font);
          }).toList(),
          onSelected: (newValue) {
            FocusManager.instance.primaryFocus?.unfocus();
            if (newValue != null && newValue != selectedShape.fontFamily) {
              final updated = selectedShape.copyWith(fontFamily: newValue);
              onShapeChanged(updated);
              onShapeChangeEnd?.call(updated);
            }
          },
        );
      },
    );
  }
}

class _FontWeightDropdown extends StatelessWidget {
  final VectorShape selectedShape;
  final ValueChanged<VectorShape> onShapeChanged;
  final ValueChanged<VectorShape>? onShapeChangeEnd;

  const _FontWeightDropdown({
    required this.selectedShape,
    required this.onShapeChanged,
    this.onShapeChangeEnd,
  });

  static const _weights = [
    (FontWeight.w400, 'Regular'),
    (FontWeight.w500, 'Medium'),
    (FontWeight.w600, 'SemiBold'),
    (FontWeight.w700, 'Bold'),
    (FontWeight.w800, 'ExtraBold'),
    (FontWeight.w900, 'Black'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<FontWeight>(
          width: constraints.maxWidth,
          initialSelection: selectedShape.fontWeight,
          requestFocusOnTap: false,
          textStyle: Theme.of(context).textTheme.bodyMedium,
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
          dropdownMenuEntries: _weights.map((entry) {
            return DropdownMenuEntry<FontWeight>(
              value: entry.$1,
              label: entry.$2,
            );
          }).toList(),
          onSelected: (newValue) {
            FocusManager.instance.primaryFocus?.unfocus();
            if (newValue != null && newValue != selectedShape.fontWeight) {
              final isBold = newValue.value >= FontWeight.w700.value;
              final updated = selectedShape.copyWith(
                fontWeight: newValue,
                isBold: isBold,
              );
              onShapeChanged(updated);
              onShapeChangeEnd?.call(updated);
            }
          },
        );
      },
    );
  }
}

/// Production-grade Material 3 Expressive Number Input Field with Figma-like Scrubbing.
/// Supports clicking to edit, Up/Down arrow nudge (Shift for 10x), Escape cancel,
/// and pressing & holding/dragging horizontally on the label ('left is less, right is more')
/// with Shift (10x fast scrub), Alt (0.1x fine scrub), and haptic tick feedback.
class _NumberInputField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback? onEditingComplete;
  final double? min;
  final double? max;
  final double? step;
  final bool? isInteger;

  const _NumberInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onEditingComplete,
    this.min,
    this.max,
    this.step,
    this.isInteger,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isScrubbing = false;
  bool _isHovered = false;
  double _scrubBaseValue = 0.0;
  double _scrubAccumulatedDelta = 0.0;
  int _lastHapticTick = 0;

  double get _effectiveMin {
    if (widget.min != null) return widget.min!;
    if (widget.label == 'PTS') return 3.0;
    if (widget.label == '%') return 5.0;
    if (widget.label == 'W' || widget.label == 'H') return 1.0;
    if (widget.label == 'R' ||
        widget.label == 'TL' ||
        widget.label == 'TR' ||
        widget.label == 'BL' ||
        widget.label == 'BR') {
      return 0.0;
    }
    if (widget.label == 'px') return 8.0;
    if (widget.label == 'sp') return -4.0;
    if (widget.label == 'lh') return 0.5;
    return -99999.0;
  }

  double get _effectiveMax {
    if (widget.max != null) return widget.max!;
    if (widget.label == 'PTS') return 60.0;
    if (widget.label == '%') return 95.0;
    if (widget.label == 'R' ||
        widget.label == 'TL' ||
        widget.label == 'TR' ||
        widget.label == 'BL' ||
        widget.label == 'BR') {
      return 500.0;
    }
    if (widget.label == 'px') return 200.0;
    if (widget.label == 'sp') return 30.0;
    if (widget.label == 'lh') return 3.5;
    return 99999.0;
  }

  double get _dragSensitivity {
    if (widget.step != null) return widget.step!;
    if (widget.label == 'PTS') return 0.4;
    if (widget.label == '%') return 0.5;
    if (widget.label == 'lh') return 0.01;
    if (widget.label == 'sp') return 0.1;
    return 1.0;
  }

  String _formatValue(double val) {
    if (widget.label == 'lh') {
      return val.toStringAsFixed(2);
    }
    if (widget.label == 'sp') {
      return (val == val.roundToDouble())
          ? val.round().toString()
          : val.toStringAsFixed(1);
    }
    if (widget.isInteger == false) {
      return (val == val.roundToDouble())
          ? val.round().toString()
          : val.toStringAsFixed(1);
    }
    return val.round().toString();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _commit();
    }
  }

  void _commit() {
    final double? parsed = double.tryParse(_controller.text.trim());
    if (parsed != null && parsed != widget.value) {
      final clamped = parsed.clamp(_effectiveMin, _effectiveMax);
      widget.onChanged(clamped);
      _controller.text = _formatValue(clamped);
    } else {
      _controller.text = _formatValue(widget.value);
    }
    widget.onEditingComplete?.call();
  }

  @override
  void didUpdateWidget(covariant _NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && !_isScrubbing) {
      final currentParsed = double.tryParse(_controller.text.trim());
      if (currentParsed != widget.value) {
        _controller.text = _formatValue(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _focusNode.unfocus();
    setState(() {
      _isScrubbing = true;
    });
    _scrubBaseValue = double.tryParse(_controller.text.trim()) ?? widget.value;
    _scrubAccumulatedDelta = 0.0;
    _lastHapticTick = _scrubBaseValue.round();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dx = details.primaryDelta ?? details.delta.dx;
    if (dx == 0) return;

    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final multiplier = isShift ? 10.0 : (isAlt ? 0.1 : 1.0);

    _scrubAccumulatedDelta += dx * _dragSensitivity * multiplier;

    final rawValue = _scrubBaseValue + _scrubAccumulatedDelta;
    final clamped = rawValue.clamp(_effectiveMin, _effectiveMax);

    final double nextValue;
    if (widget.label == '°') {
      nextValue = ((clamped % 360) + 360) % 360;
    } else if (widget.label == 'lh') {
      nextValue = (clamped * 100).round() / 100.0;
    } else if (widget.isInteger ??
        (widget.label == 'PTS' ||
            widget.label == '%' ||
            widget.label == 'R' ||
            widget.label == 'TL' ||
            widget.label == 'TR' ||
            widget.label == 'BL' ||
            widget.label == 'BR' ||
            !isAlt)) {
      nextValue = clamped.roundToDouble();
    } else {
      nextValue = (clamped * 10).round() / 10.0;
    }

    final formatted = _formatValue(nextValue);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }

    final currentInt = nextValue.round();
    if (currentInt != _lastHapticTick) {
      _lastHapticTick = currentInt;
      HapticFeedback.selectionClick();
    }

    if (nextValue != widget.value) {
      widget.onChanged(nextValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isScrubbing = false;
    });
    widget.onEditingComplete?.call();
  }

  void _handleDragCancel() {
    setState(() {
      _isScrubbing = false;
    });
    widget.onEditingComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isScrubbing
              ? colorScheme.primary
              : (_focusNode.hasFocus
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.4)),
          width: (_focusNode.hasFocus || _isScrubbing) ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message:
                'Drag left/right to adjust (${widget.label})\nShift for 10x, Alt for 0.1x',
            waitDuration: const Duration(milliseconds: 650),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _focusNode.requestFocus();
                  _controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _controller.text.length,
                  );
                },
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                onHorizontalDragCancel: _handleDragCancel,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isScrubbing
                        ? colorScheme.primary.withValues(alpha: 0.22)
                        : (_isHovered
                              ? colorScheme.primary.withValues(alpha: 0.10)
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isScrubbing
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : (_isHovered
                                ? colorScheme.primary.withValues(alpha: 0.25)
                                : Colors.transparent),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _isScrubbing
                          ? colorScheme.primary
                          : (_isHovered
                                ? colorScheme.primary
                                : colorScheme.primary.withValues(alpha: 0.85)),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    final double cur =
                        double.tryParse(_controller.text.trim()) ??
                        widget.value;
                    final step = HardwareKeyboard.instance.isShiftPressed
                        ? 10.0
                        : 1.0;
                    final next = (cur + step).clamp(
                      _effectiveMin,
                      _effectiveMax,
                    );
                    _controller.text = _formatValue(next);
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                    widget.onChanged(next);
                    widget.onEditingComplete?.call();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    final double cur =
                        double.tryParse(_controller.text.trim()) ??
                        widget.value;
                    final step = HardwareKeyboard.instance.isShiftPressed
                        ? 10.0
                        : 1.0;
                    final next = (cur - step).clamp(
                      _effectiveMin,
                      _effectiveMax,
                    );
                    _controller.text = _formatValue(next);
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                    widget.onChanged(next);
                    widget.onEditingComplete?.call();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _controller.text = _formatValue(widget.value);
                    _focusNode.unfocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onFieldSubmitted: (text) {
                  _commit();
                  _focusNode.unfocus();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone scrubbable label for property sliders (e.g. Ratio, Width, Opacity).
/// Dragging left decreases the value, dragging right increases the value.
class _ScrubbableLabel extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback? onEditingComplete;
  final double min;
  final double max;

  const _ScrubbableLabel({
    required this.label,
    required this.value,
    required this.onChanged,
    this.onEditingComplete,
    this.min = 0.0,
    this.max = 100.0,
  });

  @override
  State<_ScrubbableLabel> createState() => _ScrubbableLabelState();
}

class _ScrubbableLabelState extends State<_ScrubbableLabel> {
  bool _isHovered = false;
  bool _isScrubbing = false;
  double _scrubBaseValue = 0.0;
  double _scrubAccumulatedDelta = 0.0;
  int _lastHapticTick = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Tooltip(
      message: 'Drag left/right to adjust (${widget.label})',
      waitDuration: const Duration(milliseconds: 650),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() {
              _isScrubbing = true;
            });
            _scrubBaseValue = widget.value;
            _scrubAccumulatedDelta = 0.0;
            _lastHapticTick = _scrubBaseValue.round();
          },
          onHorizontalDragUpdate: (details) {
            final dx = details.primaryDelta ?? details.delta.dx;
            if (dx == 0) return;
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            final isAlt = HardwareKeyboard.instance.isAltPressed;
            final multiplier = isShift ? 10.0 : (isAlt ? 0.1 : 1.0);

            _scrubAccumulatedDelta += dx * 0.5 * multiplier;
            final rawValue = _scrubBaseValue + _scrubAccumulatedDelta;
            final clamped = rawValue.clamp(widget.min, widget.max);
            final nextValue = (isAlt
                ? (clamped * 10).round() / 10.0
                : clamped.roundToDouble());

            final currentInt = nextValue.round();
            if (currentInt != _lastHapticTick) {
              _lastHapticTick = currentInt;
              HapticFeedback.selectionClick();
            }

            if (nextValue != widget.value) {
              widget.onChanged(nextValue);
            }
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              _isScrubbing = false;
            });
            widget.onEditingComplete?.call();
          },
          onHorizontalDragCancel: () {
            setState(() {
              _isScrubbing = false;
            });
            widget.onEditingComplete?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _isScrubbing
                  ? colorScheme.primary.withValues(alpha: 0.22)
                  : (_isHovered
                        ? colorScheme.primary.withValues(alpha: 0.10)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isScrubbing
                    ? colorScheme.primary.withValues(alpha: 0.6)
                    : (_isHovered
                          ? colorScheme.primary.withValues(alpha: 0.25)
                          : Colors.transparent),
                width: 1,
              ),
            ),
            child: Text(
              widget.label,
              style: defaultStyle?.copyWith(
                color: _isScrubbing
                    ? colorScheme.primary
                    : (_isHovered ? colorScheme.primary : null),
                fontWeight: (_isScrubbing || _isHovered)
                    ? FontWeight.bold
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Production-grade Material 3 Expressive Text Content Input Field.
/// Allows live typography changes on the canvas while properly releasing
/// focus on Enter, blur, or Escape, preventing frozen canvas state.
class _TextContentInputField extends StatefulWidget {
  final String textContent;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCommit;

  const _TextContentInputField({
    super.key,
    required this.textContent,
    required this.onChanged,
    this.onCommit,
  });

  @override
  State<_TextContentInputField> createState() => _TextContentInputFieldState();
}

class _TextContentInputFieldState extends State<_TextContentInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.textContent);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (!_focusNode.hasFocus) {
      widget.onCommit?.call();
    }
  }

  @override
  void didUpdateWidget(covariant _TextContentInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _controller.text != widget.textContent) {
      _controller.text = widget.textContent;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _focusNode.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.done,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
        onChanged: widget.onChanged,
        onFieldSubmitted: (_) {
          widget.onCommit?.call();
          _focusNode.unfocus();
        },
      ),
    );
  }
}
