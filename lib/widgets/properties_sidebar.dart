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
    this.onShapeChangeEnd,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                              final newRect = Rect.fromLTWH(
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            context,
                            'Rotate °',
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
                            ShapeType.roundedRectangle) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildNumberField(
                              context,
                              'Radius',
                              selectedShape!.cornerRadius,
                              (val) {
                                final updated = selectedShape!.copyWith(
                                  cornerRadius: val.clamp(0, 200),
                                );
                                onShapeChanged(updated);
                                onShapeChangeEnd?.call(updated);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              final updated = selectedShape!.copyWith(
                                rotation: (-selectedShape!.rotation) % 360,
                              );
                              onShapeChanged(updated);
                              onShapeChangeEnd?.call(updated);
                            },
                            icon: const Icon(RemixIcons.swap_line, size: 14),
                            label: const Text(
                              'Flip H',
                              style: TextStyle(fontSize: 11),
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
                              FocusManager.instance.primaryFocus?.unfocus();
                              final updated = selectedShape!.copyWith(
                                rotation: (180 - selectedShape!.rotation) % 360,
                              );
                              onShapeChanged(updated);
                              onShapeChangeEnd?.call(updated);
                            },
                            icon: const Icon(
                              RemixIcons.swap_box_line,
                              size: 14,
                            ),
                            label: const Text(
                              'Flip V',
                              style: TextStyle(fontSize: 11),
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

                    Divider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      height: 28,
                    ),

                    // Fill Color, Gradient & Opacity
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
                              FocusManager.instance.primaryFocus?.unfocus();
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
                        _buildToggleGroup(
                          selectedIndex: switch (selectedShape!.fillType) {
                            PaintFillType.solid => 0,
                            PaintFillType.linearGradient => 1,
                            PaintFillType.radialGradient => 2,
                          },
                          onChanged: (index) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            final types = [
                              PaintFillType.solid,
                              PaintFillType.linearGradient,
                              PaintFillType.radialGradient,
                            ];
                            final targetType = types[index];
                            ShapeGradient? nextGradient;
                            if (targetType != PaintFillType.solid) {
                              final existing = selectedShape!.fillGradient;
                              if (existing != null) {
                                nextGradient = existing.copyWith(
                                  type: targetType,
                                );
                              } else {
                                nextGradient = ShapeGradient(
                                  type: targetType,
                                  stops: [
                                    GradientColorStop(
                                      offset: 0.0,
                                      color: selectedShape!.fillColor,
                                    ),
                                    const GradientColorStop(
                                      offset: 1.0,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ],
                                );
                              }
                            } else {
                              nextGradient = selectedShape!.fillGradient;
                            }

                            final updated = selectedShape!.copyWith(
                              fillType: targetType,
                              fillGradient: nextGradient,
                            );
                            onShapeChanged(updated);
                            onShapeChangeEnd?.call(updated);
                          },
                          actions: const [
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Solid',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Solid Fill',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Linear',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Linear Gradient',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Radial',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Radial Gradient',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // If Solid: show color swatch and hex
                        if (selectedShape!.fillType == PaintFillType.solid) ...[
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  onOpenColorPickerFill();
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: selectedShape!.fillColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  onOpenColorPickerFill();
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    _colorToHex(selectedShape!.fillColor),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
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
                        ] else ...[
                          // Gradient Controls (Stops chips + angle if linear)
                          _buildGradientControls(
                            context: context,
                            gradient:
                                selectedShape!.fillGradient ??
                                ShapeGradient(
                                  type: selectedShape!.fillType,
                                  stops: [
                                    GradientColorStop(
                                      offset: 0.0,
                                      color: selectedShape!.fillColor,
                                    ),
                                    const GradientColorStop(
                                      offset: 1.0,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ],
                                ),
                            onGradientChanged: (newGrad) {
                              final updated = selectedShape!.copyWith(
                                fillGradient: newGrad,
                              );
                              onShapeChanged(updated);
                              onShapeChangeEnd?.call(updated);
                            },
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Opacity',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
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
                          onChangeStart: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
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

                    Divider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      height: 28,
                    ),

                    // Stroke Color, Gradient, Opacity & Styles
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
                              FocusManager.instance.primaryFocus?.unfocus();
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
                        _buildToggleGroup(
                          selectedIndex: switch (selectedShape!.strokeType) {
                            PaintFillType.solid => 0,
                            PaintFillType.linearGradient => 1,
                            PaintFillType.radialGradient => 2,
                          },
                          onChanged: (index) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            final types = [
                              PaintFillType.solid,
                              PaintFillType.linearGradient,
                              PaintFillType.radialGradient,
                            ];
                            final targetType = types[index];
                            ShapeGradient? nextGradient;
                            if (targetType != PaintFillType.solid) {
                              final existing = selectedShape!.strokeGradient;
                              if (existing != null) {
                                nextGradient = existing.copyWith(
                                  type: targetType,
                                );
                              } else {
                                nextGradient = ShapeGradient(
                                  type: targetType,
                                  stops: [
                                    GradientColorStop(
                                      offset: 0.0,
                                      color: selectedShape!.strokeColor,
                                    ),
                                    const GradientColorStop(
                                      offset: 1.0,
                                      color: Color(0xFFEC4899),
                                    ),
                                  ],
                                );
                              }
                            } else {
                              nextGradient = selectedShape!.strokeGradient;
                            }

                            final updated = selectedShape!.copyWith(
                              strokeType: targetType,
                              strokeGradient: nextGradient,
                            );
                            onShapeChanged(updated);
                            onShapeChangeEnd?.call(updated);
                          },
                          actions: const [
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Solid',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Solid Stroke',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Linear',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Linear Gradient Stroke',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Radial',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Radial Gradient Stroke',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Stroke Color or Gradient Controls
                        if (selectedShape!.strokeType ==
                            PaintFillType.solid) ...[
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  onOpenColorPickerStroke();
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: selectedShape!.strokeColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  onOpenColorPickerStroke();
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    _colorToHex(selectedShape!.strokeColor),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
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
                        ] else ...[
                          _buildGradientControls(
                            context: context,
                            gradient:
                                selectedShape!.strokeGradient ??
                                ShapeGradient(
                                  type: selectedShape!.strokeType,
                                  stops: [
                                    GradientColorStop(
                                      offset: 0.0,
                                      color: selectedShape!.strokeColor,
                                    ),
                                    const GradientColorStop(
                                      offset: 1.0,
                                      color: Color(0xFFEC4899),
                                    ),
                                  ],
                                ),
                            onGradientChanged: (newGrad) {
                              final updated = selectedShape!.copyWith(
                                strokeGradient: newGrad,
                              );
                              onShapeChanged(updated);
                              onShapeChangeEnd?.call(updated);
                            },
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Stroke Width Slider
                        Row(
                          children: [
                            Text(
                              'Width',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
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
                          onChangeStart: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
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
                            Text(
                              'Opacity',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
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
                          onChangeStart: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
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
                          selectedIndex: switch (selectedShape!.strokeAlign) {
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
                          actions: const [
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Inside',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Inside Stroke',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Center',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Center Stroke',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Outside',
                                style: TextStyle(fontSize: 11),
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
                          selectedIndex: switch (selectedShape!.strokeStyle) {
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
                          actions: const [
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Solid',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Solid Style',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Dashed',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Dashed Style',
                            ),
                            M3EToggleButtonGroupAction(
                              label: Text(
                                'Dotted',
                                style: TextStyle(fontSize: 11),
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
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${selectedShape!.strokeDashLength.round()} px',
                                style: theme.textTheme.labelSmall?.copyWith(
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
                            onChangeStart: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            onChanged: (val) {
                              onShapeChanged(
                                selectedShape!.copyWith(strokeDashLength: val),
                              );
                            },
                            onChangeEnd: (val) {
                              (onShapeChangeEnd ?? onShapeChanged)(
                                selectedShape!.copyWith(strokeDashLength: val),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Dash Gap',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${selectedShape!.strokeDashGap.round()} px',
                                style: theme.textTheme.labelSmall?.copyWith(
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
                            onChangeStart: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            onChanged: (val) {
                              onShapeChanged(
                                selectedShape!.copyWith(strokeDashGap: val),
                              );
                            },
                            onChangeEnd: (val) {
                              (onShapeChangeEnd ?? onShapeChanged)(
                                selectedShape!.copyWith(strokeDashGap: val),
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
                          selectedIndex: switch (selectedShape!.strokeCap) {
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
                              selectedShape!.copyWith(strokeCap: caps[index]),
                            );
                          },
                          actions: const [
                            M3EToggleButtonGroupAction(
                              icon: Icon(LucideIcons.minus, size: 14),
                              label: Text(
                                'Flat',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Butt / Flat Cap',
                            ),
                            M3EToggleButtonGroupAction(
                              icon: Icon(LucideIcons.circle, size: 12),
                              label: Text(
                                'Round',
                                style: TextStyle(fontSize: 11),
                              ),
                              tooltip: 'Round Cap',
                            ),
                            M3EToggleButtonGroupAction(
                              icon: Icon(LucideIcons.square, size: 12),
                              label: Text(
                                'Square',
                                style: TextStyle(fontSize: 11),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
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
                                        items: const [
                                          DropdownMenuItem(
                                            value: LineCapStyle.none,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.minus,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'None',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                Icon(
                                                  LucideIcons.arrowLeft,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Arrow',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                Icon(
                                                  LucideIcons.circle,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Circle',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                Icon(
                                                  LucideIcons.square,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Square',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
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
                                        items: const [
                                          DropdownMenuItem(
                                            value: LineCapStyle.none,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.minus,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'None',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                Icon(
                                                  LucideIcons.arrowRight,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Arrow',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                Icon(
                                                  LucideIcons.circle,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Circle',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                Icon(
                                                  LucideIcons.square,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Square',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                FocusManager.instance.primaryFocus?.unfocus();
                                final updated = selectedShape!.copyWith(
                                  isCurved: val,
                                  curvature:
                                      val && selectedShape!.curvature == 0.0
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bend Offset: ${selectedShape!.curvature.round()} px',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
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
                                        (onShapeChangeEnd ?? onShapeChanged)(
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

                    // Text properties (If text shape selected)
                    if (selectedShape!.type == ShapeType.text) ...[
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        height: 28,
                      ),
                      Text(
                        'TEXT CONTENT',
                        style: _getSectionHeaderStyle(theme),
                      ),
                      const SizedBox(height: 8),
                      _TextContentInputField(
                        key: ValueKey('text-content-${selectedShape!.id}'),
                        textContent: selectedShape!.textContent,
                        onChanged: (val) {
                          onShapeChanged(
                            selectedShape!.copyWith(textContent: val),
                          );
                        },
                        onCommit: () {
                          (onShapeChangeEnd ?? onShapeChanged)(selectedShape!);
                        },
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 14),
                      // Typography Header
                      Text('TYPOGRAPHY', style: _getSectionHeaderStyle(theme)),
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
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  final isNowBold = !selectedShape!.isBold;
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
                                child: const Icon(RemixIcons.bold, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Tooltip(
                              message: 'Italic',
                              child: M3EButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
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
                                child: const Icon(RemixIcons.italic, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Tooltip(
                              message: 'Underline',
                              child: M3EButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  final updated = selectedShape!.copyWith(
                                    isUnderline: !selectedShape!.isUnderline,
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
                                  FocusManager.instance.primaryFocus?.unfocus();
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
                            icon: Icon(RemixIcons.align_justify, size: 16),
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
                            icon: Icon(RemixIcons.align_vertically, size: 16),
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
                      Text('TEXT CASE', style: _getSectionHeaderStyle(theme)),
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
                        actions: const [
                          M3EToggleButtonGroupAction(
                            label: Text(
                              'Aa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            tooltip: 'As Typed',
                          ),
                          M3EToggleButtonGroupAction(
                            label: Text(
                              'AA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            tooltip: 'UPPERCASE',
                          ),
                          M3EToggleButtonGroupAction(
                            label: Text(
                              'aa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            tooltip: 'lowercase',
                          ),
                          M3EToggleButtonGroupAction(
                            label: Text(
                              'Ab',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
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
                        value: selectedShape!.letterSpacing.clamp(-2.0, 20.0),
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
                  ],
                ),
        ),
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

  Widget _buildToggleGroup({
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    required List<M3EToggleButtonGroupAction> actions,
    M3EButtonStyle style = M3EButtonStyle.tonal,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = actions.length;
        final totalGaps = (count - 1) * 2.0;
        final itemWidth = ((constraints.maxWidth - totalGaps) / count)
            .floorToDouble();
        final size = M3EButtonSize.fromBase(
          M3EButtonSize.xs,
          hPadding: 2,
          width: itemWidth,
        );

        return M3EToggleButtonGroup(
          type: M3EButtonGroupType.connected,

          style: style,
          size: size,
          shape: M3EButtonShape.round,
          density: M3EButtonGroupDensity.compact,
          overflow: M3EButtonGroupOverflow.none,
          selectedIndex: selectedIndex,
          onSelectedIndexChanged: (idx) {
            if (idx != null) {
              onChanged(idx);
            }
          },
          actions: actions,
        );
      },
    );
  }

  Widget _buildGradientControls({
    required BuildContext context,
    required ShapeGradient gradient,
    required ValueChanged<ShapeGradient> onGradientChanged,
  }) {
    return _FigmaGradientControls(
      gradient: gradient,
      onGradientChanged: onGradientChanged,
    );
  }

  Widget _buildNumberField(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged, {
    VoidCallback? onEditingComplete,
  }) {
    return _NumberInputField(
      key: ValueKey('$label-${selectedShape?.id}'),
      label: label,
      value: value,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
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
          textStyle: const TextStyle(fontSize: 13),
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
          textStyle: const TextStyle(fontSize: 13),
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

/// Production-grade Material 3 Expressive Number Input Field.
/// Handles instant blur commit, Enter submission with auto-unfocus,
/// Up/Down arrow nudge (holding Shift = 10x), Escape cancel, and text selection on focus.
class _NumberInputField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback? onEditingComplete;

  const _NumberInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onEditingComplete,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.round().toString());
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
      widget.onChanged(parsed);
    } else {
      _controller.text = widget.value.round().toString();
    }
    widget.onEditingComplete?.call();
  }

  @override
  void didUpdateWidget(covariant _NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final currentParsed = double.tryParse(_controller.text.trim());
      if (currentParsed?.round() != widget.value.round()) {
        _controller.text = widget.value.round().toString();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNode.hasFocus
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: _focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
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
                    final next = cur + step;
                    _controller.text = next.round().toString();
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
                    final next = cur - step;
                    _controller.text = next.round().toString();
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                    widget.onChanged(next);
                    widget.onEditingComplete?.call();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _controller.text = widget.value.round().toString();
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

/// Figma-style interactive Gradient Controls.
/// Provides a continuous horizontal gradient spectrum bar with draggable stop handles,
/// click-to-add stops, selected stop color/position preview, delete button,
/// and a compact angle control for linear gradients.
class _FigmaGradientControls extends StatefulWidget {
  final ShapeGradient gradient;
  final ValueChanged<ShapeGradient> onGradientChanged;

  const _FigmaGradientControls({
    required this.gradient,
    required this.onGradientChanged,
  });

  @override
  State<_FigmaGradientControls> createState() => _FigmaGradientControlsState();
}

class _FigmaGradientControlsState extends State<_FigmaGradientControls> {
  int _selectedStopIndex = 0;

  @override
  void didUpdateWidget(covariant _FigmaGradientControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedStopIndex >= widget.gradient.stops.length) {
      _selectedStopIndex = widget.gradient.stops.length - 1;
    }
  }

  void _addStopAt(double offset) {
    if (widget.gradient.stops.length >= 8) return;
    final stops = List<GradientColorStop>.from(widget.gradient.stops);
    final clampedOffset = offset.clamp(0.0, 1.0);

    // Lerp color between surrounding stops
    Color newColor = const Color(0xFF6366F1);
    if (stops.isNotEmpty) {
      GradientColorStop? prev;
      GradientColorStop? next;
      for (final s in stops) {
        if (s.offset <= clampedOffset) {
          if (prev == null || s.offset > prev.offset) prev = s;
        }
        if (s.offset >= clampedOffset) {
          if (next == null || s.offset < next.offset) next = s;
        }
      }
      if (prev != null && next != null && prev != next) {
        final t = (clampedOffset - prev.offset) / (next.offset - prev.offset);
        newColor = Color.lerp(prev.color, next.color, t) ?? prev.color;
      } else if (prev != null) {
        newColor = prev.color;
      } else if (next != null) {
        newColor = next.color;
      }
    }

    stops.add(GradientColorStop(offset: clampedOffset, color: newColor));
    stops.sort((a, b) => a.offset.compareTo(b.offset));
    final newIdx = stops.indexWhere(
      (s) => (s.offset - clampedOffset).abs() < 0.001,
    );

    setState(() {
      _selectedStopIndex = newIdx != -1 ? newIdx : stops.length - 1;
    });

    widget.onGradientChanged(widget.gradient.copyWith(stops: stops));
  }

  void _updateStopOffset(int index, double newOffset) {
    final stops = List<GradientColorStop>.from(widget.gradient.stops);
    final clamped = newOffset.clamp(0.0, 1.0);
    stops[index] = stops[index].copyWith(offset: clamped);
    stops.sort((a, b) => a.offset.compareTo(b.offset));
    final newIdx = stops.indexOf(
      stops.firstWhere(
        (s) =>
            s.color == widget.gradient.stops[index].color &&
            (s.offset - clamped).abs() < 0.001,
        orElse: () => stops[0],
      ),
    );

    setState(() {
      _selectedStopIndex = newIdx >= 0 ? newIdx : index;
    });

    widget.onGradientChanged(widget.gradient.copyWith(stops: stops));
  }

  void _removeStop(int index) {
    if (widget.gradient.stops.length <= 2) return;
    final stops = List<GradientColorStop>.from(widget.gradient.stops);
    stops.removeAt(index);
    setState(() {
      _selectedStopIndex = (_selectedStopIndex >= stops.length)
          ? stops.length - 1
          : _selectedStopIndex;
    });
    widget.onGradientChanged(widget.gradient.copyWith(stops: stops));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stops = widget.gradient.stops;
    if (_selectedStopIndex >= stops.length) {
      _selectedStopIndex = stops.length - 1;
    }
    final currentStop = stops[_selectedStopIndex];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Stops count & Add Stop hint
          Row(
            children: [
              Text(
                'GRADIENT BAR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                'Click bar to add',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Figma-style Gradient Track with interactive stop thumbs
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              const handleSize = 18.0;

              return SizedBox(
                height: 32,
                width: trackWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // The continuous gradient bar (Clickable to add stops)
                    GestureDetector(
                      onTapUp: (details) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        final localX = details.localPosition.dx;
                        final offset = (localX / trackWidth).clamp(0.0, 1.0);
                        _addStopAt(offset);
                      },
                      child: Container(
                        height: 14,
                        width: trackWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                            width: 1.0,
                          ),
                          gradient: LinearGradient(
                            colors: stops.map((s) => s.color).toList(),
                            stops: stops.map((s) => s.offset).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Draggable Stop Thumbs (Figma teardrop / circle pins)
                    ...stops.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stop = entry.value;
                      final isSelected = idx == _selectedStopIndex;
                      final thumbCenter = stop.offset * trackWidth;
                      final left = (thumbCenter - (handleSize / 2)).clamp(
                        0.0,
                        trackWidth - handleSize,
                      );

                      return Positioned(
                        left: left,
                        top: 7, // Center on 32-high stack (32 - 18) / 2 = 7
                        child: GestureDetector(
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _selectedStopIndex = idx);
                          },
                          onPanUpdate: (details) {
                            final deltaOffset = details.delta.dx / trackWidth;
                            _updateStopOffset(idx, stop.offset + deltaOffset);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: handleSize,
                            height: handleSize,
                            decoration: BoxDecoration(
                              color: stop.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.white,
                                width: isSelected ? 2.5 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Selected Stop Editor Bar: Color chip + Hex + Position Slider + Delete button
          Row(
            children: [
              // Color Chip
              GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  showDialog(
                    context: context,
                    builder: (context) => ColorPickerDialog(
                      title: 'Stop ${_selectedStopIndex + 1} Color',
                      initialColor: currentStop.color,
                      onColorSelected: (col) {
                        final newStops = List<GradientColorStop>.from(stops);
                        newStops[_selectedStopIndex] = currentStop.copyWith(
                          color: col,
                        );
                        widget.onGradientChanged(
                          widget.gradient.copyWith(stops: newStops),
                        );
                      },
                    ),
                  );
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: currentStop.color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Position % indicator / slider
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Pos',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: NixSlider(
                        value: currentStop.offset,
                        min: 0.0,
                        max: 1.0,
                        onChangeStart: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        onChanged: (val) {
                          _updateStopOffset(_selectedStopIndex, val);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(currentStop.offset * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              if (stops.length > 2) ...[
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 14,
                  tooltip: 'Delete Stop',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: Icon(LucideIcons.trash2, color: colorScheme.error),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _removeStop(_selectedStopIndex);
                  },
                ),
              ],
            ],
          ),

          // Linear Gradient Angle Control (compact)
          if (widget.gradient.type == PaintFillType.linearGradient) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.compass,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Angle',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NixSlider(
                    value: widget.gradient.angle,
                    min: 0.0,
                    max: 360.0,
                    onChangeStart: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onChanged: (val) {
                      widget.onGradientChanged(
                        widget.gradient.copyWith(angle: val),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.gradient.angle.round()}°',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
