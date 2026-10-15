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
  pan,
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

enum TextVerticalAlign {
  top,
  center,
  bottom,
}

enum TextCase {
  original,
  uppercase,
  lowercase,
  titleCase,
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
  bool isUnderline;
  bool isStrikethrough;
  TextAlign textAlign;
  TextVerticalAlign textVerticalAlign;
  double letterSpacing;
  double lineHeight;
  TextCase textCase;
  FontWeight fontWeight;
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
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.textAlign = TextAlign.left,
    this.textVerticalAlign = TextVerticalAlign.top,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.textCase = TextCase.original,
    FontWeight? fontWeight,
    this.isVisible = true,
    this.isLocked = false,
    this.imageBytes,
    this.decodedImage,
  }) : fontWeight = fontWeight ?? (isBold ? FontWeight.bold : FontWeight.normal);

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
    bool? isUnderline,
    bool? isStrikethrough,
    TextAlign? textAlign,
    TextVerticalAlign? textVerticalAlign,
    double? letterSpacing,
    double? lineHeight,
    TextCase? textCase,
    FontWeight? fontWeight,
    bool? isVisible,
    bool? isLocked,
    Uint8List? imageBytes,
    ui.Image? decodedImage,
  }) {
    final effectiveIsBold = isBold ??
        (fontWeight != null
            ? (fontWeight.value >= FontWeight.w700.value)
            : this.isBold);
    final effectiveFontWeight = fontWeight ??
        (isBold != null
            ? (isBold ? FontWeight.bold : FontWeight.normal)
            : this.fontWeight);
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
      isBold: effectiveIsBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      textAlign: textAlign ?? this.textAlign,
      textVerticalAlign: textVerticalAlign ?? this.textVerticalAlign,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      textCase: textCase ?? this.textCase,
      fontWeight: effectiveFontWeight,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      imageBytes: imageBytes ?? this.imageBytes,
      decodedImage: decodedImage ?? this.decodedImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rect': {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      },
      'rotation': rotation,
      'fillColor': fillColor.toARGB32(),
      'fillOpacity': fillOpacity,
      'strokeColor': strokeColor.toARGB32(),
      'strokeWidth': strokeWidth,
      'strokeCap': strokeCap.name,
      'startCap': startCap.name,
      'endCap': endCap.name,
      'isCurved': isCurved,
      'curvature': curvature,
      'isFilled': isFilled,
      'isStroked': isStroked,
      'cornerRadius': cornerRadius,
      'textContent': textContent,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'isStrikethrough': isStrikethrough,
      'textAlign': textAlign.name,
      'textVerticalAlign': textVerticalAlign.name,
      'letterSpacing': letterSpacing,
      'lineHeight': lineHeight,
      'textCase': textCase.name,
      'fontWeight': fontWeight.value,
      'isVisible': isVisible,
      'isLocked': isLocked,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
    };
  }

  factory VectorShape.fromJson(Map<String, dynamic> json) {
    final rectMap = json['rect'] as Map<String, dynamic>? ?? {};
    final rect = Rect.fromLTWH(
      (rectMap['left'] as num?)?.toDouble() ?? 0.0,
      (rectMap['top'] as num?)?.toDouble() ?? 0.0,
      (rectMap['width'] as num?)?.toDouble() ?? 100.0,
      (rectMap['height'] as num?)?.toDouble() ?? 100.0,
    );

    final typeStr = json['type'] as String? ?? 'rectangle';
    final type = ShapeType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ShapeType.rectangle,
    );

    final strokeCapStr = json['strokeCap'] as String? ?? 'butt';
    final strokeCap = StrokeCap.values.firstWhere(
      (e) => e.name == strokeCapStr,
      orElse: () => StrokeCap.butt,
    );

    final startCapStr = json['startCap'] as String? ?? 'none';
    final startCap = LineCapStyle.values.firstWhere(
      (e) => e.name == startCapStr,
      orElse: () => LineCapStyle.none,
    );

    final endCapStr = json['endCap'] as String? ?? 'none';
    final endCap = LineCapStyle.values.firstWhere(
      (e) => e.name == endCapStr,
      orElse: () => LineCapStyle.none,
    );

    final textAlignStr = json['textAlign'] as String? ?? 'left';
    final textAlign = TextAlign.values.firstWhere(
      (e) => e.name == textAlignStr,
      orElse: () => TextAlign.left,
    );

    final textVerticalAlignStr =
        json['textVerticalAlign'] as String? ?? 'top';
    final textVerticalAlign = TextVerticalAlign.values.firstWhere(
      (e) => e.name == textVerticalAlignStr,
      orElse: () => TextVerticalAlign.top,
    );

    final textCaseStr = json['textCase'] as String? ?? 'original';
    final textCase = TextCase.values.firstWhere(
      (e) => e.name == textCaseStr,
      orElse: () => TextCase.original,
    );

    final fontWeightVal = json['fontWeight'] as int?;
    final fontWeight = fontWeightVal != null
        ? FontWeight.values.firstWhere(
            (w) => w.value == fontWeightVal,
            orElse: () => FontWeight.normal,
          )
        : null;

    final imageBytesStr = json['imageBytes'] as String?;
    Uint8List? imageBytes;
    if (imageBytesStr != null && imageBytesStr.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBytesStr);
      } catch (_) {}
    }

    return VectorShape(
      id: json['id'] as String? ??
          'shape-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Shape',
      type: type,
      rect: rect,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      fillColor: json['fillColor'] != null
          ? Color(json['fillColor'] as int)
          : const Color(0xFF6366F1),
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 1.0,
      strokeColor: json['strokeColor'] != null
          ? Color(json['strokeColor'] as int)
          : const Color(0xFF38BDF8),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeCap: strokeCap,
      startCap: startCap,
      endCap: endCap,
      isCurved: json['isCurved'] as bool? ?? false,
      curvature: (json['curvature'] as num?)?.toDouble() ?? 0.0,
      isFilled: json['isFilled'] as bool? ?? true,
      isStroked: json['isStroked'] as bool? ?? false,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 12.0,
      textContent: json['textContent'] as String? ?? 'Text Element',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      isStrikethrough: json['isStrikethrough'] as bool? ?? false,
      textAlign: textAlign,
      textVerticalAlign: textVerticalAlign,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
      textCase: textCase,
      fontWeight: fontWeight,
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      imageBytes: imageBytes,
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
        String displayText = textContent;
        switch (textCase) {
          case TextCase.uppercase:
            displayText = displayText.toUpperCase();
            break;
          case TextCase.lowercase:
            displayText = displayText.toLowerCase();
            break;
          case TextCase.titleCase:
            displayText = _toTitleCase(displayText);
            break;
          case TextCase.original:
            break;
        }

        final weight = ' font-weight="${fontWeight.value}"';
        final style = isItalic ? ' font-style="italic"' : '';

        // Horizontal text-anchor & position X
        String textAnchor = 'start';
        double posX = rect.left;
        if (textAlign == TextAlign.center) {
          textAnchor = 'middle';
          posX = rect.center.dx;
        } else if (textAlign == TextAlign.right) {
          textAnchor = 'end';
          posX = rect.right;
        }
        final anchorAttr = ' text-anchor="$textAnchor"';

        // Vertical dominant-baseline & position Y
        String dominantBaseline = 'hanging';
        double posY = rect.top;
        if (textVerticalAlign == TextVerticalAlign.center) {
          dominantBaseline = 'central';
          posY = rect.center.dy;
        } else if (textVerticalAlign == TextVerticalAlign.bottom) {
          dominantBaseline = 'auto';
          posY = rect.bottom;
        }
        final baselineAttr = ' dominant-baseline="$dominantBaseline"';

        final letterSpacingAttr = letterSpacing != 0.0
            ? ' letter-spacing="${letterSpacing}px"'
            : '';

        final decList = <String>[];
        if (isUnderline) decList.add('underline');
        if (isStrikethrough) decList.add('line-through');
        final decAttr = decList.isNotEmpty
            ? ' text-decoration="${decList.join(' ')}"'
            : '';

        return '  <text x="$posX" y="$posY" font-family="$fontFamily" font-size="$fontSize" fill="$fillHex" fill-opacity="$fillOpacity"$weight$style$anchorAttr$baselineAttr$letterSpacingAttr$decAttr$transformAttr>${_escapeXml(displayText)}</text>';
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

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() +
          (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }
}
