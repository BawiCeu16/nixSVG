import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/calculations/canvas_transform.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/undo_redo_manager.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/providers/app_settings_provider.dart';
import 'package:nixsvg/providers/project_provider.dart';
import 'package:nixsvg/providers/workspace_settings_provider.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:nixsvg/theme/components/responsive_layout_tokens.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';
import 'package:nixsvg/ui/widgets/sidebar_resize_handle.dart';
import 'package:nixsvg/widgets/color_picker_dialog.dart';
import 'package:nixsvg/widgets/export_dialog.dart';
import 'package:nixsvg/widgets/floating_tool_bar.dart';
import 'package:nixsvg/widgets/layers_sidebar.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';
import 'package:nixsvg/widgets/settings_dialog.dart';
import 'package:nixsvg/widgets/shortcuts_dialog.dart';
import 'package:nixsvg/widgets/top_navigation_bar.dart';

void ensureFilePickerInitialized() {
  try {
    final _ = FilePicker.platform;
  } catch (_) {
    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.linux:
          FilePickerLinux.registerWith();
          break;
        case TargetPlatform.macOS:
          FilePickerMacOS.registerWith();
          break;
        case TargetPlatform.windows:
          try {
            (FilePickerWindows as dynamic).registerWith();
          } catch (_) {
            FilePickerIO.registerWith();
          }
          break;
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.fuchsia:
          FilePickerIO.registerWith();
          break;
      }
    }
  }
}

class FigmaWorkspace extends ConsumerStatefulWidget {
  final ProjectModel? initialProject;
  final VoidCallback? onGoToHome;

  const FigmaWorkspace({super.key, this.initialProject, this.onGoToHome});

  @override
  ConsumerState<FigmaWorkspace> createState() => FigmaWorkspaceState();
}

class FigmaWorkspaceState extends ConsumerState<FigmaWorkspace> {
  // Canvas State
  final TransformationController _transformationController =
      TransformationController();
  TransformationController get transformationController =>
      _transformationController;
  List<VectorShape> shapes = [];
  final Set<String> selectedShapeIds = {};
  EditorMode currentMode = EditorMode.select;

  // History & File
  final UndoRedoManager _undoRedoManager = UndoRedoManager();
  String fileName = 'nix_vector_design';
  bool get snapToGrid => ref.read(appSettingsProvider).snapToGrid;
  double get gridSpacing => ref.read(appSettingsProvider).gridSpacing;
  Color? canvasBackgroundColor;

  void _selectAll() {
    if (shapes.isEmpty) return;
    setState(() {
      selectedShapeIds.clear();
      selectedShapeIds.addAll(shapes.map((s) => s.id));
    });
  }

  void _resetZoom() {
    setState(() => _transformationController.value = Matrix4.identity());
  }

  // Sidebar Resize & Visibility State
  double layersSidebarWidth = 270.0;
  double propertiesSidebarWidth = 280.0;
  bool? isLayersPanelOpen;
  bool? isPropertiesPanelOpen;

  // Dragging / Interacting State
  Offset? panStartOffset;
  Offset? panCurrentOffset;
  Map<String, Rect>? initialShapeRects;
  ResizeHandle activeResizeHandle = ResizeHandle.none;
  bool isMovingShapes = false;
  bool isRotatingShape = false;
  Rect? marqueeRect;
  Set<String> _initialMarqueeSelectedIds = {};
  Offset? snapGuidelineX;
  Offset? snapGuidelineY;
  bool _isPanningWithMouse = false;
  bool _isSpacePressed = false;
  bool _isMouseOverCanvas = false;
  Offset? _lastPanPosition;
  Offset? _lastMouseCanvasPosition;
  Offset? _lastGlobalMousePosition;
  final GlobalKey _canvasKey = GlobalKey();
  final FocusNode _workspaceFocusNode = FocusNode(debugLabel: 'WorkspaceFocus');

  // Inline Canvas Text Editing State
  String? _editingTextShapeId;
  bool _isEditingNewText = false;
  bool _selectAllText = false;
  DateTime? _lastPointerDownTime;
  Offset? _lastPointerDownPos;

  bool get isSpacePressed =>
      _isSpacePressed ||
      (!_isTextInputFocused() &&
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.space,
          ));

  // Creation Draft
  ShapeType? draftShapeType;
  int _shapeCounter = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialProject != null) {
      fileName = widget.initialProject!.name;
      shapes = widget.initialProject!.shapes.map((s) => s.copyWith()).toList();
    } else {
      _loadSampleDemoShapes();
    }
    _saveHistorySnapshot();

    // Initialize persisted workspace settings from Riverpod
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsSettings = ref.read(workspaceSettingsProvider);
      final appSettings = ref.read(appSettingsProvider);
      setState(() {
        layersSidebarWidth = appSettings.layersSidebarWidth;
        propertiesSidebarWidth = appSettings.propertiesSidebarWidth;
        isLayersPanelOpen = appSettings.showLayers;
        isPropertiesPanelOpen = appSettings.showProperties;
        if (widget.initialProject == null) {
          fileName = wsSettings.fileName;
        }
      });
      _persistCurrentProject();
    });
  }

  @override
  void dispose() {
    _workspaceFocusNode.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _loadSampleDemoShapes() {
    shapes = [
      VectorShape(
        id: 'shape-1',
        name: 'Background Card',
        type: ShapeType.roundedRectangle,
        rect: const Rect.fromLTWH(200, 150, 480, 280),
        fillColor: const Color(0xFF1E293B),
        fillOpacity: 0.9,
        strokeColor: const Color(0xFF6366F1),
        strokeWidth: 2.0,
        isStroked: true,
        cornerRadius: 20.0,
      ),
      VectorShape(
        id: 'shape-2',
        name: 'Accent Star',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(580, 180, 70, 70),
        fillColor: const Color(0xFFF59E0B),
        strokeColor: const Color(0xFFFBBF24),
        isStroked: true,
      ),
      VectorShape(
        id: 'shape-3',
        name: 'Hero Logo Ellipse',
        type: ShapeType.ellipse,
        rect: const Rect.fromLTWH(240, 190, 80, 80),
        fillColor: const Color(0xFF6366F1),
        strokeColor: const Color(0xFF818CF8),
        strokeWidth: 3.0,
        isStroked: true,
      ),
      VectorShape(
        id: 'shape-4',
        name: 'Title Text',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(340, 205, 300, 50),
        fillColor: Colors.white,
        textContent: 'nixSVG Studio',
        fontSize: 32.0,
      ),
      VectorShape(
        id: 'shape-5',
        name: 'Subtitle Text',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(342, 255, 300, 30),
        fillColor: const Color(0xFF94A3B8),
        textContent: 'Professional Vector Graphics Engine',
        fontSize: 14.0,
      ),
      VectorShape(
        id: 'shape-6',
        name: 'Divider Line',
        type: ShapeType.line,
        rect: const Rect.fromLTWH(240, 300, 400, 0),
        strokeColor: const Color(0xFF334155),
        strokeWidth: 2.0,
        isStroked: true,
      ),
    ];
    _shapeCounter = 7;
  }

  void _saveHistorySnapshot() {
    _undoRedoManager.saveState(shapes);
    _persistCurrentProject();
  }

  void _persistCurrentProject() {
    final project =
        (widget.initialProject ?? ProjectModel.createNew(name: fileName))
            .copyWith(
              name: fileName,
              lastModified: DateTime.now(),
              shapes: shapes.map((s) => s.copyWith()).toList(),
            );
    ref.read(projectsProvider.notifier).updateActiveProject(project);
  }

  void _handleGoToHome() {
    _persistCurrentProject();
    if (widget.onGoToHome != null) {
      widget.onGoToHome!();
    } else {
      ref.read(projectsProvider.notifier).closeActiveProject();
    }
  }

  void _undo() {
    _stopTextEditing(commit: true);
    final previous = _undoRedoManager.undo();
    if (previous != null) {
      setState(() {
        shapes = previous;
        selectedShapeIds.clear();
      });
    }
  }

  void _redo() {
    _stopTextEditing(commit: true);
    final next = _undoRedoManager.redo();
    if (next != null) {
      setState(() {
        shapes = next;
        selectedShapeIds.clear();
      });
    }
  }

  void _startTextEditing(
    VectorShape shape, {
    bool isNew = false,
    bool selectAll = false,
  }) {
    setState(() {
      _editingTextShapeId = shape.id;
      _isEditingNewText = isNew;
      _selectAllText = selectAll;
      selectedShapeIds.clear();
      selectedShapeIds.add(shape.id);
      currentMode = EditorMode.select;
    });
  }

  void _stopTextEditing({bool commit = true}) {
    if (_editingTextShapeId == null) return;
    final editingId = _editingTextShapeId!;
    final editingShape = shapes.cast<VectorShape?>().firstWhere(
      (s) => s?.id == editingId,
      orElse: () => null,
    );

    setState(() {
      if (commit && editingShape != null) {
        if (_isEditingNewText && editingShape.textContent.trim().isEmpty) {
          shapes.removeWhere((s) => s.id == editingId);
          selectedShapeIds.remove(editingId);
        } else {
          if (_isEditingNewText && editingShape.textContent.isNotEmpty) {
            final style = editingShape.getTextStyle();
            final tp = TextPainter(
              text: TextSpan(text: editingShape.textContent, style: style),
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            editingShape.rect = Rect.fromLTWH(
              editingShape.rect.left,
              editingShape.rect.top,
              math.max(24.0, tp.width + 4.0),
              math.max(18.0, tp.height),
            );
          }
          editingShape.invalidateCache();
          _saveHistorySnapshot();
        }
      }
      _editingTextShapeId = null;
      _isEditingNewText = false;
      _selectAllText = false;
    });
    _workspaceFocusNode.requestFocus();
  }

  // Pointer Down / Move / Up / Cancel Gestures
  void _onPointerDown(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
    _workspaceFocusNode.requestFocus();
    final isMiddleButton = (event.buttons & kMiddleMouseButton) != 0;
    final isPan =
        _isSpacePressed ||
        isMiddleButton ||
        currentMode == EditorMode.pan ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.space,
        );

    _lastGlobalMousePosition = event.position;
    if (isPan) {
      _isPanningWithMouse = true;
      _lastPanPosition = event.position;
      setState(() {});
      return;
    }

    final localPos = event.localPosition;
    _lastMouseCanvasPosition = localPos;
    panStartOffset = localPos;
    panCurrentOffset = localPos;

    // Check if clicked inside active inline text editor
    if (_editingTextShapeId != null) {
      final editingShape = shapes.cast<VectorShape?>().firstWhere(
        (s) => s?.id == _editingTextShapeId,
        orElse: () => null,
      );
      if (editingShape != null &&
          CanvasHitTester.hitTestShape(localPos, editingShape)) {
        return;
      }
      _stopTextEditing(commit: true);
    }

    // Detect double-click on text shape to edit text like Figma
    final now = DateTime.now();
    final isDoubleClick =
        _lastPointerDownTime != null &&
        now.difference(_lastPointerDownTime!) <
            const Duration(milliseconds: 350) &&
        _lastPointerDownPos != null &&
        (localPos - _lastPointerDownPos!).distance < 16.0;
    _lastPointerDownTime = now;
    _lastPointerDownPos = localPos;

    if (isDoubleClick) {
      VectorShape? hitTextShape;
      for (int i = shapes.length - 1; i >= 0; i--) {
        final s = shapes[i];
        if (s.type == ShapeType.text &&
            CanvasHitTester.hitTestShape(localPos, s)) {
          hitTextShape = s;
          break;
        }
      }
      if (hitTextShape != null) {
        _startTextEditing(hitTextShape, isNew: false, selectAll: true);
        return;
      }
    }

    if (currentMode == EditorMode.drawText) {
      VectorShape? hitTextShape;
      for (int i = shapes.length - 1; i >= 0; i--) {
        final s = shapes[i];
        if (s.type == ShapeType.text &&
            CanvasHitTester.hitTestShape(localPos, s)) {
          hitTextShape = s;
          break;
        }
      }
      if (hitTextShape != null) {
        _startTextEditing(hitTextShape, isNew: false, selectAll: true);
        return;
      }
      draftShapeType = ShapeType.text;
      setState(() {});
      return;
    }

    if (currentMode == EditorMode.select) {
      // 1. Check if hit resize, rotation, or radius handle of selected shape(s)
      if (selectedShapeIds.length == 1) {
        final singleSelected = shapes.firstWhere(
          (s) => s.id == selectedShapeIds.first,
        );
        final zoomScale = CanvasTransformHelper.getScale(
          _transformationController.value,
        );
        if (!singleSelected.isLocked) {
          activeResizeHandle = CanvasHitTester.hitTestHandle(
            localPos,
            singleSelected,
            zoomScale: zoomScale,
          );
          if (activeResizeHandle != ResizeHandle.none) {
            initialShapeRects = {singleSelected.id: singleSelected.rect};
            if (activeResizeHandle == ResizeHandle.rotation) {
              isRotatingShape = true;
            }
            setState(() {});
            return;
          }
        }
      } else if (selectedShapeIds.length > 1) {
        final zoomScale = CanvasTransformHelper.getScale(
          _transformationController.value,
        );
        Rect? combinedBounds;
        for (final s in shapes) {
          if (selectedShapeIds.contains(s.id) && s.isVisible && !s.isLocked) {
            combinedBounds = combinedBounds == null
                ? s.rect
                : combinedBounds.expandToInclude(s.rect);
          }
        }
        if (combinedBounds != null) {
          final handle = CanvasHitTester.hitTestRectHandles(
            localPos,
            combinedBounds,
            zoomScale: zoomScale,
          );
          if (handle != ResizeHandle.none) {
            activeResizeHandle = handle;
            initialShapeRects = {
              for (final id in selectedShapeIds)
                id: shapes.firstWhere((s) => s.id == id).rect,
            };
            setState(() {});
            return;
          }
        }
      }

      // 2. Check if clicked inside existing unlocked shape
      VectorShape? hitShape;
      for (int i = shapes.length - 1; i >= 0; i--) {
        final shape = shapes[i];
        if (CanvasHitTester.hitTestShape(localPos, shape)) {
          hitShape = shape;
          break;
        }
      }

      if (hitShape != null) {
        final matchedShape = hitShape;

        final isShiftPressed =
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.shiftLeft,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.shiftRight,
            );

        // Figma style: Clicking on an already selected text element enters text editing immediately
        if (!isShiftPressed &&
            matchedShape.type == ShapeType.text &&
            selectedShapeIds.length == 1 &&
            selectedShapeIds.contains(matchedShape.id)) {
          _startTextEditing(matchedShape, isNew: false, selectAll: false);
          return;
        }

        setState(() {
          if (isShiftPressed) {
            if (selectedShapeIds.contains(matchedShape.id)) {
              selectedShapeIds.remove(matchedShape.id);
            } else {
              selectedShapeIds.add(matchedShape.id);
            }
          } else {
            if (!selectedShapeIds.contains(matchedShape.id)) {
              selectedShapeIds.clear();
              selectedShapeIds.add(matchedShape.id);
            }
          }

          if (selectedShapeIds.isNotEmpty) {
            final isAltPressed = HardwareKeyboard.instance.isAltPressed;
            if (isAltPressed) {
              _duplicateSelected(offset: Offset.zero);
            }
            isMovingShapes = true;
            initialShapeRects = {
              for (final id in selectedShapeIds)
                id: shapes.firstWhere((s) => s.id == id).rect,
            };
          }
        });
        return;
      }

      // 3. Clicked empty space -> clear selection & start marquee drag select
      final isShiftPressed =
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftLeft,
          ) ||
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftRight,
          );
      setState(() {
        if (isShiftPressed) {
          _initialMarqueeSelectedIds = Set<String>.from(selectedShapeIds);
        } else {
          selectedShapeIds.clear();
          _initialMarqueeSelectedIds.clear();
        }
        marqueeRect = Rect.fromPoints(localPos, localPos);
      });
    } else {
      // Draw modes
      draftShapeType = _getShapeTypeFromMode(currentMode);
      setState(() {});
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _lastGlobalMousePosition = event.position;
    if (_isPanningWithMouse && _lastPanPosition != null) {
      final delta = event.position - _lastPanPosition!;
      _lastPanPosition = event.position;
      _transformationController.value = CanvasTransformHelper.panMatrix(
        _transformationController.value,
        delta,
      );
      return;
    }

    if (panStartOffset == null) {
      _lastMouseCanvasPosition = event.localPosition;
      return;
    }

    final localPos = event.localPosition;
    _lastMouseCanvasPosition = localPos;
    final isShiftPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftRight,
        );
    panCurrentOffset = localPos;

    setState(() {
      if (currentMode == EditorMode.select) {
        if (marqueeRect != null) {
          marqueeRect = Rect.fromPoints(panStartOffset!, localPos);
          final marqueeHits = CanvasGeometry.calculateMarqueeSelection(
            marqueeRect: marqueeRect!,
            shapes: shapes,
          );
          selectedShapeIds.clear();
          if (isShiftPressed && _initialMarqueeSelectedIds.isNotEmpty) {
            selectedShapeIds.addAll(_initialMarqueeSelectedIds);
          }
          selectedShapeIds.addAll(marqueeHits);
        } else if (isRotatingShape && selectedShapeIds.length == 1) {
          final isShift = HardwareKeyboard.instance.isShiftPressed;
          final target = shapes.firstWhere(
            (s) => s.id == selectedShapeIds.first,
          );
          final center = target.rect.center;
          var angle =
              math.atan2(localPos.dy - center.dy, localPos.dx - center.dx) *
                  180 /
                  math.pi +
              90;
          if (isShift) {
            angle = (angle / 15).round() * 15;
          }
          target.rotation = (angle % 360).roundToDouble();
        } else if (activeResizeHandle.isRadius &&
            selectedShapeIds.length == 1) {
          final target = shapes.firstWhere(
            (s) => s.id == selectedShapeIds.first,
          );
          Offset testPos = localPos;
          if (target.rotation != 0.0) {
            final center = target.rect.center;
            final rad = -target.rotation * math.pi / 180.0;
            final cosVal = math.cos(rad);
            final sinVal = math.sin(rad);
            final dx = localPos.dx - center.dx;
            final dy = localPos.dy - center.dy;
            testPos = Offset(
              center.dx + dx * cosVal - dy * sinVal,
              center.dy + dx * sinVal + dy * cosVal,
            );
          }

          final rect = target.rect;
          final maxRadius = math.min(rect.width, rect.height) / 2;
          double dragDistance = 0.0;

          switch (activeResizeHandle) {
            case ResizeHandle.radiusTopLeft:
              final dx = testPos.dx - rect.left;
              final dy = testPos.dy - rect.top;
              dragDistance = (dx + dy) / 2;
              break;
            case ResizeHandle.radiusTopRight:
              final dx = rect.right - testPos.dx;
              final dy = testPos.dy - rect.top;
              dragDistance = (dx + dy) / 2;
              break;
            case ResizeHandle.radiusBottomLeft:
              final dx = testPos.dx - rect.left;
              final dy = rect.bottom - testPos.dy;
              dragDistance = (dx + dy) / 2;
              break;
            case ResizeHandle.radiusBottomRight:
              final dx = rect.right - testPos.dx;
              final dy = rect.bottom - testPos.dy;
              dragDistance = (dx + dy) / 2;
              break;
            default:
              break;
          }

          final newRadius = dragDistance.clamp(0.0, maxRadius);
          if (target.type == ShapeType.rectangle && newRadius > 0.0) {
            target.type = ShapeType.roundedRectangle;
          }
          target.cornerRadius = newRadius.roundToDouble();
          target.invalidateCache();
        } else if (activeResizeHandle != ResizeHandle.none &&
            selectedShapeIds.length == 1 &&
            initialShapeRects != null) {
          final target = shapes.firstWhere(
            (s) => s.id == selectedShapeIds.first,
          );
          final initialRect = initialShapeRects![target.id]!;
          if (target.type == ShapeType.line &&
              activeResizeHandle == ResizeHandle.topCenter) {
            final p1 = initialRect.topLeft;
            final p2 = initialRect.bottomRight;
            final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
            final dx = p2.dx - p1.dx;
            final dy = p2.dy - p1.dy;
            final len = math.sqrt(dx * dx + dy * dy);
            if (len > 0) {
              final perp = Offset(-dy / len, dx / len);
              final delta = localPos - mid;
              final newCurvature = delta.dx * perp.dx + delta.dy * perp.dy;
              target.curvature = newCurvature.clamp(-300.0, 300.0);
              target.isCurved = target.curvature.abs() > 0.5;
              target.invalidateCache();
            }
          } else {
            Offset unrotatedCurrent = localPos;
            if (target.rotation != 0.0) {
              final rad = -target.rotation * math.pi / 180.0;
              final cosVal = math.cos(rad);
              final sinVal = math.sin(rad);
              final dx = localPos.dx - panStartOffset!.dx;
              final dy = localPos.dy - panStartOffset!.dy;
              final localDx = dx * cosVal - dy * sinVal;
              final localDy = dx * sinVal + dy * cosVal;
              unrotatedCurrent = panStartOffset! + Offset(localDx, localDy);
            }
            target.rect = CanvasGeometry.resizeRect(
              initialRect,
              panStartOffset!,
              unrotatedCurrent,
              activeResizeHandle,
              isLine: target.type == ShapeType.line,
            );
            target.invalidateCache();
          }
        } else if (activeResizeHandle != ResizeHandle.none &&
            selectedShapeIds.length > 1 &&
            initialShapeRects != null) {
          Rect? initialCombined;
          for (final id in selectedShapeIds) {
            final r = initialShapeRects![id];
            if (r != null) {
              initialCombined = initialCombined == null
                  ? r
                  : initialCombined.expandToInclude(r);
            }
          }
          if (initialCombined != null &&
              initialCombined.width > 0 &&
              initialCombined.height > 0) {
            final newCombined = CanvasGeometry.resizeRect(
              initialCombined,
              panStartOffset!,
              localPos,
              activeResizeHandle,
            );
            final scaleX = newCombined.width / initialCombined.width;
            final scaleY = newCombined.height / initialCombined.height;
            for (final id in selectedShapeIds) {
              final s = shapes.firstWhere((shape) => shape.id == id);
              final initR = initialShapeRects![id]!;
              final relLeft = (initR.left - initialCombined.left) * scaleX;
              final relTop = (initR.top - initialCombined.top) * scaleY;
              final newW = initR.width * scaleX;
              final newH = initR.height * scaleY;
              s.rect = Rect.fromLTWH(
                newCombined.left + relLeft,
                newCombined.top + relTop,
                math.max(4.0, newW),
                math.max(4.0, newH),
              );
              s.invalidateCache();
            }
          }
        } else if (isMovingShapes && initialShapeRects != null) {
          var delta = localPos - panStartOffset!;
          final appSettings = ref.read(appSettingsProvider);
          if (appSettings.snapToGrid) {
            final snapStep = (appSettings.gridSpacing > 0)
                ? appSettings.gridSpacing / 4
                : 10.0;
            delta = Offset(
              (delta.dx / snapStep).round() * snapStep,
              (delta.dy / snapStep).round() * snapStep,
            );
          }
          if (appSettings.smartGuides) {
            final zoomScale = CanvasTransformHelper.getScale(
              _transformationController.value,
            );
            final snapRes = CanvasGeometry.calculateSnapGuidelines(
              shapes: shapes,
              selectedShapeIds: selectedShapeIds,
              initialShapeRects: initialShapeRects,
              proposedDelta: delta,
              snapThreshold: 6.0 / (zoomScale > 0 ? zoomScale : 1.0),
            );
            if (snapRes.snapDelta != Offset.zero) {
              delta += snapRes.snapDelta;
            }
            snapGuidelineX = snapRes.guidelineX;
            snapGuidelineY = snapRes.guidelineY;
          } else {
            snapGuidelineX = null;
            snapGuidelineY = null;
          }
          for (final id in selectedShapeIds) {
            final s = shapes.firstWhere((s) => s.id == id);
            final initR = initialShapeRects![id]!;
            s.rect = initR.shift(delta);
          }
        }
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPanningWithMouse) {
      setState(() {
        _isPanningWithMouse = false;
        _lastPanPosition = null;
      });
      return;
    }

    if (panStartOffset == null) return;

    final localPos = event.localPosition;

    if (currentMode != EditorMode.select && draftShapeType != null) {
      final isShiftPressed =
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftLeft,
          ) ||
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftRight,
          );
      final isAltPressed = HardwareKeyboard.instance.isAltPressed;

      final rect = CanvasGeometry.calculateDrawRect(
        start: panStartOffset!,
        current: localPos,
        shapeType: draftShapeType!,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      );

      Rect finalRect = rect;
      bool isValidShape = false;

      if (draftShapeType == ShapeType.line) {
        if ((rect.bottomRight - rect.topLeft).distance <= 5) {
          finalRect = Rect.fromLTRB(
            panStartOffset!.dx,
            panStartOffset!.dy,
            panStartOffset!.dx + 100,
            panStartOffset!.dy,
          );
        }
        isValidShape = true;
      } else if (draftShapeType == ShapeType.text) {
        if (finalRect.width <= 5 || finalRect.height <= 5) {
          finalRect = Rect.fromLTWH(
            panStartOffset!.dx,
            panStartOffset!.dy,
            48,
            24,
          );
        }
        isValidShape = true;
      } else {
        isValidShape = finalRect.width > 5 && finalRect.height > 5;
      }

      if (isValidShape) {
        final appSettings = ref.read(appSettingsProvider);
        final isCurveMode = currentMode == EditorMode.drawCurve;
        final isText = draftShapeType == ShapeType.text;
        final isRect = draftShapeType == ShapeType.roundedRectangle ||
            draftShapeType == ShapeType.rectangle;
        final newShape = VectorShape(
          id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
          name: '${_getModeName(currentMode)} $_shapeCounter',
          type: draftShapeType!,
          rect: finalRect,
          textContent: isText ? '' : 'Text Element',
          isStroked: draftShapeType == ShapeType.line ? true : false,
          isFilled: draftShapeType == ShapeType.line ? false : true,
          strokeWidth: appSettings.defaultStrokeWidth,
          cornerRadius: isRect ? appSettings.defaultCornerRadius : 0.0,
          isCurved: isCurveMode,
          curvature: isCurveMode ? 35.0 : 0.0,
        );
        _shapeCounter++;
        setState(() {
          shapes.add(newShape);
          selectedShapeIds.clear();
          selectedShapeIds.add(newShape.id);
          if (appSettings.autoSwitchToSelect) {
            currentMode = EditorMode.select;
          }
          if (isText) {
            _startTextEditing(newShape, isNew: true, selectAll: true);
          }
        });
        _saveHistorySnapshot();
      }
    } else if (isMovingShapes ||
        activeResizeHandle != ResizeHandle.none ||
        isRotatingShape) {
      _saveHistorySnapshot();
    }

    setState(() {
      panStartOffset = null;
      panCurrentOffset = null;
      initialShapeRects = null;
      activeResizeHandle = ResizeHandle.none;
      isMovingShapes = false;
      isRotatingShape = false;
      marqueeRect = null;
      _initialMarqueeSelectedIds.clear();
      draftShapeType = null;
      snapGuidelineX = null;
      snapGuidelineY = null;
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isPanningWithMouse) {
      setState(() {
        _isPanningWithMouse = false;
        _lastPanPosition = null;
      });
      return;
    }
    _initialMarqueeSelectedIds.clear();
    _onPointerUp(PointerUpEvent(position: event.position));
  }

  // Quick Action Helpers
  void _duplicateSelected({Offset offset = const Offset(20, 20)}) {
    if (selectedShapeIds.isEmpty) return;
    final newShapes = <VectorShape>[];
    final newIds = <String>{};

    for (final id in selectedShapeIds) {
      final orig = shapes.firstWhere((s) => s.id == id);
      final dup = orig.copyWith(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}',
        name: '${orig.name} Copy',
        rect: orig.rect.shift(offset),
      );
      newShapes.add(dup);
      newIds.add(dup.id);
    }

    setState(() {
      shapes.addAll(newShapes);
      selectedShapeIds.clear();
      selectedShapeIds.addAll(newIds);
      if (newShapes.length == 1 && newShapes.first.type == ShapeType.text) {
        _startTextEditing(newShapes.first, isNew: false, selectAll: true);
      }
    });
    _saveHistorySnapshot();
  }

  void _deleteSelected() {
    if (selectedShapeIds.isEmpty) return;
    if (_editingTextShapeId != null &&
        selectedShapeIds.contains(_editingTextShapeId)) {
      _stopTextEditing(commit: false);
    }
    setState(() {
      shapes = shapes.where((s) => !selectedShapeIds.contains(s.id)).toList();
      selectedShapeIds.clear();
    });
    _saveHistorySnapshot();
  }

  void _deleteShapeById(String id) {
    if (_editingTextShapeId == id) {
      _stopTextEditing(commit: false);
    }
    setState(() {
      shapes = shapes.where((s) => s.id != id).toList();
      selectedShapeIds.remove(id);
    });
    _saveHistorySnapshot();
  }

  void _alignShapes(String align) {
    CanvasGeometry.alignShapes(
      shapes: shapes,
      selectedIds: selectedShapeIds,
      align: align,
    );
    setState(() {});
    _saveHistorySnapshot();
  }

  void _bringForward() {
    if (selectedShapeIds.isEmpty) return;
    final sortedIds = selectedShapeIds.toList()
      ..sort(
        (a, b) => shapes
            .indexWhere((s) => s.id == b)
            .compareTo(shapes.indexWhere((s) => s.id == a)),
      );
    bool changed = false;
    setState(() {
      for (final id in sortedIds) {
        final index = shapes.indexWhere((s) => s.id == id);
        if (index != -1 && index < shapes.length - 1) {
          final shape = shapes.removeAt(index);
          shapes.insert(index + 1, shape);
          changed = true;
        }
      }
    });
    if (changed) _saveHistorySnapshot();
  }

  void _sendBackward() {
    if (selectedShapeIds.isEmpty) return;
    final sortedIds = selectedShapeIds.toList()
      ..sort(
        (a, b) => shapes
            .indexWhere((s) => s.id == a)
            .compareTo(shapes.indexWhere((s) => s.id == b)),
      );
    bool changed = false;
    setState(() {
      for (final id in sortedIds) {
        final index = shapes.indexWhere((s) => s.id == id);
        if (index > 0) {
          final shape = shapes.removeAt(index);
          shapes.insert(index - 1, shape);
          changed = true;
        }
      }
    });
    if (changed) _saveHistorySnapshot();
  }

  final List<VectorShape> _clipboard = [];

  void _copySelected() {
    if (selectedShapeIds.isEmpty) return;
    _clipboard.clear();
    for (final id in selectedShapeIds) {
      final s = shapes.firstWhere((shape) => shape.id == id);
      _clipboard.add(s.copyWith());
    }
  }

  void _cutSelected() {
    if (selectedShapeIds.isEmpty) return;
    _copySelected();
    _deleteSelected();
  }

  Future<void> _pasteClipboard() async {
    if (_clipboard.isNotEmpty) {
      final newShapes = <VectorShape>[];
      final newIds = <String>{};
      for (final orig in _clipboard) {
        final dup = orig.copyWith(
          id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}',
          name: '${orig.name} Copy',
          rect: orig.rect.shift(const Offset(20, 20)),
        );
        newShapes.add(dup);
        newIds.add(dup.id);
      }
      setState(() {
        shapes.addAll(newShapes);
        selectedShapeIds.clear();
        selectedShapeIds.addAll(newIds);
      });
      _saveHistorySnapshot();

      // If a single text element was pasted, auto-focus for ready to write like Figma!
      if (newShapes.length == 1 && newShapes.first.type == ShapeType.text) {
        _startTextEditing(newShapes.first, isNew: false, selectAll: true);
      }
      return;
    }

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;
      if (text != null && text.trim().isNotEmpty) {
        final focalPoint =
            (_isMouseOverCanvas && _lastMouseCanvasPosition != null)
            ? _lastMouseCanvasPosition!
            : _getViewportCanvasCenter();

        final newShape = VectorShape(
          id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Text $_shapeCounter',
          type: ShapeType.text,
          rect: Rect.fromLTWH(
            focalPoint.dx - 80,
            focalPoint.dy - 20,
            math.max(160.0, text.length * 10.0).clamp(160.0, 800.0),
            40,
          ),
          textContent: text,
        );
        _shapeCounter++;
        setState(() {
          shapes.add(newShape);
          selectedShapeIds.clear();
          selectedShapeIds.add(newShape.id);
          _startTextEditing(newShape, isNew: false, selectAll: true);
        });
        _saveHistorySnapshot();
      }
    } catch (e) {
      debugPrint('Error reading system clipboard: $e');
    }
  }

  void _flipHorizontal() {
    if (selectedShapeIds.isEmpty) return;
    setState(() {
      for (final id in selectedShapeIds) {
        final shape = shapes.firstWhere((s) => s.id == id);
        if (shape.type == ShapeType.line) {
          shape.rect = Rect.fromLTRB(
            shape.rect.right,
            shape.rect.top,
            shape.rect.left,
            shape.rect.bottom,
          );
        } else {
          shape.rotation = (-shape.rotation) % 360;
        }
      }
    });
    _saveHistorySnapshot();
  }

  void _flipVertical() {
    if (selectedShapeIds.isEmpty) return;
    setState(() {
      for (final id in selectedShapeIds) {
        final shape = shapes.firstWhere((s) => s.id == id);
        if (shape.type == ShapeType.line) {
          shape.rect = Rect.fromLTRB(
            shape.rect.left,
            shape.rect.bottom,
            shape.rect.right,
            shape.rect.top,
          );
        } else {
          shape.rotation = (180 - shape.rotation) % 360;
        }
      }
    });
    _saveHistorySnapshot();
  }

  Size _getCanvasViewportSize() {
    final canvasBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox != null &&
        canvasBox.hasSize &&
        canvasBox.size.width > 0 &&
        canvasBox.size.height > 0) {
      return canvasBox.size;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size ?? const Size(1280, 800);
  }

  Offset _getViewportCanvasCenter() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale <= 0.0 || scale.isNaN) return const Offset(1600, 1200);
    final tx = matrix.storage[12];
    final ty = matrix.storage[13];
    final size = _getCanvasViewportSize();
    final centerX = (size.width / 2 - tx) / scale;
    final centerY = (size.height / 2 - ty) / scale;
    return Offset(centerX, centerY);
  }

  Offset _getCurrentZoomFocalCanvasPoint() {
    final canvasBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox != null &&
        canvasBox.hasSize &&
        _lastGlobalMousePosition != null) {
      final localPos = canvasBox.globalToLocal(_lastGlobalMousePosition!);
      final size = canvasBox.size;
      // If cursor is within the canvas viewport bounds
      if (localPos.dx >= 0 &&
          localPos.dx <= size.width &&
          localPos.dy >= 0 &&
          localPos.dy <= size.height) {
        return CanvasTransformHelper.screenToCanvas(
          _transformationController.value,
          localPos,
        );
      }
    }

    // If cursor was recorded over the canvas viewport
    if (_isMouseOverCanvas && _lastMouseCanvasPosition != null) {
      return _lastMouseCanvasPosition!;
    }

    // If shapes are selected and cursor is outside canvas, zoom focused on selection center
    if (selectedShapeIds.isNotEmpty) {
      final selected = shapes
          .where((s) => selectedShapeIds.contains(s.id))
          .toList();
      if (selected.isNotEmpty) {
        Rect bounds = selected.first.rect;
        for (final s in selected.skip(1)) {
          bounds = bounds.expandToInclude(s.rect);
        }
        return bounds.center;
      }
    }

    // Fallback: zoom into last known canvas position or center of the viewport
    return _lastMouseCanvasPosition ?? _getViewportCanvasCenter();
  }

  void _updateMouseCanvasPositionFromGlobal() {
    final canvasBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox != null &&
        canvasBox.hasSize &&
        _lastGlobalMousePosition != null) {
      final localPos = canvasBox.globalToLocal(_lastGlobalMousePosition!);
      final size = canvasBox.size;
      if (localPos.dx >= 0 &&
          localPos.dx <= size.width &&
          localPos.dy >= 0 &&
          localPos.dy <= size.height) {
        _lastMouseCanvasPosition = CanvasTransformHelper.screenToCanvas(
          _transformationController.value,
          localPos,
        );
      }
    }
  }

  void _zoomIn() {
    final focalPoint = _getCurrentZoomFocalCanvasPoint();
    setState(() {
      _transformationController.value = CanvasTransformHelper.zoomAtCanvasPoint(
        _transformationController.value,
        focalPoint,
        1.2,
      );
    });
    _updateMouseCanvasPositionFromGlobal();
  }

  void _zoomOut() {
    final focalPoint = _getCurrentZoomFocalCanvasPoint();
    setState(() {
      _transformationController.value = CanvasTransformHelper.zoomAtCanvasPoint(
        _transformationController.value,
        focalPoint,
        1.0 / 1.2,
      );
    });
    _updateMouseCanvasPositionFromGlobal();
  }

  void _zoomToFit() {
    if (shapes.isEmpty) {
      setState(() => _transformationController.value = Matrix4.identity());
      return;
    }
    Rect bounds = shapes.first.rect;
    for (final s in shapes.skip(1)) {
      bounds = bounds.expandToInclude(s.rect);
    }
    final size = _getCanvasViewportSize();
    setState(() {
      _transformationController.value = CanvasTransformHelper.zoomToFit(
        bounds,
        size,
      );
    });
  }

  void _zoomToSelection() {
    if (selectedShapeIds.isEmpty) {
      _zoomToFit();
      return;
    }
    final selected = shapes
        .where((s) => selectedShapeIds.contains(s.id))
        .toList();
    if (selected.isEmpty) return;
    Rect bounds = selected.first.rect;
    for (final s in selected.skip(1)) {
      bounds = bounds.expandToInclude(s.rect);
    }
    final size = _getCanvasViewportSize();
    setState(() {
      _transformationController.value = CanvasTransformHelper.zoomToFit(
        bounds,
        size,
        padding: 60.0,
      );
    });
  }

  void _setZoomScale(double targetScale) {
    final currentScale = CanvasTransformHelper.getScale(
      _transformationController.value,
    );
    if (currentScale <= 0) return;
    final factor = targetScale / currentScale;
    final focalPoint = _getCurrentZoomFocalCanvasPoint();
    setState(() {
      _transformationController.value = CanvasTransformHelper.zoomAtCanvasPoint(
        _transformationController.value,
        focalPoint,
        factor,
      );
    });
    _updateMouseCanvasPositionFromGlobal();
  }

  void _togglePanMode() {
    setState(() {
      if (currentMode == EditorMode.pan) {
        currentMode = EditorMode.select;
      } else {
        currentMode = EditorMode.pan;
      }
    });
  }

  void _centerCanvas() {
    final size = _getCanvasViewportSize();
    const canvasWidth = 3200.0;
    const canvasHeight = 2400.0;
    final scale = CanvasTransformHelper.getScale(
      _transformationController.value,
    );
    final tx = (size.width - canvasWidth * scale) / 2;
    final ty = (size.height - canvasHeight * scale) / 2;
    final m = Matrix4.identity();
    m.storage[0] = scale;
    m.storage[5] = scale;
    m.storage[12] = tx;
    m.storage[13] = ty;
    setState(() {
      _transformationController.value = m;
    });
  }

  void _clearCanvas() {
    if (shapes.isEmpty) return;
    setState(() {
      shapes = [];
      selectedShapeIds.clear();
      _stopTextEditing(commit: false);
    });
    _saveHistorySnapshot();
  }

  Future<void> _importImageFromDevice() async {
    try {
      ensureFilePickerInitialized();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final decodedImage = frame.image;

          final double width = decodedImage.width.toDouble().clamp(100, 800);
          final double height = decodedImage.height.toDouble().clamp(100, 800);

          final newShape = VectorShape(
            id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
            name: 'Image ${file.name}',
            type: ShapeType.image,
            rect: Rect.fromLTWH(300, 200, width, height),
            imageBytes: bytes,
            decodedImage: decodedImage,
          );

          setState(() {
            shapes.add(newShape);
            selectedShapeIds.clear();
            selectedShapeIds.add(newShape.id);
          });
          _saveHistorySnapshot();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openExportDialog() {
    final settings = ref.read(appSettingsProvider);
    final svgCode = SvgExportService.generateSvg(
      shapes,
      includeXmlHeader: settings.svgIncludeXml,
      prettyPrint: settings.svgPrettyPrint,
      exportScale: settings.exportScale,
    );
    showDialog(
      context: context,
      builder: (context) =>
          ExportDialog(svgContent: svgCode, fileName: '$fileName.svg'),
    );
  }

  void _openShortcutsDialog() {
    showDialog(context: context, builder: (context) => const ShortcutsDialog());
  }

  void _openSettingsDialog() {
    showAppSettingsDialog(context);
  }

  Color _sampleShapeColorAtScreenPoint(Offset screenPos) {
    try {
      final canvasBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final viewportPos = canvasBox != null
          ? canvasBox.globalToLocal(screenPos)
          : screenPos;
      final canvasPos = CanvasTransformHelper.screenToCanvas(
        _transformationController.value,
        viewportPos,
      );

      for (int i = shapes.length - 1; i >= 0; i--) {
        final shape = shapes[i];
        if (shape.isVisible && CanvasHitTester.hitTestShape(canvasPos, shape)) {
          if (shape.fillType != PaintFillType.solid &&
              shape.fillGradient != null &&
              shape.fillGradient!.stops.isNotEmpty) {
            return shape.fillGradient!.stops.first.color;
          }
          return shape.fillColor;
        }
      }
      return canvasBackgroundColor ?? Colors.white;
    } catch (_) {
      return canvasBackgroundColor ?? Colors.white;
    }
  }

  Future<void> _pickColorFromScreen() async {
    Color? initialColor;
    if (selectedShapeIds.isNotEmpty) {
      final selected = shapes.cast<VectorShape?>().firstWhere(
        (s) => selectedShapeIds.contains(s?.id),
        orElse: () => null,
      );
      initialColor = selected?.fillColor;
    }

    final sampled = await NixEyedropper.pickColor(
      context: context,
      initialColor: initialColor ?? Colors.black,
      onSamplePixel: _sampleShapeColorAtScreenPoint,
    );

    if (sampled != null && mounted) {
      if (selectedShapeIds.isNotEmpty) {
        setState(() {
          shapes = List.of(shapes);
          for (final id in selectedShapeIds) {
            final s = shapes.firstWhere((shape) => shape.id == id);
            s.fillColor = sampled;
            s.fillType = PaintFillType.solid;
            s.invalidateCache();
          }
        });
        _saveHistorySnapshot();
      }
    }
  }

  void _openColorPicker(bool isFill, [Rect? anchorRect]) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (selectedShapeIds.isEmpty) return;
    final target = shapes.firstWhere((s) => s.id == selectedShapeIds.first);
    final initialMode = isFill
        ? (target.fillType == PaintFillType.linearGradient
              ? ColorPickerMode.linearGradient
              : (target.fillType == PaintFillType.radialGradient
                    ? ColorPickerMode.radialGradient
                    : ColorPickerMode.solid))
        : (target.strokeType == PaintFillType.linearGradient
              ? ColorPickerMode.linearGradient
              : (target.strokeType == PaintFillType.radialGradient
                    ? ColorPickerMode.radialGradient
                    : ColorPickerMode.solid));
    final initialGrad =
        (isFill ? target.fillGradient : target.strokeGradient) ??
        (initialMode != ColorPickerMode.solid
            ? ShapeGradient(
                type: initialMode == ColorPickerMode.radialGradient
                    ? PaintFillType.radialGradient
                    : PaintFillType.linearGradient,
                stops: [
                  GradientColorStop(
                    offset: 0.0,
                    color: isFill ? target.fillColor : target.strokeColor,
                  ),
                  const GradientColorStop(
                    offset: 1.0,
                    color: Color(0xFF38BDF8),
                  ),
                ],
              )
            : null);

    showNixColorPicker(
      context: context,
      initialColor: isFill ? target.fillColor : target.strokeColor,
      initialGradient: initialGrad,
      enableGradient: true,
      initialMode: initialMode,
      anchorRect: anchorRect,
      title: isFill ? 'Fill Color & Gradient' : 'Stroke Color & Gradient',
      onColorChanged: (color) {
        setState(() {
          shapes = List.of(shapes);
          for (final id in selectedShapeIds) {
            final s = shapes.firstWhere((s) => s.id == id);
            if (isFill) {
              s.fillColor = color;
              s.fillType = PaintFillType.solid;
            } else {
              s.strokeColor = color;
              s.strokeType = PaintFillType.solid;
            }
            s.invalidateCache();
          }
        });
      },
      onGradientChanged: (grad) {
        setState(() {
          shapes = List.of(shapes);
          for (final id in selectedShapeIds) {
            final s = shapes.firstWhere((s) => s.id == id);
            if (isFill) {
              s.fillGradient = grad;
              s.fillType = grad.type;
            } else {
              s.strokeGradient = grad;
              s.strokeType = grad.type;
            }
            s.invalidateCache();
          }
        });
      },
      onModeChanged: (mode) {
        setState(() {
          shapes = List.of(shapes);
          for (final id in selectedShapeIds) {
            final s = shapes.firstWhere((s) => s.id == id);
            final pft = mode == ColorPickerMode.linearGradient
                ? PaintFillType.linearGradient
                : (mode == ColorPickerMode.radialGradient
                      ? PaintFillType.radialGradient
                      : PaintFillType.solid);
            if (isFill) {
              s.fillType = pft;
              if (s.fillGradient == null && pft != PaintFillType.solid) {
                s.fillGradient = ShapeGradient(
                  type: pft,
                  stops: [
                    GradientColorStop(offset: 0.0, color: s.fillColor),
                    const GradientColorStop(
                      offset: 1.0,
                      color: Color(0xFF38BDF8),
                    ),
                  ],
                );
              }
            } else {
              s.strokeType = pft;
              if (s.strokeGradient == null && pft != PaintFillType.solid) {
                s.strokeGradient = ShapeGradient(
                  type: pft,
                  stops: [
                    GradientColorStop(offset: 0.0, color: s.strokeColor),
                    const GradientColorStop(
                      offset: 1.0,
                      color: Color(0xFF38BDF8),
                    ),
                  ],
                );
              }
            }
            s.invalidateCache();
          }
        });
      },
    ).then((_) {
      _saveHistorySnapshot();
    });
  }

  void _onPropertiesShapeChanged(VectorShape updated) {
    setState(() {
      final index = shapes.indexWhere((s) => s.id == updated.id);
      if (index != -1) {
        shapes = List.of(shapes);
        shapes[index] = updated;
      }
    });
  }

  void _onPropertiesShapeChangeEnd(VectorShape updated) {
    setState(() {
      final index = shapes.indexWhere((s) => s.id == updated.id);
      if (index != -1) {
        shapes = List.of(shapes);
        shapes[index] = updated;
      }
    });
    _saveHistorySnapshot();
  }

  /// Selects a shape by ID and ensures the properties panel is visible.
  void selectShape(String id) {
    if (_editingTextShapeId != null && _editingTextShapeId != id) {
      _stopTextEditing(commit: true);
    }
    setState(() {
      selectedShapeIds.clear();
      selectedShapeIds.add(id);
      isPropertiesPanelOpen = true;
    });
  }

  /// Clears shape selection to focus canvas/document inspector.
  void clearSelection() {
    setState(() {
      selectedShapeIds.clear();
    });
  }

  /// Deletes currently selected shapes.
  void deleteSelected() => _deleteSelected();

  /// Sets the canvas background color and saves to undo history.
  void setCanvasBackgroundColor(Color color) {
    setState(() => canvasBackgroundColor = color);
    _saveHistorySnapshot();
  }

  /// Zooms in towards canvas focal point.
  void zoomIn() => _zoomIn();

  /// Zooms out from canvas focal point.
  void zoomOut() => _zoomOut();

  /// Zooms to fit all shapes.
  void zoomToFit() => _zoomToFit();

  /// Resets zoom to 100%.
  void resetZoom() => _resetZoom();

  /// Centers the canvas in the viewport.
  void centerCanvas() => _centerCanvas();

  /// Toggles between Pan/Move mode and Select mode.
  void togglePanMode() => _togglePanMode();

  /// Sets zoom scale directly.
  void setZoomScale(double scale) => _setZoomScale(scale);

  /// Clears all shapes from the canvas.
  void clearCanvas() => _clearCanvas();

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) return false;
    final ctx = focus.context!;
    if (!ctx.mounted) return false;
    try {
      if (ctx.widget is EditableText ||
          ctx.widget is TextField ||
          ctx.widget is TextFormField) {
        return true;
      }
      if (ctx.findAncestorWidgetOfExactType<EditableText>() != null ||
          ctx.findAncestorWidgetOfExactType<TextField>() != null ||
          ctx.findAncestorWidgetOfExactType<TextFormField>() != null) {
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_editingTextShapeId != null) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _stopTextEditing(commit: true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      FocusManager.instance.primaryFocus?.unfocus();
      _workspaceFocusNode.requestFocus();
      if (selectedShapeIds.isNotEmpty) {
        setState(() => selectedShapeIds.clear());
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (_isMouseOverCanvas || !_isTextInputFocused()) {
        if (_isTextInputFocused()) {
          FocusManager.instance.primaryFocus?.unfocus();
          _workspaceFocusNode.requestFocus();
        }
        if (event is KeyDownEvent && !_isSpacePressed) {
          setState(() => _isSpacePressed = true);
        } else if (event is KeyUpEvent && _isSpacePressed) {
          setState(() => _isSpacePressed = false);
        }
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      if (panStartOffset != null && draftShapeType != null) {
        setState(() {});
      }
    }

    if (_isTextInputFocused()) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      final isCtrl =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (isCtrl) {
        if (event.logicalKey == LogicalKeyboardKey.keyA) {
          if (shapes.isNotEmpty) {
            _selectAll();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
          _copySelected();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyX) {
          _cutSelected();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyV) {
          _pasteClipboard();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyZ) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _redo();
          } else {
            _undo();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
          _redo();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
          _duplicateSelected();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
          _openExportDialog();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit0) {
          setState(() => _transformationController.value = Matrix4.identity());
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
          _zoomToFit();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
          _zoomToSelection();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.equal ||
            event.logicalKey == LogicalKeyboardKey.add ||
            event.logicalKey == LogicalKeyboardKey.numpadAdd) {
          _zoomIn();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.minus ||
            event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
          _zoomOut();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.bracketRight) {
          _bringForward();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
          _sendBackward();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.comma) {
          _openSettingsDialog();
          return KeyEventResult.handled;
        }
      } else {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() {
            selectedShapeIds.clear();
            currentMode = EditorMode.select;
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (selectedShapeIds.length == 1) {
            final selected = shapes.cast<VectorShape?>().firstWhere(
              (s) => s?.id == selectedShapeIds.first,
              orElse: () => null,
            );
            if (selected != null && selected.type == ShapeType.text) {
              _startTextEditing(selected, isNew: false, selectAll: true);
              return KeyEventResult.handled;
            }
          }
        } else if (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) {
          _deleteSelected();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.bracketRight) {
          _bringForward();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
          _sendBackward();
          return KeyEventResult.handled;
        } else if (HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.keyH) {
          _flipHorizontal();
          return KeyEventResult.handled;
        } else if (HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.keyV) {
          _flipVertical();
          return KeyEventResult.handled;
        } else if (HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.digit1) {
          _zoomToFit();
          return KeyEventResult.handled;
        } else if (HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.digit2) {
          _zoomToSelection();
          return KeyEventResult.handled;
        } else if (HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.digit0) {
          setState(() => _transformationController.value = Matrix4.identity());
          return KeyEventResult.handled;
        } else if (selectedShapeIds.isNotEmpty &&
            (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown)) {
          final isShift = HardwareKeyboard.instance.isShiftPressed;
          final step = isShift ? 10.0 : 1.0;
          Offset delta = Offset.zero;
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            delta = Offset(-step, 0);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            delta = Offset(step, 0);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            delta = Offset(0, -step);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            delta = Offset(0, step);
          }

          setState(() {
            for (final id in selectedShapeIds) {
              final s = shapes.firstWhere((s) => s.id == id);
              s.rect = s.rect.shift(delta);
            }
          });
          _saveHistorySnapshot();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyV) {
          setState(() => currentMode = EditorMode.select);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
          setState(() => currentMode = EditorMode.pan);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
          setState(() => currentMode = EditorMode.drawRectangle);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
          setState(() => currentMode = EditorMode.drawRoundedRectangle);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyO) {
          setState(() => currentMode = EditorMode.drawEllipse);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          setState(() => currentMode = EditorMode.drawLine);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyC ||
            event.logicalKey == LogicalKeyboardKey.keyB ||
            event.logicalKey == LogicalKeyboardKey.keyP) {
          setState(() => currentMode = EditorMode.drawCurve);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          setState(() => currentMode = EditorMode.drawStar);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyT) {
          setState(() => currentMode = EditorMode.drawText);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
          _pickColorFromScreen();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.equal ||
            event.logicalKey == LogicalKeyboardKey.add ||
            event.logicalKey == LogicalKeyboardKey.numpadAdd) {
          _zoomIn();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.minus ||
            event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
          _zoomOut();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final double zoomScale = CanvasTransformHelper.getScale(
      _transformationController.value,
    );
    final selectedShape = selectedShapeIds.length == 1
        ? shapes.firstWhere((s) => s.id == selectedShapeIds.first)
        : null;

    final isCompact = ResponsiveLayoutTokens.isCompact(context);

    return Focus(
      focusNode: _workspaceFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        onHover: (event) => _lastGlobalMousePosition = event.position,
        child: Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          body: Column(
            children: [
              // Dynamic Top Navigation Bar adhering to cross-platform tokens
              RepaintBoundary(
                child: TopNavigationBar(
                  fileName: fileName,
                  onFileNameChanged: (val) {
                    setState(() => fileName = val);
                    ref
                        .read(workspaceSettingsProvider.notifier)
                        .setFileName(val);
                    _persistCurrentProject();
                  },
                  onGoToHome: _handleGoToHome,
                  onUndo: _undo,
                  onRedo: _redo,
                  canUndo: _undoRedoManager.canUndo,
                  canRedo: _undoRedoManager.canRedo,
                  snapToGrid: appSettings.snapToGrid,
                  onSnapToGridChanged: (val) {
                    ref.read(appSettingsProvider.notifier).setSnapToGrid(val);
                  },
                  onExportSvg: _openExportDialog,
                  onImportImage: _importImageFromDevice,
                  onClearCanvas: _clearCanvas,
                  onShowShortcuts: _openShortcutsDialog,
                  onOpenSettings: _openSettingsDialog,
                  zoomScale: zoomScale,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onResetZoom: () {
                    setState(() {
                      _transformationController.value = Matrix4.identity();
                    });
                  },
                  onZoomToFit: _zoomToFit,
                  onZoomToSelection: _zoomToSelection,
                  showLayers: isLayersPanelOpen ?? appSettings.showLayers ?? (!isCompact),
                  onToggleLayers: (val) {
                    setState(() => isLayersPanelOpen = val);
                    ref.read(appSettingsProvider.notifier).setShowLayers(val);
                  },
                  showProperties: isPropertiesPanelOpen ?? appSettings.showProperties ?? (!isCompact),
                  onToggleProperties: (val) {
                    setState(() => isPropertiesPanelOpen = val);
                    ref.read(appSettingsProvider.notifier).setShowProperties(val);
                  },
                ),
              ),

              // Main Editor Workbench Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showLayers =
                        isLayersPanelOpen ?? appSettings.showLayers ?? (!isCompact);
                    final showProperties =
                        isPropertiesPanelOpen ?? appSettings.showProperties ?? (!isCompact);

                    final effectiveLayersWidth =
                        ResponsiveLayoutTokens.getEffectiveLayersWidth(
                          desiredWidth: layersSidebarWidth,
                          screenWidth: constraints.maxWidth,
                        );
                    final effectivePropertiesWidth =
                        ResponsiveLayoutTokens.getEffectivePropertiesWidth(
                          desiredWidth: propertiesSidebarWidth,
                          screenWidth: constraints.maxWidth,
                        );

                    return Row(
                      children: [
                        // Left Layers Sidebar (Docked when wide & enabled)
                        if (!isCompact && showLayers) ...[
                          RepaintBoundary(
                            child: LayersSidebar(
                              width: effectiveLayersWidth,
                              shapes: shapes,
                              selectedShapeIds: selectedShapeIds,
                              onSelectShape: (id) {
                                setState(() {
                                  selectedShapeIds.clear();
                                  selectedShapeIds.add(id);
                                });
                              },
                              onToggleVisibility: (id) {
                                setState(() {
                                  final s = shapes.firstWhere(
                                    (s) => s.id == id,
                                  );
                                  s.isVisible = !s.isVisible;
                                });
                                _saveHistorySnapshot();
                              },
                              onToggleLock: (id) {
                                setState(() {
                                  final s = shapes.firstWhere(
                                    (s) => s.id == id,
                                  );
                                  s.isLocked = !s.isLocked;
                                });
                                _saveHistorySnapshot();
                              },
                              onDeleteShape: _deleteShapeById,
                              onBringForward: _bringForward,
                              onSendBackward: _sendBackward,
                              onRenameShape: (id, newName) {
                                setState(() {
                                  shapes.firstWhere((s) => s.id == id).name =
                                      newName;
                                });
                                _saveHistorySnapshot();
                              },
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final displayList = shapes.reversed.toList();
                                  final shape = displayList.removeAt(oldIndex);
                                  displayList.insert(newIndex, shape);
                                  shapes = displayList.reversed.toList();
                                });
                                _saveHistorySnapshot();
                              },
                            ),
                          ),
                          SidebarResizeHandle(
                            onDragUpdate: (deltaDx) {
                              final maxWidth =
                                  ResponsiveLayoutTokens.getMaxSidebarWidth(
                                    constraints.maxWidth,
                                  );
                              final next = (layersSidebarWidth + deltaDx).clamp(
                                160.0,
                                maxWidth,
                              );
                              setState(() => layersSidebarWidth = next);
                              ref
                                  .read(workspaceSettingsProvider.notifier)
                                  .setLayersSidebarWidth(next);
                            },
                            onDoubleTapReset: () {
                              setState(() => layersSidebarWidth = 270.0);
                              ref
                                  .read(workspaceSettingsProvider.notifier)
                                  .setLayersSidebarWidth(270.0);
                            },
                          ),
                        ],

                        // Center Workspace Interactive Canvas
                        Expanded(
                          child: Stack(
                            children: [
                              InteractiveCanvas(
                                key: _canvasKey,
                                transformationController:
                                    _transformationController,
                                shapes: shapes,
                                selectedShapeIds: selectedShapeIds,
                                currentMode: currentMode,
                                draftShapeType: draftShapeType,
                                draftIsShiftPressed:
                                    HardwareKeyboard.instance.logicalKeysPressed
                                        .contains(
                                          LogicalKeyboardKey.shiftLeft,
                                        ) ||
                                    HardwareKeyboard.instance.logicalKeysPressed
                                        .contains(
                                          LogicalKeyboardKey.shiftRight,
                                        ),
                                draftIsAltPressed:
                                    HardwareKeyboard.instance.isAltPressed,
                                panStartOffset: panStartOffset,
                                panCurrentOffset: panCurrentOffset,
                                marqueeRect: marqueeRect,
                                snapGuidelineX: snapGuidelineX,
                                snapGuidelineY: snapGuidelineY,
                                gridSpacing: appSettings.gridSpacing,
                                gridStyle: appSettings.gridStyle,
                                invertZoom: appSettings.invertZoom,
                                isPanningWithMouse: _isPanningWithMouse,
                                isSpacePressed: _isSpacePressed,
                                isResizing:
                                    activeResizeHandle != ResizeHandle.none,
                                activeResizeHandle: activeResizeHandle,
                                isRotatingShape: isRotatingShape,
                                isMovingShapes: isMovingShapes,
                                editingTextShapeId: _editingTextShapeId,
                                isEditingNewText: _isEditingNewText,
                                selectAllText: _selectAllText,
                                canvasBackgroundColor:
                                    canvasBackgroundColor ??
                                    appSettings.defaultCanvasBgColor,
                                onInlineTextChanged: (text) {
                                  final editingId = _editingTextShapeId;
                                  if (editingId == null) return;
                                  final index = shapes.indexWhere(
                                    (s) => s.id == editingId,
                                  );
                                  if (index != -1) {
                                    shapes[index].textContent = text;
                                    shapes[index].invalidateCache();
                                    setState(() {});
                                  }
                                },
                                onInlineTextCommit: () =>
                                    _stopTextEditing(commit: true),
                                onInlineTextCancel: () =>
                                    _stopTextEditing(commit: false),
                                onInlineTextRectChanged: (newRect) {
                                  final editingId = _editingTextShapeId;
                                  if (editingId == null) return;
                                  final index = shapes.indexWhere(
                                    (s) => s.id == editingId,
                                  );
                                  if (index != -1) {
                                    shapes[index].rect = newRect;
                                    shapes[index].invalidateCache();
                                    setState(() {});
                                  }
                                },
                                onPointerDown: _onPointerDown,
                                onPointerMove: _onPointerMove,
                                onPointerUp: _onPointerUp,
                                onPointerCancel: _onPointerCancel,
                                onMatrixChanged: () => setState(() {}),
                                onCanvasHoverChanged: (hovered) =>
                                    _isMouseOverCanvas = hovered,
                                onPointerHover: (pos) =>
                                    _lastMouseCanvasPosition = pos,
                              ),

                              // Overlay Drawer for Compact Mobile Screens
                              if (isCompact && showLayers)
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 0,
                                  width:
                                      ResponsiveLayoutTokens.getCompactDrawerWidth(
                                        constraints.maxWidth,
                                      ),
                                  child: Material(
                                    elevation: 8,
                                    color: colorScheme.surfaceContainer,
                                    child: RepaintBoundary(
                                      child: LayersSidebar(
                                        width:
                                            ResponsiveLayoutTokens.getCompactDrawerWidth(
                                              constraints.maxWidth,
                                            ),
                                        shapes: shapes,
                                        selectedShapeIds: selectedShapeIds,
                                        onSelectShape: (id) {
                                          setState(() {
                                            selectedShapeIds.clear();
                                            selectedShapeIds.add(id);
                                          });
                                        },
                                        onToggleVisibility: (id) {
                                          setState(() {
                                            final s = shapes.firstWhere(
                                              (s) => s.id == id,
                                            );
                                            s.isVisible = !s.isVisible;
                                          });
                                          _saveHistorySnapshot();
                                        },
                                        onToggleLock: (id) {
                                          setState(() {
                                            final s = shapes.firstWhere(
                                              (s) => s.id == id,
                                            );
                                            s.isLocked = !s.isLocked;
                                          });
                                          _saveHistorySnapshot();
                                        },
                                        onDeleteShape: _deleteShapeById,
                                        onBringForward: _bringForward,
                                        onSendBackward: _sendBackward,
                                        onRenameShape: (id, newName) {
                                          setState(() {
                                            shapes
                                                    .firstWhere(
                                                      (s) => s.id == id,
                                                    )
                                                    .name =
                                                newName;
                                          });
                                          _saveHistorySnapshot();
                                        },
                                        onReorder: (oldIndex, newIndex) {
                                          setState(() {
                                            if (newIndex > oldIndex) newIndex--;
                                            final displayList = shapes.reversed
                                                .toList();
                                            final shape = displayList.removeAt(
                                              oldIndex,
                                            );
                                            displayList.insert(newIndex, shape);
                                            shapes = displayList.reversed
                                                .toList();
                                          });
                                          _saveHistorySnapshot();
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                              // Overlay Properties for Compact Mobile Screens
                              if (isCompact &&
                                  showProperties &&
                                  selectedShape != null)
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  right: 0,
                                  width:
                                      ResponsiveLayoutTokens.getCompactDrawerWidth(
                                        constraints.maxWidth,
                                      ),
                                  child: Material(
                                    elevation: 8,
                                    color: colorScheme.surfaceContainer,
                                    child: RepaintBoundary(
                                      child: PropertiesSidebar(
                                        width:
                                            ResponsiveLayoutTokens.getCompactDrawerWidth(
                                              constraints.maxWidth,
                                            ),
                                        selectedShape: selectedShape,
                                        onShapeChanged:
                                            _onPropertiesShapeChanged,
                                        onShapeChangeEnd:
                                            _onPropertiesShapeChangeEnd,
                                        onOpenColorPickerFill: ([anchorRect]) =>
                                            _openColorPicker(true, anchorRect),
                                        onOpenColorPickerStroke:
                                            ([anchorRect]) => _openColorPicker(
                                              false,
                                              anchorRect,
                                            ),
                                        onDuplicateShape: _duplicateSelected,
                                        onDeleteSelected: _deleteSelected,
                                        onAlignShape: _alignShapes,
                                        canvasBackgroundColor:
                                            canvasBackgroundColor,
                                        onCanvasBackgroundColorChanged: (col) {
                                          setState(
                                            () => canvasBackgroundColor = col,
                                          );
                                          _saveHistorySnapshot();
                                        },
                                        snapToGrid: appSettings.snapToGrid,
                                        onToggleSnapToGrid: (val) {
                                          ref
                                              .read(
                                                appSettingsProvider.notifier,
                                              )
                                              .setSnapToGrid(val);
                                        },
                                        gridSpacing: appSettings.gridSpacing,
                                        onGridSpacingChanged: (val) {
                                          ref
                                              .read(
                                                appSettingsProvider.notifier,
                                              )
                                              .setGridSpacing(val);
                                        },
                                        totalShapesCount: shapes.length,
                                        zoomScale: zoomScale,
                                        onZoomIn: _zoomIn,
                                        onZoomOut: _zoomOut,
                                        onSetZoomScale: _setZoomScale,
                                        isPanMode:
                                            currentMode == EditorMode.pan,
                                        onTogglePanMode: _togglePanMode,
                                        onCenterCanvas: _centerCanvas,
                                        onResetZoom: _resetZoom,
                                        onZoomToFit: _zoomToFit,
                                        onZoomToSelection: _zoomToSelection,
                                        onSelectAll: _selectAll,
                                        onExportSvg: _openExportDialog,
                                        onClearCanvas: _clearCanvas,
                                      ),
                                    ),
                                  ),
                                ),

                              // Center Dynamic Floating Tool Bar (Top or Bottom based on App Settings)
                              Positioned(
                                top: appSettings.toolbarPosition == 'top'
                                    ? 16.0
                                    : null,
                                bottom: appSettings.toolbarPosition == 'top'
                                    ? null
                                    : ResponsiveLayoutTokens.getFloatingToolbarBottomMargin(
                                        context,
                                      ),
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: RepaintBoundary(
                                    child: Transform.scale(
                                      scale:
                                          ResponsiveLayoutTokens.getFloatingToolbarScale(
                                            context,
                                          ),
                                      child: FloatingToolBar(
                                        currentMode: currentMode,
                                        onModeChanged: (mode) {
                                          setState(() => currentMode = mode);
                                        },
                                        onExportSvg: _openExportDialog,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Properties Inspector Sidebar (Docked when wide & enabled)
                        if (!isCompact && showProperties) ...[
                          SidebarResizeHandle(
                            onDragUpdate: (deltaDx) {
                              final maxWidth =
                                  ResponsiveLayoutTokens.getMaxSidebarWidth(
                                    constraints.maxWidth,
                                  );
                              final next = (propertiesSidebarWidth - deltaDx)
                                  .clamp(180.0, maxWidth);
                              setState(() => propertiesSidebarWidth = next);
                              ref
                                  .read(workspaceSettingsProvider.notifier)
                                  .setPropertiesSidebarWidth(next);
                            },
                            onDoubleTapReset: () {
                              setState(() => propertiesSidebarWidth = 280.0);
                              ref
                                  .read(workspaceSettingsProvider.notifier)
                                  .setPropertiesSidebarWidth(280.0);
                            },
                          ),
                          RepaintBoundary(
                            child: PropertiesSidebar(
                              width: effectivePropertiesWidth,
                              selectedShape: selectedShape,
                              onShapeChanged: _onPropertiesShapeChanged,
                              onShapeChangeEnd: _onPropertiesShapeChangeEnd,
                              onOpenColorPickerFill: ([anchorRect]) =>
                                  _openColorPicker(true, anchorRect),
                              onOpenColorPickerStroke: ([anchorRect]) =>
                                  _openColorPicker(false, anchorRect),
                              onDuplicateShape: _duplicateSelected,
                              onDeleteSelected: _deleteSelected,
                              onAlignShape: _alignShapes,
                              canvasBackgroundColor: canvasBackgroundColor,
                              onCanvasBackgroundColorChanged: (col) {
                                setState(() => canvasBackgroundColor = col);
                                _saveHistorySnapshot();
                              },
                              snapToGrid: appSettings.snapToGrid,
                              onToggleSnapToGrid: (val) {
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .setSnapToGrid(val);
                              },
                              gridSpacing: appSettings.gridSpacing,
                              onGridSpacingChanged: (val) {
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .setGridSpacing(val);
                              },
                              totalShapesCount: shapes.length,
                              zoomScale: zoomScale,
                              onZoomIn: _zoomIn,
                              onZoomOut: _zoomOut,
                              onSetZoomScale: _setZoomScale,
                              isPanMode: currentMode == EditorMode.pan,
                              onTogglePanMode: _togglePanMode,
                              onCenterCanvas: _centerCanvas,
                              onResetZoom: _resetZoom,
                              onZoomToFit: _zoomToFit,
                              onZoomToSelection: _zoomToSelection,
                              onSelectAll: _selectAll,
                              onExportSvg: _openExportDialog,
                              onClearCanvas: _clearCanvas,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ShapeType? _getShapeTypeFromMode(EditorMode mode) {
    switch (mode) {
      case EditorMode.drawRectangle:
        return ShapeType.rectangle;
      case EditorMode.drawRoundedRectangle:
        return ShapeType.roundedRectangle;
      case EditorMode.drawEllipse:
        return ShapeType.ellipse;
      case EditorMode.drawLine:
      case EditorMode.drawCurve:
        return ShapeType.line;
      case EditorMode.drawStar:
        return ShapeType.star;
      case EditorMode.drawText:
        return ShapeType.text;
      case EditorMode.select:
      case EditorMode.pan:
        return null;
    }
  }

  String _getModeName(EditorMode mode) {
    switch (mode) {
      case EditorMode.pan:
        return 'Pan';
      case EditorMode.drawRectangle:
        return 'Rectangle';
      case EditorMode.drawRoundedRectangle:
        return 'Rounded Rect';
      case EditorMode.drawEllipse:
        return 'Ellipse';
      case EditorMode.drawLine:
        return 'Line';
      case EditorMode.drawCurve:
        return 'Curve';
      case EditorMode.drawStar:
        return 'Star';
      case EditorMode.drawText:
        return 'Text';
      default:
        return 'Shape';
    }
  }
}
