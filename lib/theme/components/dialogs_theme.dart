import 'package:flutter/material.dart';

/// Material 3 Expressive dialog and popup menu styles.
class AppDialogsTheme {
  const AppDialogsTheme._();

  static DialogThemeData dialog(ColorScheme scheme) {
    return DialogThemeData(
      elevation: 0,
      backgroundColor: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    );
  }

  static PopupMenuThemeData popupMenu(ColorScheme scheme) {
    return PopupMenuThemeData(
      color: scheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
