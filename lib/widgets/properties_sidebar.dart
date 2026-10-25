import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:m3e_buttons/m3e_buttons.dart' hide M3EHapticFeedback, M3EMotion;
import 'package:m3e_dropdown_menu/m3e_dropdown_menu.dart';
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
  final Function(String direction)? onDistributeShapes;
  final Function(PathOperation op)? onBooleanOperation;
  final int selectedShapesCount;
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
    this.onDistributeShapes,
    this.onBooleanOperation,
    this.selectedShapesCount = 1,
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
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              if (selectedShape!.groupName != null) ...[
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 90,
                                  ),
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
                          _buildHeaderActionButtons(context),
                        ],
                      ),
                    ),

                    // Layout Section (Alignment, Boolean Groups, Transform)
                    _CollapsibleSection(
                      title: 'Layout',
                      icon: RemixIcons.layout_masonry_line,
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
                              innerRadius: 8.0,
                              gap: 1.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              hoverColor: colorScheme.surfaceContainerHighest,
                              pressedRadius: 8.0,
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
                              innerRadius: 8.0,
                              gap: 1.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              hoverColor: colorScheme.surfaceContainerHighest,
                              pressedRadius: 8.0,
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
                          const SizedBox(height: 4),

                          // Row 3: Distribute Spacing (Horizontal & Vertical)
                          M3ESegmentedRow(
                            onTap: (index) {
                              if (onDistributeShapes != null) {
                                onDistributeShapes!(
                                  index == 0 ? 'horizontal' : 'vertical',
                                );
                              }
                            },
                            equalWidth: true,
                            gap: 1.5,
                            decoration: M3ESegmentedListDecoration(
                              outerRadius: 8.0,
                              innerRadius: 8.0,
                              gap: 1.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              hoverColor: colorScheme.surfaceContainerHighest,
                              pressedRadius: 8.0,
                              pressedScale: 1.0,
                            ),
                            children: [
                              Tooltip(
                                message: 'Distribute Horizontal Spacing (⌥⌘H)',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.space,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Distribute Vertical Spacing (⌥⌘V)',
                                child: Center(
                                  child: Icon(
                                    RemixIcons.line_height,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Boolean Operations Card (Union, Subtract, Intersect, Exclude)
                          if (selectedShapesCount >= 2 &&
                              onBooleanOperation != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'BOOLEAN GROUPS',
                              style: _getSectionHeaderStyle(theme),
                            ),
                            const SizedBox(height: 5),
                            M3ESegmentedRow(
                              onTap: (index) {
                                const ops = [
                                  PathOperation.union,
                                  PathOperation.difference,
                                  PathOperation.intersect,
                                  PathOperation.xor,
                                ];
                                onBooleanOperation!(ops[index]);
                              },
                              equalWidth: true,
                              gap: 1.5,
                              decoration: M3ESegmentedListDecoration(
                                outerRadius: 8.0,
                                innerRadius: 8.0,
                                gap: 1.5,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                color: colorScheme.surfaceContainerHigh,
                                hoverColor: colorScheme.surfaceContainerHighest,
                                pressedRadius: 8.0,
                                pressedScale: 1.0,
                              ),
                              children: [
                                Tooltip(
                                  message: 'Boolean Union (⌥⌘U)',
                                  child: Center(
                                    child: Icon(
                                      RemixIcons.shape_line,
                                      size: 15,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Boolean Subtract (⌥⌘S)',
                                  child: Center(
                                    child: Icon(
                                      RemixIcons.subtract_line,
                                      size: 15,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Boolean Intersect (⌥⌘I)',
                                  child: Center(
                                    child: Icon(
                                      RemixIcons.pie_chart_line,
                                      size: 15,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Boolean Exclude (⌥⌘X)',
                                  child: Center(
                                    child: Icon(
                                      RemixIcons.contrast_line,
                                      size: 15,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            thickness: 0.8,
                            color: colorScheme.outlineVariant.withValues(
                              alpha: isDark ? 0.25 : 0.35,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            'TRANSFORM',
                            style: _getSectionHeaderStyle(theme),
                          ),
                          const SizedBox(height: 6),

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
                          if ((width ?? 280) < 220 &&
                              (selectedShape!.type == ShapeType.rectangle ||
                                  selectedShape!.type ==
                                      ShapeType.roundedRectangle ||
                                  selectedShape!.type == ShapeType.image)) ...[
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
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
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
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: selectedShape!.hasIndependentCorners
                                      ? 'Link Corner Radii'
                                      : 'Independent Corner Radii',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      if (selectedShape!
                                          .hasIndependentCorners) {
                                        final updated = selectedShape!.copyWith(
                                          clearIndependentCorners: true,
                                        );
                                        onShapeChanged(updated);
                                        onShapeChangeEnd?.call(updated);
                                      } else {
                                        final cur = selectedShape!.cornerRadius;
                                        final updated = selectedShape!.copyWith(
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
                                            selectedShape!.hasIndependentCorners
                                            ? colorScheme.primary.withValues(
                                                alpha: 0.16,
                                              )
                                            : colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        RemixIcons.corner_up_left_line,
                                        size: 15,
                                        color:
                                            selectedShape!.hasIndependentCorners
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: selectedShape!.cornerSmoothing > 0
                                      ? 'Disable Corner Smoothing'
                                      : 'Enable Corner Smoothing (Squircle)',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      final isCurrentlySmooth =
                                          selectedShape!.cornerSmoothing > 0;
                                      final newSmoothing = isCurrentlySmooth
                                          ? 0.0
                                          : 0.6;
                                      final needsDefaultRadius =
                                          !isCurrentlySmooth &&
                                          selectedShape!.cornerRadius == 0 &&
                                          !selectedShape!.hasIndependentCorners;
                                      final updated = selectedShape!.copyWith(
                                        cornerSmoothing: newSmoothing,
                                        cornerRadius: needsDefaultRadius
                                            ? 16.0
                                            : null,
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedShape!.cornerSmoothing > 0
                                            ? colorScheme.primary.withValues(
                                                alpha: 0.16,
                                              )
                                            : colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        LucideIcons.squircle,
                                        size: 15,
                                        color:
                                            selectedShape!.cornerSmoothing > 0
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
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
                                    selectedShape!.type ==
                                        ShapeType.rectangle ||
                                    selectedShape!.type == ShapeType.star ||
                                    selectedShape!.type == ShapeType.polygon ||
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
                                      selectedShape!.type ==
                                          ShapeType.image) ...[
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
                                                ? colorScheme.primary
                                                      .withValues(alpha: 0.16)
                                                : colorScheme
                                                      .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              8,
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
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message:
                                          selectedShape!.cornerSmoothing > 0
                                          ? 'Disable Corner Smoothing'
                                          : 'Enable Corner Smoothing (Squircle)',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          final isCurrentlySmooth =
                                              selectedShape!.cornerSmoothing >
                                              0;
                                          final newSmoothing = isCurrentlySmooth
                                              ? 0.0
                                              : 0.6;
                                          final needsDefaultRadius =
                                              !isCurrentlySmooth &&
                                              selectedShape!.cornerRadius ==
                                                  0 &&
                                              !selectedShape!
                                                  .hasIndependentCorners;
                                          final updated = selectedShape!
                                              .copyWith(
                                                cornerSmoothing: newSmoothing,
                                                cornerRadius: needsDefaultRadius
                                                    ? 16.0
                                                    : null,
                                              );
                                          onShapeChanged(updated);
                                          onShapeChangeEnd?.call(updated);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                selectedShape!.cornerSmoothing >
                                                    0
                                                ? colorScheme.primary
                                                      .withValues(alpha: 0.16)
                                                : colorScheme
                                                      .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            LucideIcons.squircle,
                                            size: 15,
                                            color:
                                                selectedShape!.cornerSmoothing >
                                                    0
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
                          ],
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
                          if ((selectedShape!.type == ShapeType.rectangle ||
                                  selectedShape!.type ==
                                      ShapeType.roundedRectangle ||
                                  selectedShape!.type == ShapeType.image) &&
                              selectedShape!.cornerSmoothing > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh
                                    .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.squircle,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Corner Smoothing',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${(selectedShape!.cornerSmoothing * 100).round()}%',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: NixSlider(
                                          value: selectedShape!.cornerSmoothing,
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: (val) {
                                            final updated = selectedShape!
                                                .copyWith(cornerSmoothing: val);
                                            onShapeChanged(updated);
                                          },
                                          onChangeEnd: (val) {
                                            final updated = selectedShape!
                                                .copyWith(cornerSmoothing: val);
                                            onShapeChangeEnd?.call(updated);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 58,
                                        child: _buildNumberField(
                                          context,
                                          '%',
                                          (selectedShape!.cornerSmoothing * 100)
                                              .roundToDouble(),
                                          (val) {
                                            final updated = selectedShape!
                                                .copyWith(
                                                  cornerSmoothing: (val / 100.0)
                                                      .clamp(0.0, 1.0),
                                                );
                                            onShapeChanged(updated);
                                            onShapeChangeEnd?.call(updated);
                                          },
                                          min: 0,
                                          max: 100,
                                          isInteger: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildSquirclePresetChip(
                                        context,
                                        label: 'Round (0%)',
                                        value: 0.0,
                                        currentValue:
                                            selectedShape!.cornerSmoothing,
                                      ),
                                      const SizedBox(width: 6),
                                      _buildSquirclePresetChip(
                                        context,
                                        label: 'iOS (60%)',
                                        value: 0.6,
                                        currentValue:
                                            selectedShape!.cornerSmoothing,
                                      ),
                                      const SizedBox(width: 6),
                                      _buildSquirclePresetChip(
                                        context,
                                        label: 'Smooth (100%)',
                                        value: 1.0,
                                        currentValue:
                                            selectedShape!.cornerSmoothing,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

                    // Star Geometry Section (Sharp Points Count & Ratio)
                    if (selectedShape!.type == ShapeType.star)
                      _CollapsibleSection(
                        title: 'Star Geometry',
                        icon: RemixIcons.star_line,
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

                    // Polygon Geometry Section (Sides & Corner Radius)
                    if (selectedShape!.type == ShapeType.polygon)
                      _CollapsibleSection(
                        title: 'Polygon Geometry',
                        icon: RemixIcons.shape_line,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'POLYGON',
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
                                    '${selectedShape!.pointCount} Sides',
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
                                    'Sides',
                                    selectedShape!.pointCount.toDouble(),
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        pointCount: val.round().clamp(3, 32),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                    min: 3,
                                    max: 32,
                                    isInteger: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    context,
                                    'R',
                                    selectedShape!.cornerRadius,
                                    (val) {
                                      final updated = selectedShape!.copyWith(
                                        cornerRadius: val.clamp(0, 100),
                                      );
                                      onShapeChanged(updated);
                                      onShapeChangeEnd?.call(updated);
                                    },
                                    min: 0,
                                    max: 100,
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
                      _CollapsibleSection(
                        title: selectedShape!.type == ShapeType.text
                            ? 'Text Color'
                            : 'Fill',
                        icon: RemixIcons.paint_fill,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TileSwitch(
                              icon: selectedShape!.type == ShapeType.text
                                  ? RemixIcons.font_color
                                  : RemixIcons.paint_fill,
                              title: selectedShape!.type == ShapeType.text
                                  ? 'Text Color'
                                  : 'Fill Layer',
                              subtitle: selectedShape!.isFilled
                                  ? (selectedShape!.fillGradient != null
                                        ? 'Gradient'
                                        : _colorToHex(selectedShape!.fillColor))
                                  : 'Hidden',
                              value: selectedShape!.isFilled,
                              onChanged: (val) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final updated = selectedShape!.copyWith(
                                  isFilled: val,
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
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
                                    child:
                                        selectedShape!.fillType ==
                                            PaintFillType.solid
                                        ? _HexColorInputField(
                                            key: ValueKey(
                                              'fill-hex-${selectedShape!.id}',
                                            ),
                                            color: selectedShape!.fillColor,
                                            onColorChanged: (newColor) {
                                              final updated = selectedShape!
                                                  .copyWith(
                                                    fillColor: newColor,
                                                  );
                                              onShapeChanged(updated);
                                            },
                                            onColorChangeEnd: (newColor) {
                                              final updated = selectedShape!
                                                  .copyWith(
                                                    fillColor: newColor,
                                                  );
                                              (onShapeChangeEnd ??
                                                  onShapeChanged)(updated);
                                            },
                                          )
                                        : InkWell(
                                            onTapUp: (details) {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              onOpenColorPickerFill(
                                                Rect.fromCenter(
                                                  center:
                                                      details.globalPosition,
                                                  width: 60,
                                                  height: 24,
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              height: 28,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              alignment: Alignment.centerLeft,
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    RemixIcons.gradienter_line,
                                                    size: 13,
                                                    color: colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    selectedShape!.fillType ==
                                                            PaintFillType
                                                                .linearGradient
                                                        ? 'Linear'
                                                        : 'Radial',
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11,
                                                          color: colorScheme
                                                              .onSurface,
                                                        ),
                                                  ),
                                                ],
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
                      _CollapsibleSection(
                        title: 'Stroke',
                        icon: RemixIcons.pen_nib_line,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TileSwitch(
                              icon: RemixIcons.pen_nib_line,
                              title: 'Stroke Outline',
                              subtitle: selectedShape!.isStroked
                                  ? '${selectedShape!.strokeWidth.toStringAsFixed(1)}px • ${_colorToHex(selectedShape!.strokeColor)}'
                                  : 'None',
                              value: selectedShape!.isStroked,
                              onChanged: (val) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final updated = selectedShape!.copyWith(
                                  isStroked: val,
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
                            ),
                            if (selectedShape!.isStroked) ...[
                              const SizedBox(height: 5),
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
                                    child:
                                        selectedShape!.strokeType ==
                                            PaintFillType.solid
                                        ? _HexColorInputField(
                                            key: ValueKey(
                                              'stroke-hex-${selectedShape!.id}',
                                            ),
                                            color: selectedShape!.strokeColor,
                                            onColorChanged: (newColor) {
                                              final updated = selectedShape!
                                                  .copyWith(
                                                    strokeColor: newColor,
                                                  );
                                              onShapeChanged(updated);
                                            },
                                            onColorChangeEnd: (newColor) {
                                              final updated = selectedShape!
                                                  .copyWith(
                                                    strokeColor: newColor,
                                                  );
                                              (onShapeChangeEnd ??
                                                  onShapeChanged)(updated);
                                            },
                                          )
                                        : InkWell(
                                            onTapUp: (details) {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                              onOpenColorPickerStroke(
                                                Rect.fromCenter(
                                                  center:
                                                      details.globalPosition,
                                                  width: 60,
                                                  height: 24,
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              height: 28,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              alignment: Alignment.centerLeft,
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    RemixIcons.gradienter_line,
                                                    size: 13,
                                                    color: colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    selectedShape!.strokeType ==
                                                            PaintFillType
                                                                .linearGradient
                                                        ? 'Linear'
                                                        : 'Radial',
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11,
                                                          color: colorScheme
                                                              .onSurface,
                                                        ),
                                                  ),
                                                ],
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
                              const SizedBox(height: 8),
                              Text(
                                'CAP STYLE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                              const SizedBox(height: 8),
                              Text(
                                'START & END POINTS',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                                                fontSize: 11,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        _LineCapDropdown(
                                          selectedShape: selectedShape!,
                                          isStart: true,
                                          onShapeChanged: onShapeChanged,
                                          onShapeChangeEnd: onShapeChangeEnd,
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
                                                fontSize: 11,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        _LineCapDropdown(
                                          selectedShape: selectedShape!,
                                          isStart: false,
                                          onShapeChanged: onShapeChanged,
                                          onShapeChangeEnd: onShapeChangeEnd,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Curve / Bend properties (If line shape selected)
                    if (selectedShape!.type == ShapeType.line)
                      _CollapsibleSection(
                        title: 'Line Curve / Bend',
                        icon: LucideIcons.spline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TileSwitch(
                              icon: LucideIcons.spline,
                              title: 'CURVE / BEND',
                              subtitle: selectedShape!.isCurved
                                  ? 'Curvature: ${selectedShape!.curvature.round()}px'
                                  : 'Straight line',
                              value: selectedShape!.isCurved,
                              onChanged: (val) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final updated = selectedShape!.copyWith(
                                  isCurved: val,
                                  curvature: val
                                      ? (selectedShape!.curvature == 0.0
                                            ? 30.0
                                            : selectedShape!.curvature)
                                      : 0.0,
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
                            ),
                            if (selectedShape!.isCurved ||
                                selectedShape!.curvature != 0.0) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(LucideIcons.spline, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Bend: ${selectedShape!.curvature.round()} px',
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            if (selectedShape!.curvature != 0.0)
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                onTap: () {
                                                  final updated = selectedShape!
                                                      .copyWith(curvature: 0.0);
                                                  onShapeChanged(updated);
                                                  onShapeChangeEnd?.call(
                                                    updated,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        LucideIcons.rotateCcw,
                                                        size: 11,
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        'Reset',
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              fontSize: 10,
                                                              color: colorScheme
                                                                  .primary,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        NixSlider(
                                          value: selectedShape!.curvature.clamp(
                                            -150.0,
                                            150.0,
                                          ),
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
                                                isCurved: true,
                                              ),
                                            );
                                          },
                                          onChangeEnd: (val) {
                                            (onShapeChangeEnd ??
                                                onShapeChanged)(
                                              selectedShape!.copyWith(
                                                curvature: val,
                                                isCurved: true,
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
                        ),
                      ),

                    // Text properties (If text shape selected)
                    if (selectedShape!.type == ShapeType.text)
                      _CollapsibleSection(
                        title: 'Typography',
                        icon: RemixIcons.text,
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

                            // Font Styles (Bold, Italic, Underline, Strikethrough) - Figma-Style Connected Multi-Select Toggle Group
                            _buildMultiToggleGroup(
                              selectedIndices: {
                                if (selectedShape!.isBold) 0,
                                if (selectedShape!.isItalic) 1,
                                if (selectedShape!.isUnderline) 2,
                                if (selectedShape!.isStrikethrough) 3,
                              },
                              onChanged: (newIndices) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final isNowBold = newIndices.contains(0);
                                final isNowItalic = newIndices.contains(1);
                                final isNowUnderline = newIndices.contains(2);
                                final isNowStrikethrough = newIndices.contains(
                                  3,
                                );
                                final updated = selectedShape!.copyWith(
                                  isBold: isNowBold,
                                  fontWeight: isNowBold
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  isItalic: isNowItalic,
                                  isUnderline: isNowUnderline,
                                  isStrikethrough: isNowStrikethrough,
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
                              actions: const [
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.bold, size: 16),
                                  tooltip: 'Bold',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.italic, size: 16),
                                  tooltip: 'Italic',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(RemixIcons.underline, size: 16),
                                  tooltip: 'Underline',
                                ),
                                M3EToggleButtonGroupAction(
                                  icon: Icon(
                                    RemixIcons.strikethrough,
                                    size: 16,
                                  ),
                                  tooltip: 'Strikethrough',
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
                    _CollapsibleSection(
                      title: 'Export',
                      icon: RemixIcons.download_2_line,
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
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 9.5,
        ) ??
        TextStyle(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 9.5,
        );
  }

  Widget _buildHeaderActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final actions =
        <
          ({
            Widget icon,
            String tooltip,
            bool enabled,
            VoidCallback onTap,
            M3EToggleButtonDecoration? decoration,
          })
        >[
          if (onGroupShapes != null)
            (
              icon: Icon(
                Icons.folder_outlined,
                size: 15,
                color: canGroup
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
              tooltip: 'Group (Ctrl+G)',
              enabled: canGroup,
              onTap: onGroupShapes!,
              decoration: null,
            ),
          if (canUngroup && onUngroupShapes != null)
            (
              icon: Icon(
                Icons.folder_open_outlined,
                size: 15,
                color: colorScheme.onSecondaryContainer,
              ),
              tooltip: 'Ungroup (Ctrl+Shift+G)',
              enabled: true,
              onTap: onUngroupShapes!,
              decoration: null,
            ),
          (
            icon: Icon(
              RemixIcons.file_copy_line,
              size: 15,
              color: colorScheme.onSecondaryContainer,
            ),
            tooltip: 'Duplicate (Ctrl+D)',
            enabled: true,
            onTap: onDuplicateShape,
            decoration: null,
          ),
          (
            icon: Icon(
              RemixIcons.delete_bin_line,
              size: 15,
              color: colorScheme.onErrorContainer,
            ),
            tooltip: 'Delete (Del)',
            enabled: true,
            onTap: onDeleteSelected,
            decoration: M3EToggleButtonDecoration(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return colorScheme.errorContainer.withValues(alpha: 0.85);
                }
                return colorScheme.errorContainer;
              }),
              foregroundColor: WidgetStatePropertyAll(
                colorScheme.onErrorContainer,
              ),
            ),
          ),
        ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = actions.length;
        final itemWidth = (constraints.maxWidth / count).floorToDouble();
        final size = M3EButtonSize.fromBase(M3EButtonSize.sm, width: itemWidth);

        return M3EToggleButtonGroup(
          type: M3EButtonGroupType.standard,
          style: M3EButtonStyle.tonal,
          size: size,
          neighborSquish: true,

          shape: M3EButtonShape.round,
          density: M3EButtonGroupDensity.compact,
          overflow: M3EButtonGroupOverflow.none,
          selectedIndex: null,
          onSelectedIndexChanged: (idx) {
            if (idx != null && idx >= 0 && idx < actions.length) {
              final action = actions[idx];
              if (action.enabled) {
                action.onTap();
              }
            }
          },
          actions: actions.map((a) {
            return M3EToggleButtonGroupAction(
              icon: a.icon,
              tooltip: a.tooltip,
              enabled: a.enabled,
              decoration: a.decoration,
            );
          }).toList(),
        );
      },
    );
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
            final originalStyle =
                uncheckedLabel.style ??
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

  Widget _buildMultiToggleGroup({
    required Set<int> selectedIndices,
    required ValueChanged<Set<int>> onChanged,
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
            final originalStyle =
                uncheckedLabel.style ??
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
          selectedIndices: selectedIndices,
          decoration: groupDecoration,
          onSelectedIndicesChanged: onChanged,
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
                        fontSize: 12.0,
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
                        fontSize: 10.5,
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

        // Section: Viewport & Navigation
        _CollapsibleSection(
          title: 'Viewport & Navigation',
          icon: RemixIcons.navigation_line,
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
                  innerRadius: 10.0,
                  gap: 2.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  color: colorScheme.surfaceContainerHigh,
                  hoverColor: colorScheme.surfaceContainerHighest,
                  pressedRadius: 10.0,
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

              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.8,
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.25 : 0.35,
                ),
              ),
              const SizedBox(height: 10),

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
                  innerRadius: 10.0,
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
        _CollapsibleSection(
          title: 'Canvas Background',
          icon: RemixIcons.palette_line,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color Chip + Hex Field + Opacity
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
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
        _CollapsibleSection(
          title: 'Grid & Snapping',
          icon: RemixIcons.grid_line,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TileSwitch(
                icon: RemixIcons.grid_line,
                title: 'Snap to Grid',
                subtitle: (snapToGrid ?? true)
                    ? 'Snapping to ${gridSpacing?.round() ?? 20}px'
                    : 'Free movement',
                value: snapToGrid ?? true,
                onChanged: onToggleSnapToGrid,
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
        _CollapsibleSection(
          title: 'Artboard Dimensions',
          icon: RemixIcons.artboard_line,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        _CollapsibleSection(
          title: 'Export Canvas',
          icon: RemixIcons.download_2_line,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
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
              ),
              const SizedBox(height: 8),
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

  Widget _buildSquirclePresetChip(
    BuildContext context, {
    required String label,
    required double value,
    required double currentValue,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = (currentValue - value).abs() < 0.02;
    return Expanded(
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          final updated = selectedShape!.copyWith(cornerSmoothing: value);
          onShapeChanged(updated);
          onShapeChangeEnd?.call(updated);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
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

/// Editable Hex input field for Fill, Stroke, Text and Shape colors
class _HexColorInputField extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<Color>? onColorChangeEnd;

  const _HexColorInputField({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.onColorChangeEnd,
  });

  @override
  State<_HexColorInputField> createState() => _HexColorInputFieldState();
}

class _HexColorInputFieldState extends State<_HexColorInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatHex(widget.color));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitHex(_controller.text);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _HexColorInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        (oldWidget.color.toARGB32() & 0x00FFFFFF) !=
            (widget.color.toARGB32() & 0x00FFFFFF)) {
      _controller.text = _formatHex(widget.color);
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
        final existingAlpha = widget.color.a;
        final newColor = Color(0xFF000000 | value)
            .withValues(alpha: existingAlpha);
        widget.onColorChanged(newColor);
        widget.onColorChangeEnd?.call(newColor);
        _controller.text = _formatHex(newColor);
        return;
      }
    } else if (raw.length == 8) {
      final value = int.tryParse(raw, radix: 16);
      if (value != null) {
        final newColor = Color(value);
        widget.onColorChanged(newColor);
        widget.onColorChangeEnd?.call(newColor);
        _controller.text = _formatHex(newColor);
        return;
      }
    }
    _controller.text = _formatHex(widget.color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
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
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: _focusNode.hasFocus
                ? colorScheme.primary.withValues(alpha: 0.14)
                : (_isHovered
                    ? colorScheme.primary.withValues(alpha: 0.08)
                    : colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '#',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: _focusNode.hasFocus
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.5,
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
                  onSubmitted: (val) {
                    _commitHex(val);
                    _focusNode.unfocus();
                  },
                ),
              ),
            ],
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

Widget _buildM3EStyledDropdown<T>({
  Key? key,
  required List<M3EDropdownItem<T>> items,
  required String hintText,
  required ValueChanged<T> onSelected,
  bool searchEnabled = false,
  String searchHint = 'Search…',
  Widget? prefixIcon,
  M3EDropdownItemBuilder<T>? itemBuilder,
}) {
  return M3EDropdownMenu<T>(
    key: key,
    items: items,
    singleSelect: true,
    searchEnabled: searchEnabled,
    showChipAnimation: false,
    enabled: true,
    containerRadius: 100.0,
    haptic: M3EHapticFeedback.light,
    openMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
    closeMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
    fieldStyle: M3EDropdownFieldStyle(
      hintText: hintText,
      prefixIcon: prefixIcon,
      showClearIcon: false,
      padding: EdgeInsets.symmetric(
        horizontal: prefixIcon != null ? 8.0 : 12.0,
        vertical: 7.0,
      ),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(100.0),
      selectedBorderRadius: 100.0,
      hoverRadius: 100.0,
      pressedRadius: 100.0,
      selectedTextStyle: const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(fontSize: 12.0),
      pressedScale: 1.0,
    ),
    dropdownStyle: const M3EDropdownStyle(
      elevation: 0.0,
      maxHeight: 280.0,
      marginTop: 4.0,
      expandDirection: ExpandDirection.auto,
      contentPadding: EdgeInsets.all(6.0),
      containerRadius: 18.0,
    ),
    searchStyle: M3ESearchStyle(
      hintText: searchHint,
      filled: true,
      autofocus: false,
      showClearIcon: true,
      searchDebounceMs: 0,
      borderRadius: BorderRadius.circular(100.0),
      textStyle: const TextStyle(fontSize: 12.0),
      margin: EdgeInsets.only(top: 6.0, left: 6.0, right: 6.0),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4.0,
        vertical: 2.0,
      ),
      mouseCursor: SystemMouseCursors.text,
    ),
    chipStyle: M3EChipStyle(
      borderRadius: BorderRadius.circular(100.0),
      spacing: 4.0,
      runSpacing: 4.0,
      wrap: true,
      maxDisplayCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      openMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
      closeMotion: M3EMotion.custom(stiffness: 500.0, damping: 0.8),
      pressedScale: 1.0,
    ),
    itemStyle: const M3EDropdownItemStyle(
      outerRadius: 10.0,
      innerRadius: 10.0,
      hoverRadius: 10.0,
      pressedRadius: 10.0,
      itemGap: 2.0,
      itemPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      textStyle: TextStyle(fontSize: 12.0),
      selectedTextStyle: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
      pressedScale: 1.0,
      selectedIcon: SizedBox.shrink(),
    ),
    itemBuilder: itemBuilder,
    closeOnBackButton: false,
    onSelectionChanged: (selectedItems) {
      if (selectedItems.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSelected(selectedItems.first.value);
        });
      }
    },
  );
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
    return _buildM3EStyledDropdown<String>(
      key: ValueKey('font_${selectedShape.id}_${selectedShape.fontFamily}'),
      hintText: selectedShape.fontFamily,
      searchEnabled: true,
      searchHint: 'Search fonts…',

      items: _allFonts.map((font) {
        return M3EDropdownItem<String>(
          value: font,
          label: font,
          selected: font == selectedShape.fontFamily,
        );
      }).toList(),
      onSelected: (newValue) {
        if (newValue != selectedShape.fontFamily) {
          final updated = selectedShape.copyWith(fontFamily: newValue);
          onShapeChanged(updated);
          onShapeChangeEnd?.call(updated);
        }
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
    final currentWeightName = _weights
        .firstWhere(
          (w) => w.$1 == selectedShape.fontWeight,
          orElse: () => (FontWeight.w400, 'Regular'),
        )
        .$2;

    return _buildM3EStyledDropdown<FontWeight>(
      key: ValueKey('weight_${selectedShape.id}_${selectedShape.fontWeight}'),
      hintText: currentWeightName,
      items: _weights.map((entry) {
        return M3EDropdownItem<FontWeight>(
          value: entry.$1,
          label: entry.$2,
          selected: entry.$1 == selectedShape.fontWeight,
        );
      }).toList(),
      onSelected: (newValue) {
        if (newValue != selectedShape.fontWeight) {
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
  }
}

class _LineCapDropdown extends StatelessWidget {
  final VectorShape selectedShape;
  final bool isStart;
  final ValueChanged<VectorShape> onShapeChanged;
  final ValueChanged<VectorShape>? onShapeChangeEnd;

  const _LineCapDropdown({
    required this.selectedShape,
    required this.isStart,
    required this.onShapeChanged,
    this.onShapeChangeEnd,
  });

  static const _caps = [
    (LineCapStyle.none, 'None'),
    (LineCapStyle.round, 'Round'),
    (LineCapStyle.square, 'Square'),
    (LineCapStyle.arrow, 'Arrow'),
    (LineCapStyle.circle, 'Circle'),
  ];

  IconData _getCapIcon(LineCapStyle style) {
    switch (style) {
      case LineCapStyle.none:
        return LucideIcons.minus;
      case LineCapStyle.round:
        return LucideIcons.circleDot;
      case LineCapStyle.arrow:
        return isStart ? LucideIcons.arrowLeft : LucideIcons.arrowRight;
      case LineCapStyle.circle:
        return LucideIcons.circle;
      case LineCapStyle.square:
        return LucideIcons.square;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentStyle = isStart
        ? selectedShape.startCap
        : selectedShape.endCap;
    final currentCapName = _caps
        .firstWhere(
          (c) => c.$1 == currentStyle,
          orElse: () => (LineCapStyle.none, 'None'),
        )
        .$2;

    return _buildM3EStyledDropdown<LineCapStyle>(
      key: ValueKey(
        '${isStart ? "start" : "end"}_cap_${selectedShape.id}_$currentStyle',
      ),
      hintText: currentCapName,
      prefixIcon: Icon(
        _getCapIcon(currentStyle),
        size: 14.0,
        color: colorScheme.primary,
      ),
      items: _caps.map((entry) {
        return M3EDropdownItem<LineCapStyle>(
          value: entry.$1,
          label: entry.$2,
          selected: entry.$1 == currentStyle,
        );
      }).toList(),
      onSelected: (newValue) {
        if (newValue != currentStyle) {
          final updated = isStart
              ? selectedShape.copyWith(startCap: newValue)
              : selectedShape.copyWith(endCap: newValue);
          onShapeChanged(updated);
          onShapeChangeEnd?.call(updated);
        }
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
        color: (_focusNode.hasFocus || _isScrubbing)
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
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

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    this.icon,
    required this.child,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _isExpanded = true;

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          if (word == '&' || word == '/') return word;
          if (word.contains('/')) {
            return word
                .split('/')
                .map((part) {
                  if (part.isEmpty) return part;
                  return part[0].toUpperCase() +
                      part.substring(1).toLowerCase();
                })
                .join(' / ');
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: colorScheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.35 : 0.45,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.25 : 0.35,
          ),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Collapsible Header Row
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              hoverColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.4 : 0.6,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        _toTitleCase(widget.title),
                        style:
                            theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              fontSize: 11.5,
                            ) ??
                            TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              fontSize: 11.5,
                            ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.0 : -0.25,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        RemixIcons.arrow_down_s_line,
                        size: 15,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _TileSwitch extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _TileSwitch({
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: value ? (isDark ? 0.5 : 0.65) : (isDark ? 0.2 : 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onChanged != null ? () => onChanged!(!value) : null,
          borderRadius: BorderRadius.circular(8),
          hoverColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.4 : 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: value
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.surfaceContainerHigh.withValues(
                              alpha: 0.5,
                            ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 13,
                      color: value
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: value
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                          fontSize: 11.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9.5,
                            color: value
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: value,
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: colorScheme.onPrimary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
