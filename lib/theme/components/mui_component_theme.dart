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
      shadowColor: Colors.transparent,
      filledButtonTheme: mui.FilledButtonThemeData(
        style: mui.FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: m3eScheme.primary,
          foregroundColor: m3eScheme.onPrimary,
        ),
      ),
      elevatedButtonTheme: mui.ElevatedButtonThemeData(
        style: mui.ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: m3eScheme.surfaceContainerHigh,
          foregroundColor: m3eScheme.primary,
        ),
      ),
      outlinedButtonTheme: mui.OutlinedButtonThemeData(
        style: mui.OutlinedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: m3eScheme.primary,
          side: mui.BorderSide(color: m3eScheme.outlineVariant),
        ),
      ),
      textButtonTheme: mui.TextButtonThemeData(
        style: mui.TextButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: m3eScheme.primary,
        ),
      ),
      iconButtonTheme: mui.IconButtonThemeData(
        style: mui.IconButton.styleFrom(
          foregroundColor: m3eScheme.onSurfaceVariant,
          hoverColor: m3eScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
