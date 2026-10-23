import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/services/safe_file_picker.dart';

void main() {
  group('SafeFilePicker and ZenityFallback Tests', () {
    testWidgets('ZenityMissingFallbackDialog renders explanation, command box, and inputs', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZenityMissingFallbackDialog(
              allowedExtensions: ['svg', 'png', 'jpg'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and explanation text
      expect(find.text('Native File Picker Missing (Zenity)'), findsOneWidget);
      expect(
        find.textContaining('Linux desktop file dialogs require the zenity package.'),
        findsOneWidget,
      );

      // Check command snippet
      expect(find.text('sudo apt install -y zenity'), findsOneWidget);

      // Check manual file path field
      expect(find.byType(TextField), findsOneWidget);

      // Check buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Import File'), findsOneWidget);
    });

    testWidgets('Submitting valid file path in ZenityMissingFallbackDialog loads bytes', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Create a temporary dummy SVG file
      final tempDir = io.Directory.systemTemp.createTempSync('nixsvg_test_');
      final tempFile = io.File('${tempDir.path}/sample_icon.svg');
      tempFile.writeAsStringSync('<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="40"/></svg>');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      dynamic dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog(
                    context: context,
                    builder: (_) => const ZenityMissingFallbackDialog(
                      allowedExtensions: ['svg', 'png'],
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Enter path into textfield
      await tester.enterText(find.byType(TextField), tempFile.path);
      await tester.pumpAndSettle();

      // Tap Import File
      await tester.ensureVisible(find.text('Import File'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import File'));
      await tester.pumpAndSettle();

      expect(dialogResult, isNotNull);
      expect(dialogResult.files.length, 1);
      expect(dialogResult.files.first.name, 'sample_icon.svg');
      expect(dialogResult.files.first.bytes, isNotNull);
      expect(dialogResult.files.first.bytes.length, greaterThan(0));
    });
  });
}
