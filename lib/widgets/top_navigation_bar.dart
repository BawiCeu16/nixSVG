import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/providers/theme_provider.dart';
import 'package:nixsvg/theme/components/responsive_layout_tokens.dart';
import 'package:remixicon/remixicon.dart';

/// Redesigned macOS Unified Toolbar aesthetic for nixSVG.
/// Features frosted glassmorphism, authentic traffic light window controls,
/// document title capsule, connected macOS segmented pill clusters, and dynamic responsiveness.
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
  final VoidCallback onClearCanvas;
  final VoidCallback onShowShortcuts;
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
    required this.onClearCanvas,
    required this.onShowShortcuts,
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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = themeState.isDarkMode;
    final barHeight = ResponsiveLayoutTokens.getTopBarHeight(context);

    return SizedBox(
      width: double.infinity,
      height: barHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            height: barHeight,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: isDark ? 0.78 : 0.88),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.25 : 0.35,
                  ),
                  width: 0.8,
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth - 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ================= LEFT ZONE =================
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- App Brand Logo & Title ---
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [colorScheme.primary, colorScheme.tertiary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    RemixIcons.shapes_line,
                                    color: colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'nixSVG',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 14),

                            // --- macOS Document Title Capsule ---
                            _MacDocumentCapsule(
                              fileName: fileName,
                              onFileNameChanged: onFileNameChanged,
                            ),

                            const SizedBox(width: 12),

                            // --- History Segmented Pill (Undo / Redo) ---
                            _MacPillContainer(
                              children: [
                                _MacIconButton(
                                  icon: RemixIcons.arrow_go_back_line,
                                  tooltip: 'Undo (Ctrl+Z)',
                                  enabled: canUndo,
                                  onTap: onUndo,
                                ),
                                _buildInnerDivider(colorScheme),
                                _MacIconButton(
                                  icon: RemixIcons.arrow_go_forward_line,
                                  tooltip: 'Redo (Ctrl+Y)',
                                  enabled: canRedo,
                                  onTap: onRedo,
                                ),
                              ],
                            ),
                          ],
                        ),

                        // ================= CENTER ZONE =================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // --- Snap to Grid Toggle Pill ---
                              _MacTogglePill(
                                selected: snapToGrid,
                                icon: RemixIcons.grid_line,
                                label: 'Snap',
                                tooltip: 'Toggle Snap to Grid',
                                onTap: () => onSnapToGridChanged(!snapToGrid),
                              ),

                              const SizedBox(width: 10),

                              // --- Zoom Controls Segmented Pill ---
                              _MacPillContainer(
                                children: [
                                  _MacIconButton(
                                    icon: RemixIcons.subtract_line,
                                    tooltip: 'Zoom Out',
                                    enabled: true,
                                    onTap: onZoomOut,
                                  ),
                                  _buildInnerDivider(colorScheme),
                                  PopupMenuButton<String>(
                                    tooltip: 'Zoom Presets',
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    color: colorScheme.surfaceContainerHigh,
                                    padding: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${(zoomScale * 100).round()}%',
                                            style: textTheme.labelMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            RemixIcons.arrow_down_s_line,
                                            size: 12,
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
                                  _MacIconButton(
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
                            if (onToggleLayers != null || onToggleProperties != null) ...[
                              _MacPillContainer(
                                children: [
                                  if (onToggleLayers != null)
                                    _MacPanelToggleButton(
                                      icon: RemixIcons.stack_line,
                                      label: 'Layers',
                                      active: showLayers,
                                      tooltip: showLayers
                                          ? 'Hide Layers Panel'
                                          : 'Show Layers Panel',
                                      onTap: () => onToggleLayers!(!showLayers),
                                    ),
                                  if (onToggleLayers != null && onToggleProperties != null)
                                    _buildInnerDivider(colorScheme),
                                  if (onToggleProperties != null)
                                    _MacPanelToggleButton(
                                      icon: RemixIcons.sound_module_line,
                                      label: 'Inspector',
                                      active: showProperties,
                                      tooltip: showProperties
                                          ? 'Hide Properties Panel'
                                          : 'Show Properties Panel',
                                      onTap: () => onToggleProperties!(!showProperties),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 10),
                            ],

                            // --- Dynamic Theme & Utility Pill ---
                            _MacPillContainer(
                              children: [
                                // Dynamic Seed Color Selector Menu
                                PopupMenuButton<Color>(
                                  tooltip: 'Dynamic Theme Color',
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: colorScheme.surfaceContainerHigh,
                                  icon: Icon(
                                    RemixIcons.palette_line,
                                    color: colorScheme.primary,
                                    size: 17,
                                  ),
                                  onSelected: (color) {
                                    ref.read(themeProvider.notifier).setSeedColor(color);
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
                                _MacIconButton(
                                  icon: themeState.isDarkMode
                                      ? RemixIcons.sun_line
                                      : RemixIcons.moon_line,
                                  tooltip: themeState.isDarkMode
                                      ? 'Light Theme'
                                      : 'Dark Theme',
                                  enabled: true,
                                  onTap: () {
                                    ref.read(themeProvider.notifier).toggleThemeMode();
                                  },
                                ),

                                _buildInnerDivider(colorScheme),

                                // Keyboard Shortcuts
                                _MacIconButton(
                                  icon: RemixIcons.keyboard_line,
                                  tooltip: 'Keyboard Shortcuts (?)',
                                  enabled: true,
                                  onTap: onShowShortcuts,
                                ),
                              ],
                            ),

                            const SizedBox(width: 10),

                            // --- Canvas Management Group ---
                            _MacIconButton(
                              icon: RemixIcons.delete_bin_line,
                              tooltip: 'Clear Canvas',
                              enabled: true,
                              color: colorScheme.error,
                              onTap: onClearCanvas,
                            ),

                            const SizedBox(width: 8),

                            // Import Image Button
                            M3EButton.icon(
                              onPressed: onImportImage,
                              style: M3EButtonStyle.tonal,
                              size: M3EButtonSize.sm,
                              icon: Icon(
                                RemixIcons.image_add_line,
                                size: 16,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              label: Text(
                                'Import',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // --- Primary Action: Export SVG ---
                            M3EButton.icon(
                              onPressed: onExportSvg,
                              style: M3EButtonStyle.filled,
                              size: M3EButtonSize.sm,
                              icon: Icon(
                                RemixIcons.download_line,
                                size: 16,
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
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildInnerDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  String _getColorName(Color color) {
    if (color.toARGB32() == const Color(0xFF6366F1).toARGB32()) return 'Indigo';
    if (color.toARGB32() == const Color(0xFF10B981).toARGB32()) {
      return 'Emerald';
    }
    if (color.toARGB32() == const Color(0xFF3B82F6).toARGB32()) return 'Blue';
    if (color.toARGB32() == const Color(0xFF8B5CF6).toARGB32()) return 'Violet';
    if (color.toARGB32() == const Color(0xFFEC4899).toARGB32()) return 'Pink';
    if (color.toARGB32() == const Color(0xFFF59E0B).toARGB32()) return 'Amber';
    if (color.toARGB32() == const Color(0xFF06B6D4).toARGB32()) return 'Cyan';
    if (color.toARGB32() == const Color(0xFFF43F5E).toARGB32()) return 'Rose';
    return 'Dynamic Seed';
  }
}

/// macOS Unified Pill Container grouping related segmented actions.
class _MacPillContainer extends StatelessWidget {
  final List<Widget> children;

  const _MacPillContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.65 : 0.85,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.45,
          ),
          width: 0.8,
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

/// macOS Icon button with subtle rounded hover styling.
class _MacIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final Color? color;

  const _MacIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? (color ?? colorScheme.onSurface)
                : colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// macOS Toggle Pill (e.g. Snap to Grid).
class _MacTogglePill extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _MacTogglePill({
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
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHigh.withValues(
                    alpha: isDark ? 0.65 : 0.85,
                  ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.35 : 0.45,
                    ),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// macOS Panel Toggle Button inside a Segmented Pill.
class _MacPanelToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _MacPanelToggleButton({
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

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: active
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// macOS Document Title Capsule with document icon and inline edit.
class _MacDocumentCapsule extends StatefulWidget {
  final String fileName;
  final ValueChanged<String> onFileNameChanged;

  const _MacDocumentCapsule({
    required this.fileName,
    required this.onFileNameChanged,
  });

  @override
  State<_MacDocumentCapsule> createState() => _MacDocumentCapsuleState();
}

class _MacDocumentCapsuleState extends State<_MacDocumentCapsule> {
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
  void didUpdateWidget(covariant _MacDocumentCapsule oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.5 : 0.65,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focusNode.hasFocus
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.35 : 0.45,
                ),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(RemixIcons.file_edit_line, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 70, maxWidth: 160),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '.svg',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
