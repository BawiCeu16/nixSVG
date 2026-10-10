import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum ShapeType {
  rectangle,
  roundedRectangle,
  ellipse,
  line,
  star,
  text,
  image,
}

enum EditorMode {
  select,
  drawRectangle,
  drawRoundedRectangle,
  drawEllipse,
  drawLine,
  drawCurve,
  drawStar,
  drawText,
}

enum ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  topCenter,
  bottomCenter,
  centerLeft,
  centerRight,
  rotation,
  none,
}

enum LineCapStyle {
  none,
  round,
  square,
  arrow,
  circle,
}

class VectorShape {
  final String id;
  String name;
  ShapeType type;
  Rect rect;
  double rotation; // In degrees
  Color fillColor;
  double fillOpacity;
  Color strokeColor;
  double strokeWidth;
  StrokeCap strokeCap;
  LineCapStyle startCap;
  LineCapStyle endCap;
  bool isCurved;
  double curvature;
  bool isFilled;
  bool isStroked;
  double cornerRadius;
  String textContent;
  double fontSize;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool isVisible;
  bool isLocked;
  Uint8List? imageBytes;
  ui.Image? decodedImage;

  VectorShape({
    required this.id,
    required this.name,
    required this.type,
    required this.rect,
    this.rotation = 0.0,
    this.fillColor = const Color(0xFF6366F1),
    this.fillOpacity = 1.0,
    this.strokeColor = const Color(0xFF38BDF8),
    this.strokeWidth = 2.0,
    this.strokeCap = StrokeCap.butt,
    this.startCap = LineCapStyle.none,
    this.endCap = LineCapStyle.none,
    this.isCurved = false,
    this.curvature = 0.0,
    this.isFilled = true,
    this.isStroked = false,
    this.cornerRadius = 12.0,
    this.textContent = 'Text Element',
    this.fontSize = 24.0,
    this.fontFamily = 'Roboto',
    this.isBold = false,
    this.isItalic = false,
    this.isVisible = true,
    this.isLocked = false,
    this.imageBytes,
    this.decodedImage,
  });

  VectorShape copyWith({
    String? id,
    String? name,
    ShapeType? type,
    Rect? rect,
    double? rotation,
    Color? fillColor,
    double? fillOpacity,
    Color? strokeColor,
    double? strokeWidth,
    StrokeCap? strokeCap,
    LineCapStyle? startCap,
    LineCapStyle? endCap,
    bool? isCurved,
    double? curvature,
    bool? isFilled,
    bool? isStroked,
    double? cornerRadius,
    String? textContent,
    double? fontSize,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    bool? isVisible,
    bool? isLocked,
    Uint8List? imageBytes,
    ui.Image? decodedImage,
  }) {
    return VectorShape(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rect: rect ?? this.rect,
      rotation: rotation ?? this.rotation,
      fillColor: fillColor ?? this.fillColor,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap ?? this.strokeCap,
      startCap: startCap ?? this.startCap,
      endCap: endCap ?? this.endCap,
      isCurved: isCurved ?? this.isCurved,
      curvature: curvature ?? this.curvature,
      isFilled: isFilled ?? this.isFilled,
      isStroked: isStroked ?? this.isStroked,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      textContent: textContent ?? this.textContent,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      imageBytes: imageBytes ?? this.imageBytes,
      decodedImage: decodedImage ?? this.decodedImage,
    );
  }

  // Generate SVG string representation for this shape
  String toSvgElement() {
    if (!isVisible) return '';

    final fillHex = _colorToHex(fillColor);
    final strokeHex = _colorToHex(strokeColor);
    final fillAttr = isFilled
        ? 'fill="$fillHex" fill-opacity="$fillOpacity"'
        : 'fill="none"';
    final strokeAttr = isStroked
        ? 'stroke="$strokeHex" stroke-width="$strokeWidth"'
        : 'stroke="none"';

    final transformAttr = rotation != 0.0
        ? ' transform="rotate($rotation ${rect.center.dx} ${rect.center.dy})"'
        : '';

    switch (type) {
      case ShapeType.rectangle:
        return '  <rect x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.roundedRectangle:
        return '  <rect x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}" rx="$cornerRadius" ry="$cornerRadius" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.ellipse:
        final cx = rect.center.dx;
        final cy = rect.center.dy;
        final rx = rect.width / 2;
        final ry = rect.height / 2;
        return '  <ellipse cx="$cx" cy="$cy" rx="$rx" ry="$ry" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.line:
        if (!isStroked) return '';
        final capStr = strokeCap == StrokeCap.round
            ? 'round'
            : (strokeCap == StrokeCap.square ? 'square' : 'butt');
        if (isCurved || curvature != 0.0) {
          final p1 = rect.topLeft;
          final p2 = rect.bottomRight;
          final mid = (p1 + p2) / 2;
          final dx = p2.dx - p1.dx;
          final dy = p2.dy - p1.dy;
          final len = math.sqrt(dx * dx + dy * dy);
          final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
          final ctrl = mid + perp * curvature;
          return '  <path d="M ${p1.dx} ${p1.dy} Q ${ctrl.dx} ${ctrl.dy} ${p2.dx} ${p2.dy}" fill="none" stroke="$strokeHex" stroke-width="$strokeWidth" stroke-linecap="$capStr"$transformAttr />';
        }
        return '  <line x1="${rect.left}" y1="${rect.top}" x2="${rect.right}" y2="${rect.bottom}" stroke="$strokeHex" stroke-width="$strokeWidth" stroke-linecap="$capStr"$transformAttr />';
      case ShapeType.star:
        final points = _generateStarPointsSvg(rect);
        return '  <polygon points="$points" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.text:
        final weight = isBold ? ' font-weight="bold"' : '';
        final style = isItalic ? ' font-style="italic"' : '';
        return '  <text x="${rect.left}" y="${rect.top + fontSize}" font-family="$fontFamily" font-size="$fontSize" fill="$fillHex" fill-opacity="$fillOpacity"$weight$style$transformAttr>${_escapeXml(textContent)}</text>';
      case ShapeType.image:
        if (imageBytes != null) {
          final b64 = base64Encode(imageBytes!);
          return '  <image href="data:image/png;base64,$b64" x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}"$transformAttr />';
        }
        return '  <rect x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}" fill="#333"$transformAttr />';
    }
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _generateStarPointsSvg(Rect rect) {
    final center = rect.center;
    final outerRadius = math.min(rect.width, rect.height) / 2;
    final innerRadius = outerRadius * 0.4;
    final pointsList = <String>[];
    const double angleStep = math.pi / 5;

    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      pointsList.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    return pointsList.join(' ');
  }
}
