import 'package:flutter/material.dart';
import 'package:m3e_typography/m3e_typography.dart';

/// Configures Material 3 Expressive typography themes.
class AppTypography {
  const AppTypography._();

  /// Builds emphasized M3E light text theme.
  static TextTheme light(ColorScheme scheme) {
    final base = Typography.material2021().black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: 'Google Sans',
    );
    return M3ETypography.emphasized(base);
  }

  /// Builds emphasized M3E dark text theme.
  static TextTheme dark(ColorScheme scheme) {
    final base = Typography.material2021().white.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: 'Google Sans',
    );
    return M3ETypography.emphasized(base);
  }
}
