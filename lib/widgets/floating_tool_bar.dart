import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:m3e_floating_toolbar/m3e_floating_toolbar.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:remixicon/remixicon.dart';

class ShapeToolOption {
  final EditorMode mode;
  final String label;
  final String shortcut;
  final IconData icon;

  const ShapeToolOption({
    required this.mode,
    required this.label,
    required this.shortcut,
    required this.icon,
  });
}

const List<ShapeToolOption> kShapeTools = [
  ShapeToolOption(
    mode: EditorMode.drawRectangle,
    label: 'Rectangle',
    shortcut: 'R',
    icon: RemixIcons.checkbox_blank_line,
  ),
  ShapeToolOption(
    mode: EditorMode.drawRoundedRectangle,
    label: 'Rounded Rectangle',
    shortcut: 'U',
    icon: RemixIcons.rectangle_line,
  ),
  ShapeToolOption(
    mode: EditorMode.drawEllipse,
    label: 'Ellipse',
    shortcut: 'O',
    icon: RemixIcons.checkbox_blank_circle_line,
  ),
  ShapeToolOption(
    mode: EditorMode.drawLine,
    label: 'Line',
    shortcut: 'L',
    icon: LucideIcons.minus,
  ),
  ShapeToolOption(
    mode: EditorMode.drawCurve,
    label: 'Curve',
    shortcut: 'C',
    icon: LucideIcons.spline,
  ),
  ShapeToolOption(
    mode: EditorMode.drawStar,
    label: 'Star',
    shortcut: 'S',
    icon: RemixIcons.star_line,
  ),
  ShapeToolOption(
    mode: EditorMode.drawPolygon,
    label: 'Polygon',
    shortcut: 'Y',
    icon: RemixIcons.hexagon_line,
  ),
];

class FloatingToolBar extends StatefulWidget {
  final EditorMode currentMode;
  final ValueChanged<EditorMode> onModeChanged;
  final VoidCallback? onExportSvg;

  const FloatingToolBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.onExportSvg,
  });

  @override
  State<FloatingToolBar> createState() => _FloatingToolBarState();
}

class _FloatingToolBarState extends State<FloatingToolBar> {
  final GlobalKey _shapeButtonKey = GlobalKey();
  OverlayEntry? _shapesOverlayEntry;
  EditorMode _activeShapeMode = EditorMode.drawRectangle;

  static const Set<EditorMode> _shapeModes = {
    EditorMode.drawRectangle,
    EditorMode.drawRoundedRectangle,
    EditorMode.drawEllipse,
    EditorMode.drawLine,
    EditorMode.drawCurve,
    EditorMode.drawStar,
    EditorMode.drawPolygon,
  };

  @override
  void initState() {
    super.initState();
    if (_shapeModes.contains(widget.currentMode)) {
      _activeShapeMode = widget.currentMode;
    }
  }

  @override
  void didUpdateWidget(covariant FloatingToolBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shapeModes.contains(widget.currentMode) &&
        widget.currentMode != _activeShapeMode) {
      _activeShapeMode = widget.currentMode;
    }
  }

  @override
  void dispose() {
    _hideShapesPopup();
    super.dispose();
  }

  void _hideShapesPopup() {
    _shapesOverlayEntry?.remove();
    _shapesOverlayEntry = null;
  }

  void _toggleShapesPopup() {
    if (_shapesOverlayEntry != null) {
      _hideShapesPopup();
    } else {
      _showShapesPopup();
    }
  }

  void _showShapesPopup() {
    _hideShapesPopup();

    final renderBox =
        _shapeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final buttonGlobalPos = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final viewPadding = mediaQuery.padding;

    const popupWidth = 220.0;
    final popupHeight = (kShapeTools.length * 38.0) + 16.0;

    // Center horizontally on shape button, clamped strictly to viewport safe margins
    double left =
        buttonGlobalPos.dx + (buttonSize.width / 2.0) - (popupWidth / 2.0);
    final minLeft = viewPadding.left + 10.0;
    final maxLeft = screenSize.width - viewPadding.right - popupWidth - 10.0;
    left = left.clamp(minLeft, math.max(minLeft, maxLeft));

    // Dynamic vertical placement: prefer placing above the toolbar; if not enough space, place below or clamp safely
    final spaceAbove = buttonGlobalPos.dy - viewPadding.top;
    double top;
    if (spaceAbove >= popupHeight + 10.0) {
      top = buttonGlobalPos.dy - popupHeight - 8.0;
    } else {
      final spaceBelow =
          screenSize.height -
          (buttonGlobalPos.dy + buttonSize.height) -
          viewPadding.bottom;
      if (spaceBelow >= popupHeight + 10.0) {
        top = buttonGlobalPos.dy + buttonSize.height + 8.0;
      } else {
        top = (buttonGlobalPos.dy - popupHeight - 8.0).clamp(
          viewPadding.top + 8.0,
          math.max(
            viewPadding.top + 8.0,
            screenSize.height - viewPadding.bottom - popupHeight - 8.0,
          ),
        );
      }
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    _shapesOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Transparent barrier to dismiss popup on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideShapesPopup,
                onSecondaryTap: _hideShapesPopup,
                child: const SizedBox.expand(),
              ),
            ),
            // Custom Simple Shapes Popup Card
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: popupWidth,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withValues(
                      alpha: isDark ? 0.98 : 0.96,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(
                        alpha: isDark ? 0.35 : 0.45,
                      ),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.45 : 0.15,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4.0),
                  child: M3ESegmentedList(
                    itemCount: kShapeTools.length,
                    outerRadius: 10.0,
                    innerRadius: 4.0,
                    selectedRadius: 12.0,
                    selectedBorderRadius: BorderRadius.circular(12.0),
                    gap: 2.0,
                    color: Colors.transparent,
                    selectedColor: colorScheme.primary.withValues(alpha: 0.14),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: M3ESegmentedListDecoration(
                      outerRadius: 10.0,
                      innerRadius: 4.0,
                      selectedRadius: 12.0,
                      selectedBorderRadius: BorderRadius.circular(10.0),
                      gap: 2.0,
                      border: BorderSide.none,
                      selectedBorder: BorderSide.none,
                      elevation: 0.0,
                      selectedColor: colorScheme.primary.withValues(
                        alpha: 0.14,
                      ),
                      showSelectionCheckmark: false,
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                    ),
                    isSelected: (index) =>
                        widget.currentMode == kShapeTools[index].mode,
                    onTap: (index) {
                      final tool = kShapeTools[index];
                      setState(() {
                        _activeShapeMode = tool.mode;
                      });
                      widget.onModeChanged(tool.mode);
                      _hideShapesPopup();
                    },
                    itemBuilder: (context, index) {
                      final tool = kShapeTools[index];
                      final isSelected = widget.currentMode == tool.mode;
                      return _buildShapePopupItem(
                        tool,
                        isSelected,
                        colorScheme,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_shapesOverlayEntry!);
  }

  Widget _buildShapePopupItem(
    ShapeToolOption tool,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(
          tool.icon,
          size: 18,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tool.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tool.shortcut,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currentShapeItem = kShapeTools.firstWhere(
      (item) => item.mode == _activeShapeMode,
      orElse: () => kShapeTools.first,
    );
    final isAnyShapeActive = _shapeModes.contains(widget.currentMode);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EFabHorizontalFloatingToolbar(
        floatingActionButton: M3EFloatingActionButton(
          elevation: 0,
          onPressed: widget.onExportSvg,
          tooltip: 'Export SVG (⌘E)',
          child: const Icon(RemixIcons.download_line),
        ),
        expanded: true,
        decoration: M3EFloatingToolbarDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          colors: M3EFloatingToolbarColors(
            toolbarContainerColor: colorScheme.surfaceContainerHigh.withValues(
              alpha: isDark ? 0.92 : 0.96,
            ),
            toolbarContentColor: colorScheme.onSurface,
            fabContainerColor: colorScheme.primaryContainer,
            fabContentColor: colorScheme.onPrimaryContainer,
          ),
          expandedShadowElevation: 0,
          collapsedShadowElevation: 0,
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigation Tools
            _buildDockToolBtn(
              icon: RemixIcons.cursor_line,
              mode: EditorMode.select,
              tooltip: 'Select Tool (V)',
            ),
            _buildDockToolBtn(
              icon: LucideIcons.hand,
              mode: EditorMode.pan,
              tooltip: 'Hand / Pan Canvas (H / Space+Drag)',
            ),
            const SizedBox(width: 4),
            _buildToolDivider(colorScheme),
            const SizedBox(width: 4),

            // Single Shapes Tool in Dock
            _buildShapeDockBtn(
              currentShapeItem: currentShapeItem,
              isAnyShapeActive: isAnyShapeActive,
              colorScheme: colorScheme,
            ),

            // Vector Pen Tool
            _buildDockToolBtn(
              icon: RemixIcons.pen_nib_line,
              mode: EditorMode.drawPen,
              tooltip: 'Pen Tool (P)',
            ),
            const SizedBox(width: 4),
            _buildToolDivider(colorScheme),
            const SizedBox(width: 4),

            // Typography
            _buildDockToolBtn(
              icon: RemixIcons.t_box_line,
              mode: EditorMode.drawText,
              tooltip: 'Text Tool (T)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolDivider(ColorScheme colorScheme) {
    return Container(
      width: 1.0,
      height: 20.0,
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }

  Widget _buildDockToolBtn({
    required IconData icon,
    required EditorMode mode,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = widget.currentMode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: M3EButton(
            onPressed: () => widget.onModeChanged(mode),
            style: isActive ? M3EButtonStyle.filled : M3EButtonStyle.text,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
            decoration: M3EButtonDecoration(
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (isActive) return colorScheme.primary;
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (isActive) return colorScheme.onPrimary;
                return colorScheme.onSurfaceVariant;
              }),
            ),
            child: Icon(
              icon,
              size: 17,
              color: isActive ? colorScheme.onPrimary : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeDockBtn({
    required ShapeToolOption currentShapeItem,
    required bool isAnyShapeActive,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      key: _shapeButtonKey,
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Tooltip(
        message:
            '${currentShapeItem.label} Tool (${currentShapeItem.shortcut}) - Long-press for Shapes',
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onLongPress: _toggleShapesPopup,
          onSecondaryTap: _toggleShapesPopup,
          child: Container(
            decoration: BoxDecoration(
              color: isAnyShapeActive
                  ? colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: M3EButton(
              onPressed: () {
                if (widget.currentMode == currentShapeItem.mode) {
                  _toggleShapesPopup();
                } else {
                  widget.onModeChanged(currentShapeItem.mode);
                }
              },
              style: isAnyShapeActive
                  ? M3EButtonStyle.filled
                  : M3EButtonStyle.text,
              size: M3EButtonSize.sm,
              shape: M3EButtonShape.round,
              decoration: M3EButtonDecoration(
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (isAnyShapeActive) return colorScheme.primary;
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (isAnyShapeActive) return colorScheme.onPrimary;
                  return colorScheme.onSurfaceVariant;
                }),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentShapeItem.icon,
                    size: 17,
                    color: isAnyShapeActive ? colorScheme.onPrimary : null,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    RemixIcons.arrow_down_s_fill,
                    size: 11,
                    color: isAnyShapeActive
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
