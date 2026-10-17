import 'package:flutter/material.dart';

/// Custom painter for the 2D Saturation-Value box (Figma / macOS style)
class NixSaturationValuePainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;

  const NixSaturationValuePainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.clipRRect(rrect);

    // 1. Horizontal gradient: White -> Pure Hue
    final pureHue = HSVColor.fromAHSV(1.0, hue % 360, 1.0, 1.0).toColor();
    final horizontalGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, pureHue],
    );
    final paintHoriz = Paint()..shader = horizontalGradient.createShader(rect);
    canvas.drawRect(rect, paintHoriz);

    // 2. Vertical gradient: Transparent -> Black (Value/Brightness)
    final verticalGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );
    final paintVert = Paint()..shader = verticalGradient.createShader(rect);
    canvas.drawRect(rect, paintVert);

    // 3. Thumb indicator (ring with high contrast)
    final double thumbX = (saturation.clamp(0.0, 1.0) * size.width);
    final double thumbY = ((1.0 - value.clamp(0.0, 1.0)) * size.height);
    final Offset thumbCenter = Offset(thumbX, thumbY);

    // Outer shadow
    canvas.drawCircle(
      thumbCenter,
      9.0,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // White outer ring
    canvas.drawCircle(
      thumbCenter,
      8.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Dark hairline border inside for white background contrast
    canvas.drawCircle(
      thumbCenter,
      6.5,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant NixSaturationValuePainter oldDelegate) {
    return oldDelegate.hue != hue ||
        oldDelegate.saturation != saturation ||
        oldDelegate.value != value;
  }
}

/// Custom painter for Rainbow Hue Slider Track
class NixHueTrackPainter extends CustomPainter {
  final double hue;

  const NixHueTrackPainter({required this.hue});

  static const List<Color> _hueColors = [
    Color(0xFFFF0000), // Red (0°)
    Color(0xFFFFFF00), // Yellow (60°)
    Color(0xFF00FF00), // Green (120°)
    Color(0xFF00FFFF), // Cyan (180°)
    Color(0xFF0000FF), // Blue (240°)
    Color(0xFFFF00FF), // Magenta (300°)
    Color(0xFFFF0000), // Red (360°)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    canvas.clipRRect(rrect);

    // Rainbow gradient
    final gradient = const LinearGradient(
      colors: _hueColors,
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Thumb indicator
    final double thumbX = ((hue % 360) / 360.0 * size.width).clamp(0.0, size.width);
    final Offset thumbCenter = Offset(thumbX, size.height / 2);

    // Outer shadow
    canvas.drawCircle(
      thumbCenter,
      size.height / 2 - 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // Outer white ring
    canvas.drawCircle(
      thumbCenter,
      size.height / 2 - 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant NixHueTrackPainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

/// Custom painter for Checkerboard pattern + Alpha Opacity Gradient
class NixAlphaTrackPainter extends CustomPainter {
  final Color baseColor;
  final double alpha;

  const NixAlphaTrackPainter({
    required this.baseColor,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    canvas.clipRRect(rrect);

    // 1. Draw checkerboard pattern
    _drawCheckerboard(canvas, size, squareSize: 5.0);

    // 2. Draw alpha gradient: transparent -> solid baseColor
    final gradient = LinearGradient(
      colors: [
        baseColor.withValues(alpha: 0.0),
        baseColor.withValues(alpha: 1.0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // 3. Draw thumb
    final double thumbX = (alpha.clamp(0.0, 1.0) * size.width).clamp(0.0, size.width);
    final Offset thumbCenter = Offset(thumbX, size.height / 2);

    // Outer shadow
    canvas.drawCircle(
      thumbCenter,
      size.height / 2 - 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // Outer white ring
    canvas.drawCircle(
      thumbCenter,
      size.height / 2 - 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawCheckerboard(Canvas canvas, Size size, {double squareSize = 5.0}) {
    final paintLight = Paint()..color = const Color(0xFFE2E8F0);
    final paintDark = Paint()..color = const Color(0xFF94A3B8);

    canvas.drawRect(Offset.zero & size, paintLight);

    final int cols = (size.width / squareSize).ceil();
    final int rows = (size.height / squareSize).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * squareSize, r * squareSize, squareSize, squareSize),
            paintDark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant NixAlphaTrackPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor || oldDelegate.alpha != alpha;
  }
}

/// Standalone Checkerboard background painter for color preview chips
class NixCheckerboardPainter extends CustomPainter {
  final double squareSize;

  const NixCheckerboardPainter({this.squareSize = 6.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLight = Paint()..color = const Color(0xFFF1F5F9);
    final paintDark = Paint()..color = const Color(0xFFCBD5E1);

    canvas.drawRect(Offset.zero & size, paintLight);

    final int cols = (size.width / squareSize).ceil();
    final int rows = (size.height / squareSize).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * squareSize, r * squareSize, squareSize, squareSize),
            paintDark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant NixCheckerboardPainter oldDelegate) => false;
}
