import 'dart:ui';

import 'package:nixsvg/models/vector_shape.dart';

class SvgExportService {
  static String generateSvg(
    List<VectorShape> shapes, {
    Size canvasSize = const Size(1920, 1080),
    bool includeXmlHeader = true,
    bool prettyPrint = true,
    double exportScale = 1.0,
  }) {
    final effectiveWidth = (canvasSize.width * exportScale).toInt();
    final effectiveHeight = (canvasSize.height * exportScale).toInt();
    final buffer = StringBuffer();
    final newline = prettyPrint ? '\n' : '';
    final indent = prettyPrint ? '  ' : '';

    if (includeXmlHeader) {
      buffer.write(
        '<?xml version="1.0" encoding="UTF-8" standalone="no"?>$newline',
      );
    }
    buffer.write(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$effectiveWidth" height="$effectiveHeight" viewBox="0 0 ${canvasSize.width.toInt()} ${canvasSize.height.toInt()}">$newline',
    );

    final defsBuffer = StringBuffer();
    for (final shape in shapes) {
      if (shape.isVisible) {
        final defs = shape.toSvgDefs();
        if (defs.isNotEmpty) {
          defsBuffer.write(defs);
        }
      }
    }

    if (defsBuffer.isNotEmpty) {
      buffer.write('$indent<defs>$newline');
      buffer.write(defsBuffer.toString());
      buffer.write('$indent</defs>$newline');
    }

    for (final shape in shapes) {
      if (shape.isVisible) {
        final elementSvg = shape.toSvgElement();
        if (elementSvg.isNotEmpty) {
          buffer.write('$elementSvg$newline');
        }
      }
    }

    buffer.write('</svg>');

    return buffer.toString();
  }
}
