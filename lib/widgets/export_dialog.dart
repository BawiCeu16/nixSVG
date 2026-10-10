import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:remixicon/remixicon.dart';

class ExportDialog extends StatelessWidget {
  final String svgContent;
  final String fileName;

  const ExportDialog({
    super.key,
    required this.svgContent,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      title: Row(
        children: [
          Icon(RemixIcons.code_line, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            'Export $fileName',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        height: 340,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              svgContent,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
      actions: [
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          child: Text(
            'Cancel',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        M3EButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: svgContent));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'SVG markup copied to clipboard!',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
                ),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          icon: Icon(RemixIcons.file_copy_line, size: 18, color: colorScheme.onPrimary),
          label: Text(
            'Copy SVG Code',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

