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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: M3EFabHorizontalFloatingToolbar(
        floatingActionButton: M3EFloatingActionButton(
          elevation: 0,
          onPressed: onExportSvg,
          tooltip: 'Export SVG',
          child: const Icon(RemixIcons.download_line),
        ),
        expanded: true,
        decoration: M3EFloatingToolbarDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          colors: M3EFloatingToolbarColors(
            toolbarContainerColor: colorScheme.surfaceContainerHigh,
            toolbarContentColor: colorScheme.onSurface,
            fabContainerColor: colorScheme.primaryContainer,
            fabContentColor: colorScheme.onPrimaryContainer,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          expandedShadowElevation: 0,
          collapsedShadowElevation: 0,
        ),

        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.cursor_line,
              mode: EditorMode.select,
              tooltip: 'Select (V)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: LucideIcons.hand,
              mode: EditorMode.pan,
              tooltip: 'Hand / Pan (H)',
            ),
            const SizedBox(width: 8),
            VerticalDivider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),

              indent: 16.0,
              endIndent: 16.0,
            ),
            const SizedBox(width: 8),
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.checkbox_blank_line,
              mode: EditorMode.drawRectangle,
              tooltip: 'Rectangle (R)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.rectangle_line,
              mode: EditorMode.drawRoundedRectangle,
              tooltip: 'Rounded Rectangle (U)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: RemixIcons.checkbox_blank_circle_line,
              mode: EditorMode.drawEllipse,
              tooltip: 'Ellipse / Circle (O)',
            ),
            _buildExpressiveToolBtn(
              context,
              icon: LucideIcons.minus,
              mode: EditorMode.drawLine,
              tooltip: 'Line (L)',
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
              tooltip: 'Star / Polygon (S)',
            ),
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

  Widget _buildExpressiveToolBtn(
    BuildContext context, {
    required IconData icon,
    required EditorMode mode,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = currentMode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: M3PhysicsPressable(
        tooltip: tooltip,
        onTap: () => onModeChanged(mode),
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
            size: 20,
            color: isActive ? colorScheme.onPrimary : null,
          ),
        ),
      ),
    );
  }
}
