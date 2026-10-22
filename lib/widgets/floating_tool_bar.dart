import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_floating_toolbar/m3e_floating_toolbar.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';
import 'package:remixicon/remixicon.dart';

class FloatingToolBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: M3EFabHorizontalFloatingToolbar(
        floatingActionButton: M3EFloatingActionButton(
          elevation: 0,
          onPressed: onExportSvg,
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
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.cursor_line,
              mode: EditorMode.select,
              tooltip: 'Select Tool (V)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: LucideIcons.hand,
              mode: EditorMode.pan,
              tooltip: 'Hand / Pan Canvas (H / Space+Drag)',
            ),
            const SizedBox(width: 4),
            _buildToolDivider(colorScheme),
            const SizedBox(width: 4),

            // Vector Primitives
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.checkbox_blank_line,
              mode: EditorMode.drawRectangle,
              tooltip: 'Rectangle Tool (R)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.rectangle_line,
              mode: EditorMode.drawRoundedRectangle,
              tooltip: 'Rounded Rectangle Tool (U)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.checkbox_blank_circle_line,
              mode: EditorMode.drawEllipse,
              tooltip: 'Ellipse / Circle Tool (O)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: LucideIcons.minus,
              mode: EditorMode.drawLine,
              tooltip: 'Line Tool (L)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: LucideIcons.spline,
              mode: EditorMode.drawCurve,
              tooltip: 'Curve / Bend Tool (C)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.star_line,
              mode: EditorMode.drawStar,
              tooltip: 'Star Tool (S)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.hexagon_line,
              mode: EditorMode.drawPolygon,
              tooltip: 'Polygon Tool (Y)',
            ),
            const SizedBox(width: 4),
            _buildToolDivider(colorScheme),
            const SizedBox(width: 4),

            // Typography
            _buildExpressiveToolBtn(
              context,
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

  Widget _buildExpressiveToolBtn(
    BuildContext context, {
    required IconData icon,
    required EditorMode mode,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = currentMode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: M3PhysicsPressable(
        tooltip: tooltip,
        onTap: () => onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.fastOutSlowIn,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: M3EButton(
            onPressed: () => onModeChanged(mode),
            style: isActive ? M3EButtonStyle.filled : M3EButtonStyle.text,
            size: M3EButtonSize.sm,
            decoration: M3EButtonDecoration(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (isActive) return colorScheme.primary;
                if (states.contains(WidgetState.hovered)) {
                  return colorScheme.surfaceContainerHighest;
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (isActive) return colorScheme.onPrimary;
                if (states.contains(WidgetState.hovered)) {
                  return colorScheme.onSurface;
                }
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
}
