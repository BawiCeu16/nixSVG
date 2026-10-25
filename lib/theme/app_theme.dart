import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/theme/color_schemes.dart';
import 'package:nixsvg/theme/components/buttons_theme.dart';
import 'package:nixsvg/theme/components/cards_and_chips_theme.dart';
import 'package:nixsvg/theme/components/dialogs_theme.dart';
import 'package:nixsvg/theme/typography.dart';

export 'package:nixsvg/controllers/theme_controller.dart' show ThemePreset;

/// Central theme builder creating dynamic Material 3 Expressive [ThemeData]
/// for both Light and Dark modes based on the current seed color.
class AppTheme {
  const AppTheme._();

  /// Curated theme accent presets with names and colors.
  static List<ThemePreset> get presets => ThemeController.presets;

  /// Curated seed colors for quick mapping.
  static List<Color> get themePresets => ThemeController.themePresets;

  /// Returns the human-readable display name for a given seed [color].
  static String getColorName(Color color) => ThemeController.getColorName(color);

  /// Builds a dynamic [ThemeData] for the requested [Brightness] and [seedColor].
  static ThemeData buildTheme({
    required Brightness brightness,
    required Color seedColor,
    bool oledDark = false,
  }) {
    final isDark = brightness == Brightness.dark;
    var colorScheme = isDark
        ? AppColorSchemes.dark(seedColor)
        : AppColorSchemes.light(seedColor);

    if (isDark && oledDark) {
      colorScheme = colorScheme.copyWith(
        
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF070707),
        surfaceContainer: const Color(0xFF101010),
        surfaceContainerHigh: const Color(0xFF171717),
        surfaceContainerHighest: const Color(0xFF202020),
      );
    }

    final textTheme = isDark
        ? AppTypography.dark(colorScheme)
        : AppTypography.light(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      shadowColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 20),
      primaryIconTheme: IconThemeData(color: colorScheme.primary, size: 20),
      filledButtonTheme: AppButtonsTheme.filled(colorScheme, textTheme),
      elevatedButtonTheme: AppButtonsTheme.elevated(colorScheme, textTheme),
      outlinedButtonTheme: AppButtonsTheme.outlined(colorScheme, textTheme),
      textButtonTheme: AppButtonsTheme.text(colorScheme, textTheme),
      iconButtonTheme: AppButtonsTheme.icon(colorScheme),
      segmentedButtonTheme: AppButtonsTheme.segmented(colorScheme, textTheme),
      floatingActionButtonTheme: AppButtonsTheme.fab(colorScheme),
      cardTheme: AppCardsAndChipsTheme.card(colorScheme),
      chipTheme: AppCardsAndChipsTheme.chip(colorScheme, textTheme),
      dialogTheme: AppDialogsTheme.dialog(colorScheme),
      popupMenuTheme: AppDialogsTheme.popupMenu(colorScheme),
    );
  }

  /// Builds Material UI Expressive [mui.IconButtonThemeData] with [mui.StyleVariant.material3Expressive].
  static mui.IconButtonThemeData muiIconButtonTheme({
    mui.StyleVariant variant = mui.StyleVariant.material3Expressive,
    mui.ButtonStyle? style,
  }) {
    return mui.IconButtonThemeData(
      variant: variant,
      style: style,
    );
  }
}
