import 'package:flutter/material.dart';

/// Material 3 Expressive card and chip styles.
class AppCardsAndChipsTheme {
  const AppCardsAndChipsTheme._();

  static CardThemeData card(ColorScheme scheme) {
    return CardThemeData(
      elevation: 0,
      color: scheme.brightness == Brightness.dark
          ? scheme.surfaceContainer
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  static ChipThemeData chip(ColorScheme scheme, TextTheme textTheme) {
    return ChipThemeData(
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: scheme.brightness == Brightness.dark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLow,
      selectedColor: scheme.primary,
      labelStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onPrimary,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
