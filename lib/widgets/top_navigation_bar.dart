import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/providers/theme_provider.dart';
import 'package:nixsvg/theme/components/responsive_layout_tokens.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';
import 'package:nixsvg/widgets/context_menu/figma_context_menu.dart';
import 'package:remixicon/remixicon.dart';

/// Pure Material 3 Expressive Navigation Toolbar for nixSVG.
/// Adheres strictly to Material 3 Expressive motion and design specifications,
/// featuring tonal surface containers, physics-based spring interactions,
/// and responsive layout adaptation.
class TopNavigationBar extends ConsumerWidget {
  final String fileName;
  final ValueChanged<String> onFileNameChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final bool snapToGrid;
  final ValueChanged<bool> onSnapToGridChanged;
  final VoidCallback onExportSvg;
  final VoidCallback onImportImage;
  final Function(PathOperation op)? onBooleanOperation;
  final int selectedShapesCount;
  final VoidCallback onClearCanvas;
  final VoidCallback onShowShortcuts;
  final VoidCallback? onOpenSettings;
  final double zoomScale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback? onZoomToFit;
  final VoidCallback? onZoomToSelection;
  final bool showLayers;
  final ValueChanged<bool>? onToggleLayers;
  final bool showProperties;
  final ValueChanged<bool>? onToggleProperties;
  final VoidCallback? onGoToHome;

  const TopNavigationBar({
    super.key,
    required this.fileName,
    required this.onFileNameChanged,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.snapToGrid,
    required this.onSnapToGridChanged,
    required this.onExportSvg,
    required this.onImportImage,
    this.onBooleanOperation,
    this.selectedShapesCount = 0,
    required this.onClearCanvas,
    required this.onShowShortcuts,
    this.onOpenSettings,
    required this.zoomScale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    this.onZoomToFit,
    this.onZoomToSelection,
    this.showLayers = true,
    this.onToggleLayers,
    this.showProperties = true,
    this.onToggleProperties,
    this.onGoToHome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = themeState.isDarkMode;
    final barHeight = ResponsiveLayoutTokens.getTopBarHeight(context);

    return Container(
      width: double.infinity,
      height: barHeight,
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
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.max(
                  0.0,
                  constraints.maxWidth.isFinite
                      ? constraints.maxWidth - 16
                      : 0.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ================= LEFT ZONE =================
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- App Brand Logo & Title with Home Action ---
                      M3PhysicsPressable(
                        tooltip: onGoToHome != null
                            ? 'Back to Home Screen'
                            : 'nixSVG Vector Studio',
                        onTap: onGoToHome,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  RemixIcons.shapes_line,
                                  color: colorScheme.onPrimary,
                                  size: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'nixSVG',
                                style: textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (onGoToHome != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  RemixIcons.home_4_line,
                                  size: 13,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // --- Material 3 Expressive Document Title Capsule ---
                      _M3EDocumentCapsule(
                        fileName: fileName,
                        onFileNameChanged: onFileNameChanged,
                        onExportSvg: onExportSvg,
                        onOpenSettings: onOpenSettings,
                      ),

                      const SizedBox(width: 6),

                      // --- History Segmented Pill (Undo / Redo) ---
                      _M3EPillContainer(
                        children: [
                          _M3EIconButton(
                            icon: RemixIcons.arrow_go_back_line,
                            tooltip: 'Undo (Ctrl+Z)',
                            enabled: canUndo,
                            onTap: onUndo,
                          ),
                          _buildInnerDivider(colorScheme),
                          _M3EIconButton(
                            icon: RemixIcons.arrow_go_forward_line,
                            tooltip: 'Redo (Ctrl+Shift+Z)',
                            enabled: canRedo,
                            onTap: onRedo,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ================= CENTER ZONE =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- Snap to Grid Toggle Pill ---
                        _M3ETogglePill(
                          selected: snapToGrid,
                          icon: RemixIcons.grid_line,
                          label: 'Snap',
                          tooltip: 'Toggle Snap to Grid',
                          onTap: () => onSnapToGridChanged(!snapToGrid),
                        ),

                        if (selectedShapesCount >= 2 &&
                            onBooleanOperation != null) ...[
                          const SizedBox(width: 6),
                          PopupMenuButton<PathOperation>(
                            tooltip: 'Boolean Vector Operations',
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            color: colorScheme.surfaceContainerHigh,
                            elevation: 3,
                            onSelected: onBooleanOperation,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: PathOperation.union,
                                child: Row(
                                  children: [
                                    Icon(
                                      RemixIcons.shape_line,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Boolean Union (⌥⌘U)'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: PathOperation.difference,
                                child: Row(
                                  children: [
                                    Icon(
                                      RemixIcons.subtract_line,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Boolean Subtract (⌥⌘S)'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: PathOperation.intersect,
                                child: Row(
                                  children: [
                                    Icon(
                                      RemixIcons.shape_2_line,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Boolean Intersect (⌥⌘I)'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: PathOperation.xor,
                                child: Row(
                                  children: [
                                    Icon(
                                      RemixIcons.contrast_line,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Boolean Exclude (⌥⌘X)'),
                                  ],
                                ),
                              ),
                            ],
                            child: _M3EPillContainer(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              children: [
                                Icon(
                                  RemixIcons.shape_line,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Boolean',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  RemixIcons.arrow_down_s_line,
                                  size: 13,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(width: 6),

                        // --- Zoom Controls Segmented Pill ---
                        _M3EPillContainer(
                          children: [
                            _M3EIconButton(
                              icon: RemixIcons.subtract_line,
                              tooltip: 'Zoom Out',
                              enabled: true,
                              onTap: onZoomOut,
                            ),
                            _buildInnerDivider(colorScheme),
                            PopupMenuButton<String>(
                              tooltip: 'Zoom Presets',
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              color: colorScheme.surfaceContainerHigh,
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(zoomScale * 100).round()}%',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      RemixIcons.arrow_down_s_line,
                                      size: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                              onSelected: (val) {
                                switch (val) {
                                  case 'reset':
                                    onResetZoom();
                                    break;
                                  case 'fit':
                                    onZoomToFit?.call();
                                    break;
                                  case 'selection':
                                    onZoomToSelection?.call();
                                    break;
                                  case 'in':
                                    onZoomIn();
                                    break;
                                  case 'out':
                                    onZoomOut();
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'reset',
                                  child: Text('Zoom to 100% (Ctrl+0)'),
                                ),
                                if (onZoomToFit != null)
                                  const PopupMenuItem(
                                    value: 'fit',
                                    child: Text('Zoom to Fit (Shift+1)'),
                                  ),
                                if (onZoomToSelection != null)
                                  const PopupMenuItem(
                                    value: 'selection',
                                    child: Text('Zoom to Selection (Shift+2)'),
                                  ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'in',
                                  child: Text('Zoom In (Ctrl++)'),
                                ),
                                const PopupMenuItem(
                                  value: 'out',
                                  child: Text('Zoom Out (Ctrl+-)'),
                                ),
                              ],
                            ),
                            _buildInnerDivider(colorScheme),
                            _M3EIconButton(
                              icon: RemixIcons.add_line,
                              tooltip: 'Zoom In',
                              enabled: true,
                              onTap: onZoomIn,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ================= RIGHT ZONE =================
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Sidebar Panel Toggles Segmented Pill ---
                      if (onToggleLayers != null ||
                          onToggleProperties != null) ...[
                        _M3EPillContainer(
                          children: [
                            if (onToggleLayers != null)
                              _M3EPanelToggleButton(
                                icon: RemixIcons.stack_line,
                                label: 'Layers',
                                active: showLayers,
                                tooltip: showLayers
                                    ? 'Hide Layers Panel'
                                    : 'Show Layers Panel',
                                onTap: () => onToggleLayers!(!showLayers),
                              ),

                            const SizedBox(width: 2),
                            if (onToggleLayers != null &&
                                onToggleProperties != null)
                              _buildInnerDivider(colorScheme),
                            if (onToggleProperties != null)
                              _M3EPanelToggleButton(
                                icon: RemixIcons.sound_module_line,
                                label: 'Inspector',
                                active: showProperties,
                                tooltip: showProperties
                                    ? 'Hide Properties Panel'
                                    : 'Show Properties Panel',
                                onTap: () =>
                                    onToggleProperties!(!showProperties),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                      ],

                      // --- Dynamic Theme & Utility Pill ---
                      _M3EPillContainer(
                        children: [
                          // Dynamic Seed Color Selector Menu
                          PopupMenuButton<Color>(
                            tooltip: 'Dynamic Theme Color',
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            color: colorScheme.surfaceContainerHigh,
                            icon: SizedBox(
                              width: 22,
                              height: 22,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    RemixIcons.palette_line,
                                    color: colorScheme.primary,
                                    size: 16,
                                  ),
                                  Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: themeState.seedColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colorScheme.surfaceContainerHigh,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onSelected: (color) {
                              ref
                                  .read(themeProvider.notifier)
                                  .setSeedColor(color);
                            },
                            itemBuilder: (context) {
                              return ThemeController.themePresets.map((color) {
                                final isSelected =
                                    themeState.seedColor.toARGB32() ==
                                    color.toARGB32();
                                return PopupMenuItem<Color>(
                                  value: color,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? colorScheme.onSurface
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _getColorName(color),
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          ),

                          _buildInnerDivider(colorScheme),

                          // Light / Dark Theme Mode Toggle
                          _M3EIconButton(
                            icon: themeState.isDarkMode
                                ? RemixIcons.sun_line
                                : RemixIcons.moon_line,
                            tooltip: themeState.isDarkMode
                                ? 'Light Theme'
                                : 'Dark Theme',
                            enabled: true,
                            onTap: () {
                              ref
                                  .read(themeProvider.notifier)
                                  .toggleThemeMode();
                            },
                          ),

                          _buildInnerDivider(colorScheme),

                          // Keyboard Shortcuts
                          _M3EIconButton(
                            icon: RemixIcons.keyboard_line,
                            tooltip: 'Keyboard Shortcuts (?)',
                            enabled: true,
                            onTap: onShowShortcuts,
                          ),
                        ],
                      ),

                      const SizedBox(width: 6),

                      // --- Canvas Management Group ---
                      _M3EIconButton(
                        icon: RemixIcons.delete_bin_line,
                        tooltip: 'Clear Canvas',
                        enabled: true,
                        color: colorScheme.error,
                        onTap: onClearCanvas,
                      ),

                      const SizedBox(width: 5),

                      // Import Image Button
                      Tooltip(
                        message: 'Import bitmap image or SVG',
                        waitDuration: const Duration(milliseconds: 500),
                        child: M3EButton.icon(
                          onPressed: onImportImage,
                          style: M3EButtonStyle.tonal,
                          size: M3EButtonSize.sm,
                          icon: Icon(
                            RemixIcons.image_add_line,
                            size: 15,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          label: Text(
                            'Import',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 5),

                      // --- Primary Action: Export SVG ---
                      Tooltip(
                        message: 'Export project to SVG',
                        waitDuration: const Duration(milliseconds: 500),
                        child: M3EButton.icon(
                          onPressed: onExportSvg,
                          style: M3EButtonStyle.filled,
                          size: M3EButtonSize.sm,
                          icon: Icon(
                            RemixIcons.download_line,
                            size: 15,
                            color: colorScheme.onPrimary,
                          ),
                          label: Text(
                            'Export SVG',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInnerDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 18,
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
    );
  }

  String _getColorName(Color color) {
    if (color.toARGB32() == Colors.indigo.toARGB32()) return 'Blue';
    if (color.toARGB32() == Colors.green.toARGB32()) {
      return 'Emerald';
    }
    if (color.toARGB32() == Colors.blue.toARGB32()) return 'Blue';
    if (color.toARGB32() == Colors.green.toARGB32()) return 'Violet';
    if (color.toARGB32() == Colors.amber.toARGB32()) return 'Amber';
    if (color.toARGB32() == Colors.pink.toARGB32()) return 'Pink';
    if (color.toARGB32() == Colors.red.toARGB32()) return 'Rose';
    return 'Dynamic Seed';
  }
}

/// Material 3 Expressive Container grouping related segmented actions.
class _M3EPillContainer extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const _M3EPillContainer({required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 30,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
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
  final Color? color;

  const _M3EIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.color,
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
              ? (color ?? colorScheme.onSurface)
              : colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/// Material 3 Expressive Toggle Pill (e.g. Snap to Grid).
class _M3ETogglePill extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _M3ETogglePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return M3PhysicsPressable(
      tooltip: tooltip,
      onTap: onTap,
      enableHoverHighlight: !selected,
      borderRadius: BorderRadius.circular(19),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Material 3 Expressive Panel Toggle Button inside a Segmented Pill.
class _M3EPanelToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _M3EPanelToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return M3PhysicsPressable(
      tooltip: tooltip,
      onTap: onTap,
      enableHoverHighlight: !active,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: active ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: active
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Material 3 Expressive Document Title Capsule with document icon, inline edit,
/// and Figma/macOS desktop context menu on right-click / two-finger press.
class _M3EDocumentCapsule extends StatefulWidget {
  final String fileName;
  final ValueChanged<String> onFileNameChanged;
  final VoidCallback? onExportSvg;
  final VoidCallback? onOpenSettings;

  const _M3EDocumentCapsule({
    required this.fileName,
    required this.onFileNameChanged,
    this.onExportSvg,
    this.onOpenSettings,
  });

  @override
  State<_M3EDocumentCapsule> createState() => _M3EDocumentCapsuleState();
}

class _M3EDocumentCapsuleState extends State<_M3EDocumentCapsule> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.fileName);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_controller.text.trim().isNotEmpty &&
            _controller.text.trim() != widget.fileName) {
          widget.onFileNameChanged(_controller.text.trim());
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _M3EDocumentCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _controller.text != widget.fileName) {
      _controller.text = widget.fileName;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showDocumentContextMenu(Offset globalPos) {
    showFigmaContextMenu(
      context: context,
      globalPosition: globalPos,
      items: [
        FigmaMenuItem(
          label: 'Rename Document',
          icon: RemixIcons.edit_line,
          shortcut: 'Enter',
          onTap: () {
            _focusNode.requestFocus();
            _controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controller.text.length,
            );
          },
        ),
        if (widget.onExportSvg != null)
          FigmaMenuItem(
            label: 'Export SVG...',
            icon: RemixIcons.download_line,
            shortcut: '⌘E',
            onTap: widget.onExportSvg,
          ),
        if (widget.onOpenSettings != null) ...[
          const FigmaMenuDivider(),
          FigmaMenuItem(
            label: 'Document Settings...',
            icon: RemixIcons.settings_3_line,
            shortcut: '⌘,',
            onTap: widget.onOpenSettings,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) =>
          _showDocumentContextMenu(details.globalPosition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focusNode.hasFocus
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: _focusNode.hasFocus ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              RemixIcons.file_edit_line,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 70, maxWidth: 170),
              child: IntrinsicWidth(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      widget.onFileNameChanged(val.trim());
                    }
                    _focusNode.unfocus();
                  },
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Untitled',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '.svg',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
