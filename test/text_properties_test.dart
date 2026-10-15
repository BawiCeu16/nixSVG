import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';
import 'package:remixicon/remixicon.dart';

void main() {
  group('VectorShape Text Properties & SVG Export', () {
    test('Default text properties are correctly initialized', () {
      final textShape = VectorShape(
        id: 'txt-1',
        name: 'Header',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(100, 100, 300, 60),
        textContent: 'Hello World',
      );

      expect(textShape.textAlign, TextAlign.left);
      expect(textShape.textVerticalAlign, TextVerticalAlign.top);
      expect(textShape.textCase, TextCase.original);
      expect(textShape.isUnderline, isFalse);
      expect(textShape.isStrikethrough, isFalse);
      expect(textShape.letterSpacing, 0.0);
      expect(textShape.lineHeight, 1.2);
      expect(textShape.fontWeight, FontWeight.normal);
      expect(textShape.isBold, isFalse);
    });

    test(
      'copyWith updates text properties and keeps font weight / isBold in sync',
      () {
        final textShape = VectorShape(
          id: 'txt-1',
          name: 'Header',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(100, 100, 300, 60),
          textContent: 'Hello World',
        );

        final updated = textShape.copyWith(
          textAlign: TextAlign.center,
          textVerticalAlign: TextVerticalAlign.center,
          textCase: TextCase.uppercase,
          isUnderline: true,
          isStrikethrough: true,
          letterSpacing: 3.5,
          lineHeight: 1.6,
          fontWeight: FontWeight.w800,
        );

        expect(updated.textAlign, TextAlign.center);
        expect(updated.textVerticalAlign, TextVerticalAlign.center);
        expect(updated.textCase, TextCase.uppercase);
        expect(updated.isUnderline, isTrue);
        expect(updated.isStrikethrough, isTrue);
        expect(updated.letterSpacing, 3.5);
        expect(updated.lineHeight, 1.6);
        expect(updated.fontWeight, FontWeight.w800);
        expect(updated.isBold, isTrue);
      },
    );

    test('toSvgElement generates valid SVG with text-anchor, baseline, case, and spacing', () {
      final textShape = VectorShape(
        id: 'txt-1',
        name: 'Header',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(50, 50, 200, 50),
        textContent: 'creative title',
        textAlign: TextAlign.center,
        textVerticalAlign: TextVerticalAlign.center,
        textCase: TextCase.titleCase,
        isUnderline: true,
        letterSpacing: 2.0,
        fontWeight: FontWeight.bold,
      );

      final svg = textShape.toSvgElement();

      expect(svg.contains('text-anchor="middle"'), isTrue);
      expect(svg.contains('dominant-baseline="central"'), isTrue);
      expect(svg.contains('letter-spacing="2.0px"'), isTrue);
      expect(svg.contains('text-decoration="underline"'), isTrue);
      expect(svg.contains('font-weight="700"'), isTrue);
      expect(svg.contains('Creative Title'), isTrue);
    });

    test('toSvgElement exports uppercase and strikethrough correctly', () {
      final textShape = VectorShape(
        id: 'txt-2',
        name: 'Banner',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(50, 50, 200, 50),
        textContent: 'special discount',
        textAlign: TextAlign.right,
        textVerticalAlign: TextVerticalAlign.bottom,
        textCase: TextCase.uppercase,
        isStrikethrough: true,
      );

      final svg = textShape.toSvgElement();

      expect(svg.contains('text-anchor="end"'), isTrue);
      expect(svg.contains('dominant-baseline="auto"'), isTrue);
      expect(svg.contains('text-decoration="line-through"'), isTrue);
      expect(svg.contains('SPECIAL DISCOUNT'), isTrue);
    });
  });

  group('PropertiesSidebar Text Inspector UI', () {
    testWidgets('Renders all typography controls and updates text alignment', (
      tester,
    ) async {
      VectorShape currentShape = VectorShape(
        id: 'txt-1',
        name: 'Sample Text',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(100, 100, 250, 60),
        textContent: 'Interactive Typography',
      );

      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PropertiesSidebar(
                  selectedShape: currentShape,
                  onShapeChanged: (updated) {
                    setState(() => currentShape = updated);
                  },
                  onOpenColorPickerFill: () {},
                  onOpenColorPickerStroke: () {},
                  onDuplicateShape: () {},
                  onDeleteSelected: () {},
                  onAlignShape: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Typography headers are displayed
      expect(find.text('TYPOGRAPHY'), findsOneWidget);
      expect(find.text('TEXT ALIGNMENT'), findsOneWidget);
      expect(find.text('VERTICAL ALIGNMENT'), findsOneWidget);
      expect(find.text('TEXT CASE'), findsOneWidget);

      // Verify horizontal alignment icons
      expect(find.byIcon(RemixIcons.align_left), findsWidgets);
      expect(find.byIcon(RemixIcons.align_center), findsWidgets);
      expect(find.byIcon(RemixIcons.align_right), findsWidgets);
      expect(find.byIcon(RemixIcons.align_justify), findsOneWidget);

      // Tap Center Alignment in TEXT ALIGNMENT row
      final alignCenterFinder = find.byTooltip('Text Align Center');
      expect(alignCenterFinder, findsOneWidget);
      await tester.tap(alignCenterFinder);
      await tester.pumpAndSettle();

      expect(currentShape.textAlign, TextAlign.center);

      // Tap Right Alignment
      final alignRightFinder = find.byTooltip('Text Align Right');
      expect(alignRightFinder, findsOneWidget);
      await tester.tap(alignRightFinder);
      await tester.pumpAndSettle();

      expect(currentShape.textAlign, TextAlign.right);

      // Tap Vertical Middle Alignment
      final verticalMiddleFinder = find.byTooltip('Text Align Middle');
      expect(verticalMiddleFinder, findsOneWidget);
      await tester.tap(verticalMiddleFinder);
      await tester.pumpAndSettle();

      expect(currentShape.textVerticalAlign, TextVerticalAlign.center);

      // Tap UPPERCASE Text Case
      final uppercaseFinder = find.byTooltip('UPPERCASE');
      expect(uppercaseFinder, findsOneWidget);
      await tester.tap(uppercaseFinder);
      await tester.pumpAndSettle();

      expect(currentShape.textCase, TextCase.uppercase);

      // Tap Underline Toggle
      final underlineFinder = find.byTooltip('Underline');
      expect(underlineFinder, findsOneWidget);
      await tester.tap(underlineFinder);
      await tester.pumpAndSettle();

      expect(currentShape.isUnderline, isTrue);

      // Tap Strikethrough Toggle
      final strikeFinder = find.byTooltip('Strikethrough');
      expect(strikeFinder, findsOneWidget);
      await tester.tap(strikeFinder);
      await tester.pumpAndSettle();

      expect(currentShape.isStrikethrough, isTrue);
    });

    test('TextPainter layout bounds span the entire shape width for accurate center and right alignment', () {
      const rectWidth = 300.0;
      const sampleText = 'nixSVG Studio';
      const textStyle = TextStyle(fontSize: 16.0);

      // Left aligned
      final painterLeft = TextPainter(
        text: const TextSpan(text: sampleText, style: textStyle),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: rectWidth, maxWidth: rectWidth);

      // Center aligned
      final painterCenter = TextPainter(
        text: const TextSpan(text: sampleText, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: rectWidth, maxWidth: rectWidth);

      // Right aligned
      final painterRight = TextPainter(
        text: const TextSpan(text: sampleText, style: textStyle),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: rectWidth, maxWidth: rectWidth);

      expect(painterLeft.width, rectWidth);
      expect(painterCenter.width, rectWidth);
      expect(painterRight.width, rectWidth);

      final leftBox = painterLeft
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: sampleText.length),
          )
          .first
          .toRect();

      final centerBox = painterCenter
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: sampleText.length),
          )
          .first
          .toRect();

      final rightBox = painterRight
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: sampleText.length),
          )
          .first
          .toRect();

      // Left starts at 0
      expect(leftBox.left, closeTo(0.0, 1.0));
      // Right ends at rectWidth
      expect(rightBox.right, closeTo(rectWidth, 1.0));
      // Center center matches rectWidth / 2
      expect(centerBox.center.dx, closeTo(rectWidth / 2, 2.0));
      // Center box left is > leftBox.left and < rightBox.left
      expect(centerBox.left > leftBox.left, isTrue);
      expect(rightBox.left > centerBox.left, isTrue);
    });

    test('VectorCanvasPainter paints text with all alignments successfully on Canvas', () {
      final textLeft = VectorShape(
        id: 'txt-left',
        name: 'Left',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(100, 100, 300, 60),
        textContent: 'Left Aligned Text',
        textAlign: TextAlign.left,
        textVerticalAlign: TextVerticalAlign.top,
      );
      final textCenter = VectorShape(
        id: 'txt-center',
        name: 'Center',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(100, 200, 300, 60),
        textContent: 'Center Aligned Text',
        textAlign: TextAlign.center,
        textVerticalAlign: TextVerticalAlign.center,
      );
      final textRight = VectorShape(
        id: 'txt-right',
        name: 'Right',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(100, 300, 300, 60),
        textContent: 'Right Aligned Text',
        textAlign: TextAlign.right,
        textVerticalAlign: TextVerticalAlign.bottom,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = VectorCanvasPainter(
        shapes: [textLeft, textCenter, textRight],
        selectedShapeIds: {'txt-center'},
        currentMode: EditorMode.select,
        colorScheme: const ColorScheme.dark(),
      );

      expect(
        () => painter.paint(canvas, const Size(1000, 1000)),
        returnsNormally,
      );
      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}
