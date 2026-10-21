import 'package:flutter/material.dart';

import 'color_picker/nix_color_picker.dart';

export 'color_picker/nix_color_models.dart';
export 'color_picker/nix_color_picker.dart';
export 'color_picker/nix_color_picker_presenter.dart';
export 'color_picker/nix_eyedropper_overlay.dart';

/// Backward-compatible dialog wrapper for [NixColorPicker] with Material 3 Expressive polish.
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;
  final String title;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    this.title = 'Select Color',
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Transform.translate(
          offset: _dragOffset,
          child: NixColorPicker(
            initialColor: widget.initialColor,
            title: widget.title,
            onDragDelta: (delta) {
              setState(() {
                _dragOffset += delta;
              });
            },
            onColorChanged: widget.onColorSelected,
            onColorFinalized: widget.onColorSelected,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
