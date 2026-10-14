import 'package:flutter/material.dart';
import 'package:nixsvg/theme/color_schemes.dart';
import 'package:nixsvg/theme/components/buttons_theme.dart';
import 'package:nixsvg/theme/components/cards_and_chips_theme.dart';
import 'package:nixsvg/theme/components/dialogs_theme.dart';
import 'package:nixsvg/theme/typography.dart';

/// Central theme builder creating dynamic Material 3 Expressive [ThemeData]
/// for both Light and Dark modes based on the current seed color.
class AppTheme {
  const AppTheme._();

  /// Builds a dynamic [ThemeData] for the requested [Brightness] and [seedColor].
  static ThemeData buildTheme({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? AppColorSchemes.dark(seedColor)
        : AppColorSchemes.light(seedColor);
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
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.3),
        thickness: 1,
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
}
