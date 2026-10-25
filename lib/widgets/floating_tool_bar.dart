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
  final ScrollController _toolbarScrollController = ScrollController();
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
    if (widget.currentMode != oldWidget.currentMode) {
      _shapesOverlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _hideShapesPopup();
    _toolbarScrollController.dispose();
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

    _shapesOverlayEntry = OverlayEntry(
      builder: (context) {
        return _ShapesPopupOverlayWidget(
          buttonKey: _shapeButtonKey,
          scrollController: _toolbarScrollController,
          currentMode: widget.currentMode,
          onDismiss: _hideShapesPopup,
          onSelectMode: (mode) {
            setState(() {
              _activeShapeMode = mode;
            });
            widget.onModeChanged(mode);
            _hideShapesPopup();
          },
        );
      },
    );

    Overlay.of(context).insert(_shapesOverlayEntry!);
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

    // Ensure popup dynamically recalculates its position if toolbar rebuilds or moves
    if (_shapesOverlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shapesOverlayEntry != null) {
          _shapesOverlayEntry!.markNeedsBuild();
        }
      });
    }

    return SingleChildScrollView(
      controller: _toolbarScrollController,
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
          child: Stack(
            children: [
              M3EButton(
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
                child: Icon(
                  currentShapeItem.icon,
                  size: 17,
                  color: isAnyShapeActive ? colorScheme.onPrimary : null,
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Icon(
                  RemixIcons.arrow_down_s_fill,
                  size: 12,
                  color: isAnyShapeActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShapesPopupOverlayWidget extends StatefulWidget {
  final GlobalKey buttonKey;
  final VoidCallback onDismiss;
  final EditorMode currentMode;
  final ValueChanged<EditorMode> onSelectMode;
  final ScrollController? scrollController;

  const _ShapesPopupOverlayWidget({
    required this.buttonKey,
    required this.onDismiss,
    required this.currentMode,
    required this.onSelectMode,
    this.scrollController,
  });

  @override
  State<_ShapesPopupOverlayWidget> createState() =>
      _ShapesPopupOverlayWidgetState();
}

class _ShapesPopupOverlayWidgetState extends State<_ShapesPopupOverlayWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _ShapesPopupOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Re-query anchor button coordinates after layout finishes for new window size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
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
    // 1. Dependency on MediaQuery ensures rebuild on window resize / orientation / padding change
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final viewPadding = mediaQuery.padding;

    // 2. Query anchor button RenderBox
    final renderBox =
        widget.buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox.shrink();
    }

    // 3. Compute accurate global coordinates
    // Using size.center handles any ancestor Transform.scale automatically
    final buttonCenter =
        renderBox.localToGlobal(renderBox.size.center(Offset.zero));
    final buttonTopLeft = renderBox.localToGlobal(Offset.zero);
    final buttonBottomRight = renderBox.localToGlobal(
      Offset(renderBox.size.width, renderBox.size.height),
    );

    final buttonVisualTop = math.min(buttonTopLeft.dy, buttonBottomRight.dy);
    final buttonVisualBottom = math.max(buttonTopLeft.dy, buttonBottomRight.dy);

    // 4. Dynamic sizing calculation
    const double desiredPopupWidth = 220.0;
    final double maxAllowedWidth =
        screenSize.width - viewPadding.left - viewPadding.right - 16.0;
    final double popupWidth = desiredPopupWidth.clamp(
      160.0,
      math.max(160.0, maxAllowedWidth),
    );

    const double itemHeight = 38.0;
    const double paddingHeight = 16.0;
    final double idealPopupHeight =
        (kShapeTools.length * itemHeight) + paddingHeight;

    // Available spaces above and below
    final double spaceAbove = buttonVisualTop - viewPadding.top - 8.0;
    final double spaceBelow =
        screenSize.height - buttonVisualBottom - viewPadding.bottom - 8.0;

    // Decide whether to place above or below
    final bool placeAbove = (spaceAbove >= idealPopupHeight) ||
        (spaceAbove >= spaceBelow && spaceAbove >= 120.0);

    final double availableSpace = placeAbove ? spaceAbove : spaceBelow;
    final double maxPopupHeight = math.min(
      idealPopupHeight,
      math.max(100.0, availableSpace),
    );

    // 5. Position calculations
    double top;
    if (placeAbove) {
      top = buttonVisualTop - maxPopupHeight - 8.0;
    } else {
      top = buttonVisualBottom + 8.0;
    }

    final double minTop = viewPadding.top + 8.0;
    final double maxTop = math.max(
      minTop,
      screenSize.height - viewPadding.bottom - maxPopupHeight - 8.0,
    );
    top = top.clamp(minTop, maxTop);

    double left = buttonCenter.dx - (popupWidth / 2.0);
    final double minLeft = viewPadding.left + 8.0;
    final double maxLeft = math.max(
      minLeft,
      screenSize.width - viewPadding.right - popupWidth - 8.0,
    );
    left = left.clamp(minLeft, maxLeft);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Transparent barrier to dismiss popup on tap outside
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
            onSecondaryTap: widget.onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        // Custom Dynamic Shapes Popup Card
        Positioned(
          left: left,
          top: top,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.92, end: 1.0),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                alignment: placeAbove
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: popupWidth,
                constraints: BoxConstraints(
                  maxHeight: maxPopupHeight,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(
                    alpha: isDark ? 0.98 : 0.96,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4.0),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: M3ESegmentedList(
                    itemCount: kShapeTools.length,
                    outerRadius: 10.0,
                    innerRadius: 10.0,
                    selectedRadius: 10.0,
                    selectedBorderRadius: BorderRadius.circular(10.0),
                    pressedScale: 1.0,
                    gap: 2.0,
                    color: Colors.transparent,
                    selectedColor: colorScheme.primary.withValues(alpha: 0.14),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: M3ESegmentedListDecoration(
                      outerRadius: 10.0,
                      innerRadius: 10.0,
                      selectedRadius: 10.0,
                      selectedBorderRadius: BorderRadius.circular(10.0),
                      pressedRadius: 10.0,
                      pressedScale: 1.0,
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
                      widget.onSelectMode(tool.mode);
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
          ),
        ),
      ],
    );
  }
}

