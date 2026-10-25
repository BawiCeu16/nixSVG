import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:remixicon/remixicon.dart';

class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final mod = isMac ? '⌘' : 'Ctrl';

    return AlertDialog(
      elevation: 0,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide.none,
      ),
      title: Row(
        children: [
          Icon(RemixIcons.keyboard_line, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            'Keyboard & Gesture Shortcuts',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShortcutCard(
                context,
                children: [
                  _buildShortcutRow(context, 'V', 'Selection Tool'),
                  _buildShortcutRow(context, 'H', 'Hand / Pan Canvas Tool'),
                  _buildShortcutRow(
                    context,
                    'Space / Mid-Click',
                    'Hold Spacebar or Middle-Click to Pan',
                  ),
                  _buildShortcutRow(context, 'R', 'Draw Rectangle Tool'),
                  _buildShortcutRow(context, 'U', 'Draw Rounded Rectangle Tool'),
                  _buildShortcutRow(context, 'O', 'Draw Ellipse / Circle Tool'),
                  _buildShortcutRow(
                    context,
                    'L',
                    'Draw Line Tool (Hold Shift for 45°)',
                  ),
                  _buildShortcutRow(context, 'C', 'Draw Curve / Bend Tool'),
                  _buildShortcutRow(
                    context,
                    'P',
                    'Vector Pen Tool (Click nodes or drag smooth path)',
                  ),
                  _buildShortcutRow(context, 'S', 'Draw Star Tool'),
                  _buildShortcutRow(context, 'Y', 'Draw Polygon Tool'),
                  _buildShortcutRow(context, 'T', 'Draw Text Tool'),
                  _buildShortcutRow(
                    context,
                    'I',
                    'Pick Color from Screen (Eyedropper)',
                  ),
                ],
              ),
              _buildShortcutCard(
                context,
                children: [
                  _buildShortcutRow(context, '$mod + C', 'Copy Selected Shapes'),
                  _buildShortcutRow(context, '$mod + X', 'Cut Selected Shapes'),
                  _buildShortcutRow(context, '$mod + V', 'Paste Shapes'),
                  _buildShortcutRow(
                    context,
                    '$mod + D',
                    'Duplicate Selected Shapes',
                  ),
                  _buildShortcutRow(
                    context,
                    'Delete / Backspace',
                    'Delete Selected Shapes',
                  ),
                  _buildShortcutRow(context, '$mod + A', 'Select All Shapes'),
                  _buildShortcutRow(context, '$mod + Z', 'Undo'),
                  _buildShortcutRow(context, '$mod + Shift + Z', 'Redo'),
                ],
              ),
              _buildShortcutCard(
                context,
                children: [
                  _buildShortcutRow(
                    context,
                    '$mod + ] / ]',
                    'Bring Forward (Layer Up)',
                  ),
                  _buildShortcutRow(
                    context,
                    '$mod + [ / [',
                    'Send Backward (Layer Down)',
                  ),
                  _buildShortcutRow(context, 'Shift + H', 'Flip Horizontally'),
                  _buildShortcutRow(context, 'Shift + V', 'Flip Vertically'),
                  _buildShortcutRow(
                    context,
                    '$mod + Alt + U',
                    'Boolean Union',
                  ),
                  _buildShortcutRow(
                    context,
                    '$mod + Alt + S',
                    'Boolean Subtract',
                  ),
                  _buildShortcutRow(
                    context,
                    '$mod + Alt + I',
                    'Boolean Intersect',
                  ),
                  _buildShortcutRow(
                    context,
                    '$mod + Alt + X',
                    'Boolean Exclude',
                  ),
                  _buildShortcutRow(
                    context,
                    '$mod + Alt + H',
                    'Distribute Horizontally',
                  ),
                  _buildShortcutRow(
                    context,
                    '$mod + Alt + V',
                    'Distribute Vertically',
                  ),
                ],
              ),
              _buildShortcutCard(
                context,
                children: [
                  _buildShortcutRow(
                    context,
                    '$mod + 0 / Shift + 0',
                    'Reset Zoom (100%)',
                  ),
                  _buildShortcutRow(
                    context,
                    'Shift + 1 / $mod + 1',
                    'Zoom to Fit All',
                  ),
                  _buildShortcutRow(
                    context,
                    'Shift + 2 / $mod + 2',
                    'Zoom to Selection',
                  ),
                  _buildShortcutRow(context, '$mod + / -', 'Zoom In / Out'),
                  _buildShortcutRow(
                    context,
                    '$mod + Wheel',
                    'Zoom In / Out around Cursor (Figma)',
                  ),
                  _buildShortcutRow(
                    context,
                    'Arrow Keys',
                    'Nudge 1px (Hold Shift for 10px, Alt for 0.1px)',
                  ),
                  _buildShortcutRow(
                    context,
                    'Shift + Resize',
                    'Constrain Proportions (Aspect Ratio)',
                  ),
                  _buildShortcutRow(
                    context,
                    'Alt + Resize',
                    'Resize Symmetrically from Center',
                  ),
                  _buildShortcutRow(
                    context,
                    'Shift + Rotate',
                    'Snap Rotation to 15° Increments',
                  ),
                  _buildShortcutRow(
                    context,
                    'Shift + Radius Point',
                    'Snap Radius to 10px Steps (0, 10, 20...)',
                  ),
                  _buildShortcutRow(
                    context,
                    'Alt + Radius Point',
                    'Adjust Single Corner Radius Only (Figma)',
                  ),
                ],
              ),
              _buildShortcutCard(
                context,
                children: [
                  _buildShortcutRow(
                    context,
                    '$mod + ,',
                    'Open Settings & Preferences',
                  ),
                  _buildShortcutRow(
                    context,
                    '$mod + E',
                    'Export SVG Artwork',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.tonal,
          child: Text(
            'Got it',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildShortcutRow(
    BuildContext context,
    String key,
    String description,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              key,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
