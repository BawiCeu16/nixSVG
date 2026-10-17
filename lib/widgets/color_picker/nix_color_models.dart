import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nixsvg/models/vector_shape.dart';

/// Supported color representations for input/display
enum ColorCodeFormat {
  hex('HEX'),
  rgba('RGB'),
  hsla('HSL'),
  hsva('HSV');

  final String label;
  const ColorCodeFormat(this.label);
}

/// Color Picker mode: Solid color vs Linear/Radial gradients
enum ColorPickerMode {
  solid('Solid'),
  linearGradient('Linear'),
  radialGradient('Radial');

  final String label;
  const ColorPickerMode(this.label);
}

/// Helper methods, calculations, and conversions for colors & gradients
class NixColorUtils {
  /// Converts a [Color] to a standard uppercase HEX string `#RRGGBB` or `#RRGGBBAA`
  static String toHex(Color color, {bool includeAlpha = true}) {
    final int argb = color.toARGB32();
    final int a = (argb >> 24) & 0xFF;
    final int r = (argb >> 16) & 0xFF;
    final int g = (argb >> 8) & 0xFF;
    final int b = argb & 0xFF;

    if (includeAlpha && a < 255) {
      return '#${r.toRadixString(16).padLeft(2, '0')}'
              '${g.toRadixString(16).padLeft(2, '0')}'
              '${b.toRadixString(16).padLeft(2, '0')}'
              '${a.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
    } else {
      return '#${r.toRadixString(16).padLeft(2, '0')}'
              '${g.toRadixString(16).padLeft(2, '0')}'
              '${b.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
    }
  }

  /// Parses user-entered HEX string gracefully. Supports #RGB, #RGBA, #RRGGBB, #RRGGBBAA, and without #
  static Color? parseHex(String input) {
    String clean = input.trim().replaceAll('#', '');
    if (clean.isEmpty) return null;

    // Handle 3 or 4 hex shorthand (e.g. F00 or F00F)
    if (clean.length == 3) {
      clean = '${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}';
    } else if (clean.length == 4) {
      clean = '${clean[0]}${clean[0]}${clean[1]}${clean[1]}${clean[2]}${clean[2]}${clean[3]}${clean[3]}';
    }

    if (clean.length == 6) {
      final val = int.tryParse(clean, radix: 16);
      if (val == null) return null;
      return Color(0xFF000000 | val);
    } else if (clean.length == 8) {
      // Standard 8 digits: RRGGBBAA
      final r = int.tryParse(clean.substring(0, 2), radix: 16);
      final g = int.tryParse(clean.substring(2, 4), radix: 16);
      final b = int.tryParse(clean.substring(4, 6), radix: 16);
      final a = int.tryParse(clean.substring(6, 8), radix: 16);
      if (r == null || g == null || b == null || a == null) return null;
      return Color.fromARGB(a, r, g, b);
    }
    return null;
  }

  /// Returns (R, G, B, A) where R, G, B are 0..255 and A is 0..100 (%)
  static ({int r, int g, int b, int aPct}) toRgba(Color color) {
    final int argb = color.toARGB32();
    final int a = (argb >> 24) & 0xFF;
    final int r = (argb >> 16) & 0xFF;
    final int g = (argb >> 8) & 0xFF;
    final int b = argb & 0xFF;
    return (
      r: r,
      g: g,
      b: b,
      aPct: (a / 255.0 * 100.0).round().clamp(0, 100),
    );
  }

  /// Creates a [Color] from R (0..255), G (0..255), B (0..255), and Alpha percentage (0..100)
  static Color fromRgba(int r, int g, int b, int aPct) {
    final int clampedR = r.clamp(0, 255);
    final int clampedG = g.clamp(0, 255);
    final int clampedB = b.clamp(0, 255);
    final int clampedA = ((aPct.clamp(0, 100) / 100.0) * 255.0).round().clamp(0, 255);
    return Color.fromARGB(clampedA, clampedR, clampedG, clampedB);
  }

  /// Returns (H, S, L, A) where H is 0..360, S is 0..100 (%), L is 0..100 (%), and A is 0..100 (%)
  static ({int h, int sPct, int lPct, int aPct}) toHsla(Color color) {
    final hsl = HSLColor.fromColor(color);
    return (
      h: hsl.hue.round() % 360,
      sPct: (hsl.saturation * 100.0).round().clamp(0, 100),
      lPct: (hsl.lightness * 100.0).round().clamp(0, 100),
      aPct: (hsl.alpha * 100.0).round().clamp(0, 100),
    );
  }

  /// Creates a [Color] from H (0..360), S (0..100%), L (0..100%), and A (0..100%)
  static Color fromHsla(int h, int sPct, int lPct, int aPct) {
    final double hue = (h % 360).toDouble();
    final double saturation = (sPct.clamp(0, 100) / 100.0);
    final double lightness = (lPct.clamp(0, 100) / 100.0);
    final double alpha = (aPct.clamp(0, 100) / 100.0);
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness).toColor();
  }

  /// Returns (H, S, V, A) where H is 0..360, S is 0..100 (%), V is 0..100 (%), and A is 0..100 (%)
  static ({int h, int sPct, int vPct, int aPct}) toHsva(Color color) {
    final hsv = HSVColor.fromColor(color);
    return (
      h: hsv.hue.round() % 360,
      sPct: (hsv.saturation * 100.0).round().clamp(0, 100),
      vPct: (hsv.value * 100.0).round().clamp(0, 100),
      aPct: (hsv.alpha * 100.0).round().clamp(0, 100),
    );
  }

  /// Creates a [Color] from H (0..360), S (0..100%), V (0..100%), and A (0..100%)
  static Color fromHsva(int h, int sPct, int vPct, int aPct) {
    final double hue = (h % 360).toDouble();
    final double saturation = (sPct.clamp(0, 100) / 100.0);
    final double value = (vPct.clamp(0, 100) / 100.0);
    final double alpha = (aPct.clamp(0, 100) / 100.0);
    return HSVColor.fromAHSV(alpha, hue, saturation, value).toColor();
  }

  // -------------------------------------------------------------
  // Professional Calculations: WCAG Contrast, Harmonies & Math
  // -------------------------------------------------------------

  /// Calculates WCAG 2.1 relative luminance for a color
  static double relativeLuminance(Color color) {
    double transform(double c) {
      return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates contrast ratio between two colors (range: 1.0 to 21.0)
  static double contrastRatio(Color fg, Color bg) {
    final l1 = relativeLuminance(fg);
    final l2 = relativeLuminance(bg);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns WCAG compliance rating (AAA, AA, AA Large, or Fail)
  static String wcagRating(double ratio) {
    if (ratio >= 7.0) return 'AAA';
    if (ratio >= 4.5) return 'AA';
    if (ratio >= 3.0) return 'AA Large';
    return 'Fail';
  }

  /// Computes the exact complementary color (180° opposite on hue wheel)
  static Color complementary(Color color) {
    final hsv = HSVColor.fromColor(color);
    final newHue = (hsv.hue + 180.0) % 360.0;
    return hsv.withHue(newHue).toColor();
  }

  /// Computes inverted RGB color while preserving opacity
  static Color invert(Color color) {
    final int a = (color.a * 255).round();
    final int r = (255 - (color.r * 255).round()).clamp(0, 255);
    final int g = (255 - (color.g * 255).round()).clamp(0, 255);
    final int b = (255 - (color.b * 255).round()).clamp(0, 255);
    return Color.fromARGB(a, r, g, b);
  }

  /// Generates a random vibrant color with pleasing saturation and brightness
  static Color randomVibrant() {
    final random = math.Random();
    final hue = random.nextDouble() * 360.0;
    final saturation = 0.65 + random.nextDouble() * 0.35;
    final value = 0.80 + random.nextDouble() * 0.20;
    return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
  }

  /// Generates CSS code for solid or gradient fill
  static String toCssString({
    required Color color,
    ShapeGradient? gradient,
    ColorPickerMode mode = ColorPickerMode.solid,
  }) {
    if (mode == ColorPickerMode.solid || gradient == null) {
      final rgba = toRgba(color);
      if (rgba.aPct < 100) {
        return 'rgba(${rgba.r}, ${rgba.g}, ${rgba.b}, ${(rgba.aPct / 100).toStringAsFixed(2)})';
      }
      return toHex(color);
    }

    final stopsStr = gradient.stops
        .map((s) => '${toHex(s.color)} ${(s.offset * 100).round()}%')
        .join(', ');

    if (mode == ColorPickerMode.radialGradient || gradient.type == PaintFillType.radialGradient) {
      return 'radial-gradient(circle, $stopsStr)';
    } else {
      return 'linear-gradient(${gradient.angle.round()}deg, $stopsStr)';
    }
  }

  /// Interpolates color between stops at a given offset (0.0 to 1.0)
  static Color lerpGradientStops(List<GradientColorStop> stops, double offset) {
    if (stops.isEmpty) return const Color(0xFF6366F1);
    if (stops.length == 1) return stops.first.color;

    final sorted = List<GradientColorStop>.from(stops)
      ..sort((a, b) => a.offset.compareTo(b.offset));

    if (offset <= sorted.first.offset) return sorted.first.color;
    if (offset >= sorted.last.offset) return sorted.last.color;

    for (int i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      if (offset >= a.offset && offset <= b.offset) {
        final double range = b.offset - a.offset;
        final double t = range > 0.0 ? (offset - a.offset) / range : 0.0;
        return Color.lerp(a.color, b.color, t) ?? a.color;
      }
    }
    return sorted.first.color;
  }

  // -------------------------------------------------------------
  // Curated Preset Palettes & Gradients
  // -------------------------------------------------------------

  /// Standard curated Material 3 Expressive & macOS vibrant swatches
  static const List<Color> curatedPresets = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF3B82F6), // Electric Blue
    Color(0xFF0EA5E9), // Sky Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFF22C55E), // Fresh Green
    Color(0xFF84CC16), // Lime Green
    Color(0xFFEAB308), // Vibrant Yellow
    Color(0xFFF97316), // Tangerine
    Color(0xFFEF4444), // Coral Red
    Color(0xFFF43F5E), // Rose Pink
    Color(0xFFD946EF), // Fuchsia
    Color(0xFFA855F7), // Violet
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Teal
    Color(0xFF14B8A6), // Mint
    Color(0xFFFFFFFF), // Crisp White
    Color(0xFFCBD5E1), // Cool Slate
    Color(0xFF64748B), // Slate Grey
    Color(0xFF334155), // Deep Slate
    Color(0xFF000000), // Pitch Black
  ];

  /// Curated Material 3 Expressive & macOS vibrant gradient presets
  static const List<ShapeGradient> curatedGradientPresets = [
    ShapeGradient(
      type: PaintFillType.linearGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFF6366F1)),
        GradientColorStop(offset: 1.0, color: Color(0xFF38BDF8)),
      ],
      angle: 90.0,
    ),
    ShapeGradient(
      type: PaintFillType.linearGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFFFF512F)),
        GradientColorStop(offset: 1.0, color: Color(0xFFDD2476)),
      ],
      angle: 45.0,
    ),
    ShapeGradient(
      type: PaintFillType.linearGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFF8A2387)),
        GradientColorStop(offset: 0.5, color: Color(0xFFE94057)),
        GradientColorStop(offset: 1.0, color: Color(0xFFF27121)),
      ],
      angle: 90.0,
    ),
    ShapeGradient(
      type: PaintFillType.linearGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFF00B09B)),
        GradientColorStop(offset: 1.0, color: Color(0xFF96C93D)),
      ],
      angle: 135.0,
    ),
    ShapeGradient(
      type: PaintFillType.linearGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFF00C6FF)),
        GradientColorStop(offset: 1.0, color: Color(0xFF0072FF)),
      ],
      angle: 90.0,
    ),
    ShapeGradient(
      type: PaintFillType.linearGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFFF857A6)),
        GradientColorStop(offset: 1.0, color: Color(0xFFFF5858)),
      ],
      angle: 45.0,
    ),
    ShapeGradient(
      type: PaintFillType.radialGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFFFFFFFF)),
        GradientColorStop(offset: 1.0, color: Color(0xFF6366F1)),
      ],
    ),
    ShapeGradient(
      type: PaintFillType.radialGradient,
      stops: [
        GradientColorStop(offset: 0.0, color: Color(0xFFFFE066)),
        GradientColorStop(offset: 1.0, color: Color(0xFFFF3366)),
      ],
    ),
  ];
}
