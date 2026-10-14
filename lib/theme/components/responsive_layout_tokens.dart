import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive layout tokens and dynamic sizing calculations for nixSVG panels.
/// Guarantees dynamic sizing across OS platforms (Mac, Windows, Linux, Web, Android, iOS)
/// and device orientation changes according to Material 3 design rules.
class ResponsiveLayoutTokens {
  const ResponsiveLayoutTokens._();

  /// Whether current platform is a desktop operating system (macOS, Windows, Linux).
  static bool get isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Whether current platform is a mobile operating system (Android, iOS).
  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Calculates dynamic height for the [TopNavigationBar].
  static double getTopBarHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final width = media.size.width;

    if (isDesktop || width >= 1200) {
      return 60.0;
    } else if (width >= 600) {
      return isLandscape ? 56.0 : 58.0;
    } else {
      // Small phone screens
      return isLandscape ? 48.0 : 54.0;
    }
  }

  /// Determines whether the layout is in compact mode (e.g. phones or narrow windows).
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < 900.0;
  }

  /// Calculates dynamic maximum allowed sidebar width.
  static double getMaxSidebarWidth(double screenWidth) {
    return (screenWidth * 0.35).clamp(180.0, 420.0);
  }

  /// Clamps the user layers sidebar width against responsive limits.
  static double getEffectiveLayersWidth({
    required double desiredWidth,
    required double screenWidth,
  }) {
    final maxWidth = getMaxSidebarWidth(screenWidth);
    return desiredWidth.clamp(160.0, maxWidth);
  }

  /// Clamps the user properties sidebar width against responsive limits.
  static double getEffectivePropertiesWidth({
    required double desiredWidth,
    required double screenWidth,
  }) {
    final maxWidth = getMaxSidebarWidth(screenWidth);
    return desiredWidth.clamp(180.0, maxWidth);
  }

  /// Dynamic drawer width for compact screens (phones / small viewports).
  static double getCompactDrawerWidth(double screenWidth) {
    return (screenWidth * 0.78).clamp(240.0, 360.0);
  }

  /// Dynamic bottom padding for the [FloatingToolBar].
  static double getFloatingToolbarBottomMargin(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    if (media.orientation == Orientation.landscape && media.size.height < 500) {
      return 12.0 + bottomInset;
    }
    return 24.0 + bottomInset;
  }
}
