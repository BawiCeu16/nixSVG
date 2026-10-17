import 'package:flutter/material.dart';

import 'color_picker/nix_color_picker.dart';

export 'color_picker/nix_color_models.dart';
export 'color_picker/nix_color_picker.dart';
export 'color_picker/nix_color_picker_presenter.dart';
export 'color_picker/color_picker_experiment_widget.dart';
export 'color_picker/nix_eyedropper_overlay.dart';

/// Backward-compatible dialog wrapper for [NixColorPicker] with Material 3 Expressive polish.
class ColorPickerDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: NixColorPicker(
          initialColor: initialColor,
          title: title,
          onColorChanged: onColorSelected,
          onColorFinalized: onColorSelected,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
