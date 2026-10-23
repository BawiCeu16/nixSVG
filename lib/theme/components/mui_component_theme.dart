import 'package:flutter/material.dart';
import 'package:m3e_color_scheme/m3e_color_scheme.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// Theme styling specifically configured for nixSVG Material UI components.
class NixSvgMuiTheme {
  const NixSvgMuiTheme._();

  static mui.ThemeData createTheme({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final m3eScheme = isDark
        ? M3EColorScheme.dark(
            seedColor: seedColor,
            variant: M3EColorVariant.vibrant,
          )
        : M3EColorScheme.light(
            seedColor: seedColor,
            variant: M3EColorVariant.vibrant,
          );

    return mui.ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: m3eScheme,
      iconButtonTheme: const mui.IconButtonThemeData(
        variant: mui.StyleVariant.material3Expressive,
      ),
    );
  }
}
