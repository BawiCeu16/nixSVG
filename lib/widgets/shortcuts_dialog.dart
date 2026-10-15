import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:remixicon/remixicon.dart';

class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
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
              _buildShortcutRow(context, 'C / P', 'Draw Curve / Path Tool'),
              _buildShortcutRow(context, 'S', 'Draw Star Tool'),
              _buildShortcutRow(context, 'T', 'Draw Text Tool'),
              const Divider(height: 16),
              _buildShortcutRow(context, 'Ctrl + C', 'Copy Selected Shapes'),
              _buildShortcutRow(context, 'Ctrl + X', 'Cut Selected Shapes'),
              _buildShortcutRow(context, 'Ctrl + V', 'Paste Shapes'),
              _buildShortcutRow(
                context,
                'Ctrl + D',
                'Duplicate Selected Shapes',
              ),
              _buildShortcutRow(
                context,
                'Delete / Backspace',
                'Delete Selected Shapes',
              ),
              _buildShortcutRow(context, 'Ctrl + A', 'Select All Shapes'),
              _buildShortcutRow(context, 'Ctrl + Z', 'Undo'),
              _buildShortcutRow(context, 'Ctrl + Y', 'Redo'),
              const Divider(height: 16),
              _buildShortcutRow(
                context,
                'Ctrl + ] / ]',
                'Bring Forward (Layer Up)',
              ),
              _buildShortcutRow(
                context,
                'Ctrl + [ / [',
                'Send Backward (Layer Down)',
              ),
              _buildShortcutRow(context, 'Shift + H', 'Flip Horizontally'),
              _buildShortcutRow(context, 'Shift + V', 'Flip Vertically'),
              const Divider(height: 16),
              _buildShortcutRow(
                context,
                'Ctrl + 0 / Shift + 0',
                'Reset Zoom (100%)',
              ),
              _buildShortcutRow(
                context,
                'Shift + 1 / Ctrl + 1',
                'Zoom to Fit All',
              ),
              _buildShortcutRow(
                context,
                'Shift + 2 / Ctrl + 2',
                'Zoom to Selection',
              ),
              _buildShortcutRow(context, 'Ctrl + / -', 'Zoom In / Out'),
              _buildShortcutRow(
                context,
                'Arrow Keys',
                'Nudge 1px (Hold Shift for 10px)',
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
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
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
