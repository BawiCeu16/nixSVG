import 'dart:ui';
import 'package:nixsvg/models/vector_shape.dart';

class SvgExportService {
  static String generateSvg(List<VectorShape> shapes, {Size canvasSize = const Size(1920, 1080)}) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" width="${canvasSize.width.toInt()}" height="${canvasSize.height.toInt()}" viewBox="0 0 ${canvasSize.width.toInt()} ${canvasSize.height.toInt()}">');

    for (final shape in shapes) {
      if (shape.isVisible) {
        final elementSvg = shape.toSvgElement();
        if (elementSvg.isNotEmpty) {
          buffer.writeln(elementSvg);
        }
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }
}
