import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_seekbar/m3e_seekbar.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:m3e_slider/m3e_slider.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:remixicon/remixicon.dart';

class PropertiesSidebar extends StatelessWidget {
  final VectorShape? selectedShape;
  final ValueChanged<VectorShape> onShapeChanged;
  final VoidCallback onOpenColorPickerFill;
  final VoidCallback onOpenColorPickerStroke;
  final VoidCallback onDuplicateShape;
  final VoidCallback onDeleteSelected;
  final Function(String align) onAlignShape;
  final double? width;

  const PropertiesSidebar({
    super.key,
    required this.selectedShape,
    required this.onShapeChanged,
    required this.onOpenColorPickerFill,
    required this.onOpenColorPickerStroke,
    required this.onDuplicateShape,
    required this.onDeleteSelected,
    required this.onAlignShape,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width ?? 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: selectedShape == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      RemixIcons.hand,
                      size: 40,
                      color: colorScheme.outline.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Shape Selected',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Click on a shape or layer to inspect & edit properties.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // Header M3 & Quick Actions with RemixIcons & M3EButtons
                Row(
                  children: [
                    Icon(
                      _getShapeIcon(selectedShape!.type),
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
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
                    M3EButton(
                      onPressed: onDuplicateShape,
                      style: M3EButtonStyle.tonal,
                      size: M3EButtonSize.sm,
                      tooltip: 'Duplicate (Ctrl+D)',
                      child: Icon(
                        RemixIcons.file_copy_line,
                        size: 16,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    M3EButton(
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
                        size: 16,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),

                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  height: 24,
                ),

                // Alignment Controls M3 with RemixIcons & M3E Connected Rows
                Text('ALIGNMENT', style: _getSectionHeaderStyle(theme)),
                const SizedBox(height: 10),

                // Row 1: Horizontal Alignment (Left, Center, Right - connected)
                M3ESegmentedRow(
                  onTap: (index) {
                    const types = ['left', 'center', 'right'];
                    onAlignShape(types[index]);
                  },
                  equalWidth: true,
                  gap: 2.0,
                  decoration: M3ESegmentedListDecoration(
                    outerRadius: 14.0,
                    innerRadius: 4.0,
                    gap: 2.0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    color: colorScheme.surfaceContainerHigh,
                    hoverColor: colorScheme.surfaceContainerHighest,
                    pressedRadius: 8.0,
                    pressedScale: 0.96,
                  ),
                  children: [
                    Tooltip(
                      message: 'Align Left',
                      child: Center(
                        child: Icon(
                          RemixIcons.align_left,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Align Center',
                      child: Center(
                        child: Icon(
                          RemixIcons.align_center,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Align Right',
                      child: Center(
                        child: Icon(
                          RemixIcons.align_right,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Vertical Alignment (Top, Middle, Bottom - connected)
                M3ESegmentedRow(
                  onTap: (index) {
                    const types = ['top', 'middle', 'bottom'];
                    onAlignShape(types[index]);
                  },
                  equalWidth: true,
                  gap: 2.0,
                  decoration: M3ESegmentedListDecoration(
                    outerRadius: 14.0,
                    innerRadius: 4.0,
                    gap: 2.0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    color: colorScheme.surfaceContainerHigh,
                    hoverColor: colorScheme.surfaceContainerHighest,
                    pressedRadius: 8.0,
                    pressedScale: 0.96,
                  ),
                  children: [
                    Tooltip(
                      message: 'Align Top',
                      child: Center(
                        child: Icon(
                          RemixIcons.align_top,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Align Middle',
                      child: Center(
                        child: Icon(
                          RemixIcons.align_vertically,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Align Bottom',
                      child: Center(
                        child: Icon(
                          RemixIcons.align_bottom,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  height: 28,
                ),

                // Transform Geometry (X, Y, W, H, Rotation)
                Text('TRANSFORM', style: _getSectionHeaderStyle(theme)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        context,
                        'X',
                        selectedShape!.rect.left,
                        (val) {
                          final newRect = Rect.fromLTWH(
                            val,
                            selectedShape!.rect.top,
                            selectedShape!.rect.width,
                            selectedShape!.rect.height,
                          );
                          onShapeChanged(
                            selectedShape!.copyWith(rect: newRect),
                          );
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
                          final newRect = Rect.fromLTWH(
                            selectedShape!.rect.left,
                            val,
                            selectedShape!.rect.width,
                            selectedShape!.rect.height,
                          );
                          onShapeChanged(
                            selectedShape!.copyWith(rect: newRect),
                          );
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
                        'W',
                        selectedShape!.rect.width,
                        (val) {
                          final newRect = Rect.fromLTWH(
                            selectedShape!.rect.left,
                            selectedShape!.rect.top,
                            val.clamp(5, 5000),
                            selectedShape!.rect.height,
                          );
                          onShapeChanged(
                            selectedShape!.copyWith(rect: newRect),
                          );
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
                          onShapeChanged(
                            selectedShape!.copyWith(rect: newRect),
                          );
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
                        'Rotate °',
                        selectedShape!.rotation,
                        (val) {
                          onShapeChanged(
                            selectedShape!.copyWith(rotation: val % 360),
                          );
                        },
                      ),
                    ),
                    if (selectedShape!.type == ShapeType.roundedRectangle) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberField(
                          context,
                          'Radius',
                          selectedShape!.cornerRadius,
                          (val) {
                            onShapeChanged(
                              selectedShape!.copyWith(
                                cornerRadius: val.clamp(0, 200),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),

                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  height: 28,
                ),

                // Fill Color & Opacity
                if (selectedShape!.type != ShapeType.line &&
                    selectedShape!.type != ShapeType.image) ...[
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
                          onShapeChanged(
                            selectedShape!.copyWith(isFilled: val),
                          );
                        },
                      ),
                    ],
                  ),
                  if (selectedShape!.isFilled) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onOpenColorPickerFill,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selectedShape!.fillColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Opacity: ${(selectedShape!.fillOpacity * 100).round()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              M3ESlider(
                                value: selectedShape!.fillOpacity,
                                min: 0.0,
                                max: 1.0,
                                decoration: M3ESliderDecoration(
                                  colors: M3ESliderColors(
                                    thumbColor: colorScheme.primary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveTrackColor:
                                        colorScheme.surfaceContainerHighest,
                                    disabledThumbColor: colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                                    disabledActiveTrackColor: colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.38),
                                    disabledInactiveTrackColor: colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.38),
                                    activeTickColor: colorScheme.onPrimary,
                                    inactiveTickColor:
                                        colorScheme.onSurfaceVariant,
                                    disabledActiveTickColor: colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.38),
                                    disabledInactiveTickColor: colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.38),
                                  ),
                                ),
                                onChanged: (val) {
                                  onShapeChanged(
                                    selectedShape!.copyWith(fillOpacity: val),
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

                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  height: 28,
                ),

                // Stroke Color & Width
                if (selectedShape!.type != ShapeType.image &&
                    selectedShape!.type != ShapeType.text) ...[
                  Row(
                    children: [
                      Text('STROKE', style: _getSectionHeaderStyle(theme)),
                      const Spacer(),
                      Switch(
                        value: selectedShape!.isStroked,
                        activeTrackColor: colorScheme.primary,
                        onChanged: (val) {
                          onShapeChanged(
                            selectedShape!.copyWith(isStroked: val),
                          );
                        },
                      ),
                    ],
                  ),
                  if (selectedShape!.isStroked) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onOpenColorPickerStroke,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selectedShape!.strokeColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Width: ${selectedShape!.strokeWidth.round()} px',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              M3ESeekbar(
                                value: selectedShape!.strokeWidth,
                                min: 1.0,
                                max: 30.0,
                                decoration: M3ESeekbarDecoration(
                                  colors: M3ESeekbarColors(
                                    handleColor: colorScheme.primary,
                                    activeTrackColor: colorScheme.primary,
                                    inactiveTrackColor:
                                        colorScheme.surfaceContainerHighest,
                                    disabledHandleColor: colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                                    disabledActiveTrackColor: colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.38),
                                    disabledInactiveTrackColor: colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.38),
                                    secondaryTrackColor: colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    disabledSecondaryTrackColor: colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                onChanged: (val) {
                                  onShapeChanged(
                                    selectedShape!.copyWith(strokeWidth: val),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      M3ESegmentedRow(
                        onTap: (index) {
                          final caps = [
                            StrokeCap.butt,
                            StrokeCap.round,
                            StrokeCap.square,
                          ];
                          onShapeChanged(
                            selectedShape!.copyWith(strokeCap: caps[index]),
                          );
                        },
                        equalWidth: true,
                        gap: 2.0,
                        decoration: M3ESegmentedListDecoration(
                          outerRadius: 10.0,
                          innerRadius: 4.0,
                          gap: 2.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          color: colorScheme.surfaceContainerHigh,
                          hoverColor: colorScheme.surfaceContainerHighest,
                          pressedRadius: 6.0,
                          pressedScale: 0.96,
                        ),
                        children: [
                          Tooltip(
                            message: 'Butt / Flat Cap',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.minus,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Flat',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Round Cap',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.circle,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Round',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Square Cap',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.square,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Square',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Point',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<LineCapStyle>(
                                      value: selectedShape!.startCap,
                                      isExpanded: true,
                                      isDense: true,
                                      icon: const Icon(LucideIcons.chevronDown, size: 14),
                                      items: const [
                                        DropdownMenuItem(
                                          value: LineCapStyle.none,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.minus, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'None',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: LineCapStyle.arrow,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.arrowLeft, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Arrow',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: LineCapStyle.circle,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.circle, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Circle',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: LineCapStyle.square,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.square, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Square',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          onShapeChanged(
                                            selectedShape!.copyWith(startCap: val),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Point',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<LineCapStyle>(
                                      value: selectedShape!.endCap,
                                      isExpanded: true,
                                      isDense: true,
                                      icon: const Icon(LucideIcons.chevronDown, size: 14),
                                      items: const [
                                        DropdownMenuItem(
                                          value: LineCapStyle.none,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.minus, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'None',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: LineCapStyle.arrow,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.arrowRight, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Arrow',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: LineCapStyle.circle,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.circle, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Circle',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: LineCapStyle.square,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.square, size: 14),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Square',
                                                  style: TextStyle(fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          onShapeChanged(
                                            selectedShape!.copyWith(endCap: val),
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
                              onShapeChanged(
                                selectedShape!.copyWith(
                                  isCurved: val,
                                  curvature: val && selectedShape!.curvature == 0.0
                                      ? 30.0
                                      : selectedShape!.curvature,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (selectedShape!.isCurved || selectedShape!.curvature != 0.0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(LucideIcons.spline, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bend Offset: ${selectedShape!.curvature.round()} px',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  M3ESeekbar(
                                    value: selectedShape!.curvature,
                                    min: -150.0,
                                    max: 150.0,
                                    decoration: M3ESeekbarDecoration(
                                      colors: M3ESeekbarColors(
                                        handleColor: colorScheme.primary,
                                        activeTrackColor: colorScheme.primary,
                                        inactiveTrackColor:
                                            colorScheme.surfaceContainerHighest,
                                        disabledHandleColor: colorScheme.onSurface
                                            .withValues(alpha: 0.38),
                                        disabledActiveTrackColor: colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.38),
                                        disabledInactiveTrackColor: colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.38),
                                        secondaryTrackColor: colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        disabledSecondaryTrackColor: colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      onShapeChanged(
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
                ],

                // Text properties (If text shape selected)
                if (selectedShape!.type == ShapeType.text) ...[
                  Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    height: 28,
                  ),
                  Text('TEXT CONTENT', style: _getSectionHeaderStyle(theme)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: selectedShape!.textContent,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      onShapeChanged(selectedShape!.copyWith(textContent: val));
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Font Size: ${selectedShape!.fontSize.round()} px',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  M3ESlider(
                    value: selectedShape!.fontSize,
                    min: 10.0,
                    max: 120.0,
                    decoration: M3ESliderDecoration(
                      colors: M3ESliderColors(
                        thumbColor: colorScheme.primary,
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.surfaceContainerHighest,
                        disabledThumbColor: colorScheme.onSurface.withValues(
                          alpha: 0.38,
                        ),
                        disabledActiveTrackColor: colorScheme.onSurface
                            .withValues(alpha: 0.38),
                        disabledInactiveTrackColor: colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.38),
                        activeTickColor: colorScheme.onPrimary,
                        inactiveTickColor: colorScheme.onSurfaceVariant,
                        disabledActiveTickColor: colorScheme.onSurface
                            .withValues(alpha: 0.38),
                        disabledInactiveTickColor: colorScheme.onSurface
                            .withValues(alpha: 0.38),
                      ),
                    ),
                    onChanged: (val) {
                      onShapeChanged(selectedShape!.copyWith(fontSize: val));
                    },
                  ),
                  const SizedBox(height: 12),
                  // Font Family & Style
                  Row(
                    children: [
                      Expanded(
                        child: _FontDropdown(
                          selectedShape: selectedShape!,
                          onShapeChanged: onShapeChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bold Toggle
                      M3EButton(
                        onPressed: () {
                          onShapeChanged(
                            selectedShape!.copyWith(
                              isBold: !selectedShape!.isBold,
                            ),
                          );
                        },
                        style: selectedShape!.isBold
                            ? M3EButtonStyle.filled
                            : M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        child: Icon(RemixIcons.bold, size: 16),
                      ),
                      const SizedBox(width: 4),
                      // Italic Toggle
                      M3EButton(
                        onPressed: () {
                          onShapeChanged(
                            selectedShape!.copyWith(
                              isItalic: !selectedShape!.isItalic,
                            ),
                          );
                        },
                        style: selectedShape!.isItalic
                            ? M3EButtonStyle.filled
                            : M3EButtonStyle.tonal,
                        size: M3EButtonSize.sm,
                        child: Icon(RemixIcons.italic, size: 16),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  TextStyle _getSectionHeaderStyle(ThemeData theme) {
    return theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ) ??
        TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        );
  }

  Widget _buildNumberField(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('$label-${value.round()}'),
              initialValue: value.round().toString(),
              keyboardType: TextInputType.number,
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
                final double? parsed = double.tryParse(text);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
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

class _FontDropdown extends StatefulWidget {
  final VectorShape selectedShape;
  final ValueChanged<VectorShape> onShapeChanged;

  const _FontDropdown({
    required this.selectedShape,
    required this.onShapeChanged,
  });

  @override
  State<_FontDropdown> createState() => _FontDropdownState();
}

class _FontDropdownState extends State<_FontDropdown> {
  final List<String> _allFonts = [
    'Google Sans',
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Oswald',
  ];


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          width: constraints.maxWidth,
          initialSelection: widget.selectedShape.fontFamily,
          enableSearch: true,
          enableFilter: true,
          requestFocusOnTap: true,
          textStyle: const TextStyle(fontSize: 14),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          dropdownMenuEntries: _allFonts.map((font) {
            return DropdownMenuEntry<String>(
              value: font,
              label: font,
            );
          }).toList(),
          onSelected: (newValue) {
            if (newValue != null && newValue != widget.selectedShape.fontFamily) {
              widget.onShapeChanged(
                widget.selectedShape.copyWith(fontFamily: newValue),
              );
            }
          },
        );
      },
    );
  }
}
