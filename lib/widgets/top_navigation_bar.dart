import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/theme/components/responsive_layout_tokens.dart';
import 'package:remixicon/remixicon.dart';

class TopNavigationBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final barHeight = ResponsiveLayoutTokens.getTopBarHeight(context);

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Expressive M3 Brand Badge using M3EContainer from flutter_m3shapes_extended
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  RemixIcons.shapes_line,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'nixSVG',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Expressive M3 File Name Input
            _FileNameField(
              fileName: fileName,
              onFileNameChanged: onFileNameChanged,
            ),

            const SizedBox(width: 16),

            // Undo / Redo M3EButtons
            M3EButton(
              onPressed: canUndo ? onUndo : null,
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              tooltip: 'Undo (Ctrl+Z)',
              child: Icon(
                RemixIcons.arrow_go_back_line,
                size: 18,
                color: canUndo
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(width: 6),
            M3EButton(
              onPressed: canRedo ? onRedo : null,
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              tooltip: 'Redo (Ctrl+Y)',
              child: Icon(
                RemixIcons.arrow_go_forward_line,
                size: 18,
                color: canRedo
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
            ),

            const VerticalDivider(indent: 14, endIndent: 14, width: 24),

            // Snap to Grid FilterChip (showCheckmark: false explicitly preserved)
            FilterChip(
              selected: snapToGrid,
              showCheckmark: false,
              avatar: Icon(
                RemixIcons.grid_line,
                size: 16,
                color: snapToGrid
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              label: Text(
                'Snap Grid',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: snapToGrid ? FontWeight.bold : FontWeight.w500,
                  color: snapToGrid
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerHigh,
              selectedColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: snapToGrid
                      ? Colors.transparent
                      : colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onSelected: onSnapToGridChanged,
            ),

            const SizedBox(width: 12),

            // Zoom Controls Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Zoom Out',
                    child: InkWell(
                      onTap: onZoomOut,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          RemixIcons.subtract_line,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Zoom Presets',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: colorScheme.surfaceContainerHigh,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(zoomScale * 100).round()}%',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
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
                  Tooltip(
                    message: 'Zoom In',
                    child: InkWell(
                      onTap: onZoomIn,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          RemixIcons.add_line,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (onToggleLayers != null) ...[
              const SizedBox(width: 12),
              M3EButton(
                onPressed: () => onToggleLayers!(!showLayers),
                style: showLayers ? M3EButtonStyle.tonal : M3EButtonStyle.text,
                size: M3EButtonSize.sm,
                tooltip: showLayers ? 'Hide Layers Panel' : 'Show Layers Panel',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      RemixIcons.stack_line,
                      size: 18,
                      color: showLayers
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Layers',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (onToggleProperties != null) ...[
              const SizedBox(width: 6),
              M3EButton(
                onPressed: () => onToggleProperties!(!showProperties),
                style: showProperties
                    ? M3EButtonStyle.tonal
                    : M3EButtonStyle.text,
                size: M3EButtonSize.sm,
                tooltip: showProperties
                    ? 'Hide Properties Panel'
                    : 'Show Properties Panel',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      RemixIcons.sound_module_line,
                      size: 18,
                      color: showProperties
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Properties',
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(width: 16),

            // Import Image M3EButton
            M3EButton.icon(
              onPressed: onImportImage,
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              icon: Icon(
                RemixIcons.image_add_line,
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
              label: Text(
                'Import Image',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Dynamic Theme Seed Color Selector Menu
            PopupMenuButton<Color>(
              tooltip: 'Dynamic Theme Palette',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              color: colorScheme.surfaceContainerHigh,
              icon: Icon(
                RemixIcons.palette_line,
                color: colorScheme.primary,
                size: 20,
              ),
              onSelected: (color) => themeController.setSeedColor(color),
              itemBuilder: (context) {
                return ThemeController.themePresets.map((color) {
                  final isSelected =
                      themeController.seedColor.toARGB32() == color.toARGB32();
                  return PopupMenuItem<Color>(
                    value: color,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
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
                        const SizedBox(width: 12),
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

            // Light / Dark Theme Mode Toggle M3EButton
            M3EButton(
              onPressed: () => themeController.toggleThemeMode(),
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              tooltip: themeController.isDarkMode
                  ? 'Switch to Light Theme'
                  : 'Switch to Dark Theme',
              child: Icon(
                themeController.isDarkMode
                    ? RemixIcons.sun_line
                    : RemixIcons.moon_line,
                size: 18,
                color: colorScheme.onSecondaryContainer,
              ),
            ),

            const SizedBox(width: 8),

            // Shortcuts info button M3EButton
            M3EButton(
              onPressed: onShowShortcuts,
              style: M3EButtonStyle.outlined,
              size: M3EButtonSize.sm,
              tooltip: 'Keyboard Shortcuts',
              child: Icon(
                RemixIcons.keyboard_line,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),

            // Clear Canvas button M3EButton
            M3EButton(
              onPressed: onClearCanvas,
              style: M3EButtonStyle.tonal,
              size: M3EButtonSize.sm,
              tooltip: 'Clear Canvas',
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
                size: 18,
                color: colorScheme.onErrorContainer,
              ),
            ),

            const SizedBox(width: 12),

            // Export SVG M3EButton
            M3EButton.icon(
              onPressed: onExportSvg,
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.sm,
              icon: Icon(
                RemixIcons.download_line,
                size: 18,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Export SVG',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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

class _FileNameField extends StatefulWidget {
  final String fileName;
  final ValueChanged<String> onFileNameChanged;

  const _FileNameField({
    required this.fileName,
    required this.onFileNameChanged,
  });

  @override
  State<_FileNameField> createState() => _FileNameFieldState();
}

class _FileNameFieldState extends State<_FileNameField> {
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
  void didUpdateWidget(covariant _FileNameField oldWidget) {
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
    final textTheme = theme.textTheme;

    return SizedBox(
      width: 160,
      height: 38,
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
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintText: 'Untitled.svg',
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

