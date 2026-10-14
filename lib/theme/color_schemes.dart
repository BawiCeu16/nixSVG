import 'package:flutter/material.dart';
import 'package:m3e_color_scheme/m3e_color_scheme.dart';

/// Generates Material 3 Expressive ColorSchemes dynamically based on any seed color.
class AppColorSchemes {
  const AppColorSchemes._();

  /// Builds dynamic light [ColorScheme] using M3E vibrant color variant.
  static ColorScheme light(Color seedColor) {
    final m3eLight = M3EColorScheme.light(
      seedColor: seedColor,
      variant: M3EColorVariant.vibrant,
    );

    return ColorScheme(
      brightness: Brightness.light,
      primary: m3eLight.primary,
      onPrimary: m3eLight.onPrimary,
      primaryContainer: m3eLight.primaryContainer,
      onPrimaryContainer: m3eLight.onPrimaryContainer,
      secondary: m3eLight.secondary,
      onSecondary: m3eLight.onSecondary,
      secondaryContainer: m3eLight.secondaryContainer,
      onSecondaryContainer: m3eLight.onSecondaryContainer,
      tertiary: m3eLight.tertiary,
      onTertiary: m3eLight.onTertiary,
      tertiaryContainer: m3eLight.tertiaryContainer,
      onTertiaryContainer: m3eLight.onTertiaryContainer,
      error: m3eLight.error,
      onError: m3eLight.onError,
      errorContainer: m3eLight.errorContainer,
      onErrorContainer: m3eLight.onErrorContainer,
      surface: m3eLight.surface,
      onSurface: m3eLight.onSurface,
      onSurfaceVariant: m3eLight.onSurfaceVariant,
      surfaceContainerLowest: m3eLight.surfaceContainerLowest,
      surfaceContainerLow: m3eLight.surfaceContainerLow,
      surfaceContainer: m3eLight.surfaceContainer,
      surfaceContainerHigh: m3eLight.surfaceContainerHigh,
      surfaceContainerHighest: m3eLight.surfaceContainerHighest,
      outline: m3eLight.outline,
      outlineVariant: m3eLight.outlineVariant,
      inverseSurface: m3eLight.inverseSurface,
      onInverseSurface: m3eLight.onInverseSurface,
      inversePrimary: m3eLight.inversePrimary,
      scrim: m3eLight.scrim,
      shadow: m3eLight.shadow,
      surfaceTint: m3eLight.surfaceTint,
    );
  }

  /// Builds dynamic dark [ColorScheme] using M3E vibrant color variant.
  static ColorScheme dark(Color seedColor) {
    final m3eDark = M3EColorScheme.dark(
      seedColor: seedColor,
      variant: M3EColorVariant.vibrant,
    );

    return ColorScheme(
      brightness: Brightness.dark,
      primary: m3eDark.primary,
      onPrimary: m3eDark.onPrimary,
      primaryContainer: m3eDark.primaryContainer,
      onPrimaryContainer: m3eDark.onPrimaryContainer,
      secondary: m3eDark.secondary,
      onSecondary: m3eDark.onSecondary,
      secondaryContainer: m3eDark.secondaryContainer,
      onSecondaryContainer: m3eDark.onSecondaryContainer,
      tertiary: m3eDark.tertiary,
      onTertiary: m3eDark.onTertiary,
      tertiaryContainer: m3eDark.tertiaryContainer,
      onTertiaryContainer: m3eDark.onTertiaryContainer,
      error: m3eDark.error,
      onError: m3eDark.onError,
      errorContainer: m3eDark.errorContainer,
      onErrorContainer: m3eDark.onErrorContainer,
      surface: m3eDark.surface,
      onSurface: m3eDark.onSurface,
      onSurfaceVariant: m3eDark.onSurfaceVariant,
      surfaceContainerLowest: m3eDark.surfaceContainerLowest,
      surfaceContainerLow: m3eDark.surfaceContainerLow,
      surfaceContainer: m3eDark.surfaceContainer,
      surfaceContainerHigh: m3eDark.surfaceContainerHigh,
      surfaceContainerHighest: m3eDark.surfaceContainerHighest,
      outline: m3eDark.outline,
      outlineVariant: m3eDark.outlineVariant,
      inverseSurface: m3eDark.inverseSurface,
      onInverseSurface: m3eDark.onInverseSurface,
      inversePrimary: m3eDark.inversePrimary,
      scrim: m3eDark.scrim,
      shadow: m3eDark.shadow,
      surfaceTint: m3eDark.surfaceTint,
    );
  }
}
