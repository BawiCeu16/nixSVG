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
    final orientation = MediaQuery.orientationOf(context);
    final isLandscape = orientation == Orientation.landscape;
    final width = MediaQuery.sizeOf(context).width;

    if (isDesktop || width >= 1200) {
      return 55.0;
    } else if (width >= 600) {
      return isLandscape ? 47.0 : 49.0;
    } else {
      // Small phone screens
      return isLandscape ? 43.0 : 47.0;
    }
  }

  /// Determines whether the layout is in compact mode (e.g. phones or narrow windows).
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 900.0;
  }

  /// True for small phone screen viewports (<600px width).
  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600.0;
  }

  /// True for large desktop and 4k ultrawide screens (>=1600px width).
  static bool isUltraWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 1600.0;
  }

  /// Calculates dynamic maximum allowed sidebar width.
  static double getMaxSidebarWidth(double screenWidth) {
    if (screenWidth >= 1920) {
      return (screenWidth * 0.28).clamp(240.0, 520.0);
    }
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
    return (screenWidth * 0.85).clamp(240.0, 380.0);
  }

  /// Dynamic bottom padding for the [FloatingToolBar].
  static double getFloatingToolbarBottomMargin(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    if (orientation == Orientation.landscape && size.height < 500) {
      return 8.0 + bottomInset;
    }
    return (size.width < 600) ? (10.0 + bottomInset) : (14.0 + bottomInset);
  }

  /// Dynamic scale factor for the [FloatingToolBar] across device form factors.
  static double getFloatingToolbarScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 0.84;
    if (width < 600) return 0.92;
    if (width >= 2000) return 1.05;
    return 1.0;
  }
}
