import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/ui/canvas/canvas_inline_text_editor.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';

void main() {
  group('Canvas Inline Text Editing Tests (Figma Experience)', () {
    testWidgets(
      'CanvasInlineTextEditor displays shape text and triggers callbacks',
      (tester) async {
        final shape = VectorShape(
          id: 'txt-1',
          name: 'Heading',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(100, 100, 200, 50),
          textContent: 'Initial Text',
          fontSize: 20.0,
        );

        String? updatedText;
        bool committed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CanvasInlineTextEditor(
                    shape: shape,
                    onTextChanged: (val) => updatedText = val,
                    onCommit: () => committed = true,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify TextField displays the initial text
        expect(find.text('Initial Text'), findsOneWidget);

        // Enter new text directly
        await tester.enterText(find.byType(TextField), 'Figma Canvas Text');
        await tester.pumpAndSettle();

        expect(updatedText, 'Figma Canvas Text');

        // Test Escape commits editing
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(committed, isTrue);
      },
    );

    testWidgets(
      'CanvasInlineTextEditor auto-expands rect when text exceeds width',
      (tester) async {
        final shape = VectorShape(
          id: 'txt-narrow',
          name: 'Narrow Text',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(50, 50, 60, 30),
          textContent: 'Hi',
          fontSize: 24.0,
        );

        Rect? expandedRect;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CanvasInlineTextEditor(
                    shape: shape,
                    onTextChanged: (_) {},
                    onCommit: () {},
                    onRectChanged: (rect) => expandedRect = rect,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter a long string that definitely exceeds 60px width
        await tester.enterText(
          find.byType(TextField),
          'This is a long line of vector text that overflows the original box',
        );
        await tester.pumpAndSettle();

        expect(expandedRect, isNotNull);
        expect(expandedRect!.width, greaterThan(60.0));
      },
    );

    test('VectorCanvasPainter respects editingShapeId by skipping static text painting', () {
      final textShape = VectorShape(
        id: 'txt-edit',
        name: 'Editable Text',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(100, 100, 200, 50),
        textContent: 'Hidden On Edit',
      );

      final painterNormal = VectorCanvasPainter(
        shapes: [textShape],
        selectedShapeIds: {textShape.id},
        currentMode: EditorMode.select,
        colorScheme: const ColorScheme.light(),
      );

      final painterEditing = VectorCanvasPainter(
        shapes: [textShape],
        selectedShapeIds: {textShape.id},
        currentMode: EditorMode.select,
        colorScheme: const ColorScheme.light(),
        editingShapeId: textShape.id,
      );

      expect(painterEditing.editingShapeId, 'txt-edit');
      expect(painterNormal.shouldRepaint(painterEditing), isTrue);
    });

    testWidgets(
      'Double-clicking text shape on canvas activates inline editor in FigmaWorkspace',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final textShape = VectorShape(
          id: 'shape-doubleclick',
          name: 'Double Click Me',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(100, 100, 200, 50),
          textContent: 'Double Click Target',
        );

        final project = ProjectModel(
          id: 'proj-doubleclick',
          name: 'Double Click Test',
          shapes: [textShape],
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FigmaWorkspace(initialProject: project)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify no inline text editor is initially open
        expect(find.byType(CanvasInlineTextEditor), findsNothing);

        final canvasOrigin = tester.getTopLeft(find.byType(InteractiveCanvas));
        final targetScreenPoint = canvasOrigin + textShape.rect.center;

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: targetScreenPoint);
        addTearDown(gesture.removePointer);

        // First click
        await gesture.down(targetScreenPoint);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 50));

        // Second click (within 350ms window)
        await gesture.down(targetScreenPoint);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        // Verify inline editor is now active on the canvas!
        expect(find.byType(CanvasInlineTextEditor), findsOneWidget);
        expect(find.text('Double Click Target'), findsOneWidget);

        final canvasTextField = find.descendant(
          of: find.byType(CanvasInlineTextEditor),
          matching: find.byType(TextField),
        );

        // Type directly into canvas
        await tester.enterText(canvasTextField, 'Modified Inline Text');
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );
        expect(state.shapes.first.textContent, 'Modified Inline Text');

        // Press Escape to commit
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Editor overlay is dismissed and committed
        expect(find.byType(CanvasInlineTextEditor), findsNothing);
        expect(state.shapes.first.textContent, 'Modified Inline Text');
      },
    );

    testWidgets('Clicking with Text tool opens inline editor ready to write', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final project = ProjectModel(
        id: 'proj-texttool',
        name: 'Text Tool Test',
        shapes: [],
        lastModified: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: FigmaWorkspace(initialProject: project)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Activate Text tool with keyboard shortcut 'T'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();

      final canvasOrigin = tester.getTopLeft(find.byType(InteractiveCanvas));
      final clickPoint = canvasOrigin + const Offset(150, 150);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: clickPoint);
      addTearDown(gesture.removePointer);

      await gesture.down(clickPoint);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      // Inline editor should open immediately ready for writing!
      expect(find.byType(CanvasInlineTextEditor), findsOneWidget);

      final canvasTextField = find.descendant(
        of: find.byType(CanvasInlineTextEditor),
        matching: find.byType(TextField),
      );

      // Type on the canvas
      await tester.enterText(canvasTextField, 'Freshly Created Canvas Text');
      await tester.pumpAndSettle();

      // Press Escape to commit
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(CanvasInlineTextEditor), findsNothing);

      final state = tester.state<FigmaWorkspaceState>(
        find.byType(FigmaWorkspace),
      );
      expect(state.shapes.length, 1);
      expect(state.shapes.first.textContent, 'Freshly Created Canvas Text');
    });

    testWidgets(
      'Empty freshly created text shape is cleanly removed when committed without typing',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final project = ProjectModel(
          id: 'proj-emptytext',
          name: 'Empty Text Test',
          shapes: [],
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FigmaWorkspace(initialProject: project)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Press 'T' for text tool
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.pumpAndSettle();

        final canvasOrigin = tester.getTopLeft(find.byType(InteractiveCanvas));
        final clickPoint = canvasOrigin + const Offset(200, 200);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: clickPoint);
        addTearDown(gesture.removePointer);

        await gesture.down(clickPoint);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(CanvasInlineTextEditor), findsOneWidget);

        // Press Escape without typing anything
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(CanvasInlineTextEditor), findsNothing);

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );
        // Cleanly removed like Figma!
        expect(state.shapes, isEmpty);
      },
    );

    testWidgets(
      'Clicking with Text tool on an existing text shape opens it for editing',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final existingShape = VectorShape(
          id: 'txt-existing',
          name: 'Existing Text',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(120, 120, 200, 40),
          textContent: 'Existing Content',
        );

        final project = ProjectModel(
          id: 'proj-clickexisting',
          name: 'Click Existing Test',
          shapes: [existingShape],
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FigmaWorkspace(initialProject: project)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Select Text tool (T)
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
        await tester.pumpAndSettle();

        final canvasOrigin = tester.getTopLeft(find.byType(InteractiveCanvas));
        final shapeCenterScreen = canvasOrigin + existingShape.rect.center;

        // Single click on existing text shape with Text tool
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: shapeCenterScreen);
        addTearDown(gesture.removePointer);

        await gesture.down(shapeCenterScreen);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        // Inline editor should open immediately on existing shape!
        expect(find.byType(CanvasInlineTextEditor), findsOneWidget);
        expect(find.text('Existing Content'), findsOneWidget);
      },
    );

    testWidgets(
      'Pasting a text element auto-focuses text field ready to write',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final textShape = VectorShape(
          id: 'txt-copy-source',
          name: 'Copied Text',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(100, 100, 200, 40),
          textContent: 'Copy Paste Me',
        );

        final project = ProjectModel(
          id: 'proj-paste-test',
          name: 'Paste Test',
          shapes: [textShape],
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FigmaWorkspace(initialProject: project)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );

        // Select the text shape
        state.selectShape(textShape.id);
        await tester.pumpAndSettle();

        // Copy with Ctrl+C
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        // Paste with Ctrl+V
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        // The pasted text element should immediately have CanvasInlineTextEditor active and auto-focused!
        expect(find.byType(CanvasInlineTextEditor), findsOneWidget);
        final textFieldFinder = find.descendant(
          of: find.byType(CanvasInlineTextEditor),
          matching: find.byType(TextField),
        );
        expect(textFieldFinder, findsOneWidget);

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.focusNode?.hasFocus, isTrue);

        // Type immediately without any additional clicks
        await tester.enterText(textFieldFinder, 'Brand New Pasted Content');
        await tester.pumpAndSettle();

        expect(state.shapes.last.textContent, 'Brand New Pasted Content');
      },
    );

    testWidgets(
      'Clicking on already selected text element auto-focuses text field ready to write',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final textShape = VectorShape(
          id: 'txt-click-selected',
          name: 'Selected Text',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(150, 150, 200, 40),
          textContent: 'Click When Selected',
        );

        final project = ProjectModel(
          id: 'proj-click-selected-test',
          name: 'Click Selected Test',
          shapes: [textShape],
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FigmaWorkspace(initialProject: project)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );

        // Initially select the shape
        state.selectShape(textShape.id);
        await tester.pumpAndSettle();
        expect(find.byType(CanvasInlineTextEditor), findsNothing);

        final canvasOrigin = tester.getTopLeft(find.byType(InteractiveCanvas));
        final clickLocation = canvasOrigin + textShape.rect.center;

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: clickLocation);
        addTearDown(gesture.removePointer);

        await gesture.down(clickLocation);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        // CanvasInlineTextEditor opens and is focused ready to write!
        expect(find.byType(CanvasInlineTextEditor), findsOneWidget);
        final textFieldFinder = find.descendant(
          of: find.byType(CanvasInlineTextEditor),
          matching: find.byType(TextField),
        );
        expect(textFieldFinder, findsOneWidget);
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.focusNode?.hasFocus, isTrue);
      },
    );

    testWidgets(
      'Pressing Enter on selected text shape auto-focuses text field ready to write',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final textShape = VectorShape(
          id: 'txt-enter-key',
          name: 'Enter Key Text',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(150, 150, 200, 40),
          textContent: 'Press Enter On Me',
        );

        final project = ProjectModel(
          id: 'proj-enter-test',
          name: 'Enter Test',
          shapes: [textShape],
          lastModified: DateTime.now(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FigmaWorkspace(initialProject: project)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<FigmaWorkspaceState>(
          find.byType(FigmaWorkspace),
        );
        state.selectShape(textShape.id);
        await tester.pumpAndSettle();
        expect(find.byType(CanvasInlineTextEditor), findsNothing);

        // Press Enter
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Editor is open and auto-focused!
        expect(find.byType(CanvasInlineTextEditor), findsOneWidget);
        final textFieldFinder = find.descendant(
          of: find.byType(CanvasInlineTextEditor),
          matching: find.byType(TextField),
        );
        expect(textFieldFinder, findsOneWidget);
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.focusNode?.hasFocus, isTrue);
      },
    );
  });
}
