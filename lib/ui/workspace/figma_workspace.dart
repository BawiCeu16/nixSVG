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
import 'package:nixsvg/models/undo_redo_manager.dart';
import 'package:nixsvg/models/vector_shape.dart';
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
  const FigmaWorkspace({super.key});

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
  bool snapToGrid = true;
  double gridSpacing = 40.0;

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
  final GlobalKey _canvasKey = GlobalKey();
  final FocusNode _workspaceFocusNode = FocusNode(debugLabel: 'WorkspaceFocus');

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
    _loadSampleDemoShapes();
    _saveHistorySnapshot();

    // Initialize persisted workspace settings from Riverpod
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsSettings = ref.read(workspaceSettingsProvider);
      setState(() {
        snapToGrid = wsSettings.snapToGrid;
        gridSpacing = wsSettings.gridSpacing;
        layersSidebarWidth = wsSettings.layersSidebarWidth;
        propertiesSidebarWidth = wsSettings.propertiesSidebarWidth;
        isLayersPanelOpen = wsSettings.isLayersPanelOpen;
        isPropertiesPanelOpen = wsSettings.isPropertiesPanelOpen;
        fileName = wsSettings.fileName;
      });
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
  }

  void _undo() {
    final previous = _undoRedoManager.undo();
    if (previous != null) {
      setState(() {
        shapes = previous;
        selectedShapeIds.clear();
      });
    }
  }

  void _redo() {
    final next = _undoRedoManager.redo();
    if (next != null) {
      setState(() {
        shapes = next;
        selectedShapeIds.clear();
      });
    }
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

    if (currentMode == EditorMode.select) {
      // 1. Check if hit resize or rotation handle of single selected shape
      if (selectedShapeIds.length == 1) {
        final singleSelected = shapes.firstWhere(
          (s) => s.id == selectedShapeIds.first,
        );
        if (!singleSelected.isLocked) {
          activeResizeHandle = CanvasHitTester.hitTestHandle(
            localPos,
            singleSelected,
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
        setState(() {
          final isShiftPressed =
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.shiftLeft,
              ) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.shiftRight,
              );

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
    if (_isPanningWithMouse && _lastPanPosition != null) {
      final delta = event.position - _lastPanPosition!;
      _lastPanPosition = event.position;
      setState(() {
        _transformationController.value = CanvasTransformHelper.panMatrix(
          _transformationController.value,
          delta,
        );
      });
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

    if (draftShapeType == ShapeType.line &&
        isShiftPressed &&
        panStartOffset != null) {
      panCurrentOffset = CanvasGeometry.snapLinePoint(
        panStartOffset!,
        localPos,
      );
    } else {
      panCurrentOffset = localPos;
    }

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
        } else if (activeResizeHandle != ResizeHandle.none &&
            selectedShapeIds.length == 1 &&
            initialShapeRects != null) {
          final target = shapes.firstWhere(
            (s) => s.id == selectedShapeIds.first,
          );
          final initialRect = initialShapeRects![target.id]!;
          target.rect = CanvasGeometry.resizeRect(
            initialRect,
            panStartOffset!,
            localPos,
            activeResizeHandle,
            isLine: target.type == ShapeType.line,
          );
        } else if (isMovingShapes && initialShapeRects != null) {
          var delta = localPos - panStartOffset!;
          if (snapToGrid) {
            final snapStep = (gridSpacing > 0) ? gridSpacing / 4 : 10.0;
            delta = Offset(
              (delta.dx / snapStep).round() * snapStep,
              (delta.dy / snapStep).round() * snapStep,
            );
          }
          final snapRes = CanvasGeometry.calculateSnapGuidelines(
            shapes: shapes,
            selectedShapeIds: selectedShapeIds,
          );
          if (snapRes.snapDelta != Offset.zero) {
            delta += snapRes.snapDelta;
          }
          snapGuidelineX = snapRes.guidelineX;
          snapGuidelineY = snapRes.guidelineY;
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
      Rect finalRect;
      bool isValidShape = false;

      final isShiftPressed =
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftLeft,
          ) ||
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftRight,
          );

      if (draftShapeType == ShapeType.line) {
        final endPos = isShiftPressed
            ? CanvasGeometry.snapLinePoint(panStartOffset!, localPos)
            : localPos;
        if ((endPos - panStartOffset!).distance <= 5) {
          finalRect = Rect.fromLTRB(
            panStartOffset!.dx,
            panStartOffset!.dy,
            panStartOffset!.dx + 100,
            panStartOffset!.dy,
          );
        } else {
          finalRect = Rect.fromLTRB(
            panStartOffset!.dx,
            panStartOffset!.dy,
            endPos.dx,
            endPos.dy,
          );
        }
        isValidShape = true;
      } else if (draftShapeType == ShapeType.text) {
        finalRect = Rect.fromPoints(panStartOffset!, localPos);
        if (finalRect.width <= 5 || finalRect.height <= 5) {
          finalRect = Rect.fromLTWH(
            panStartOffset!.dx,
            panStartOffset!.dy,
            160,
            40,
          );
        }
        isValidShape = true;
      } else {
        var rect = Rect.fromPoints(panStartOffset!, localPos);
        if (isShiftPressed) {
          final side = math.max(rect.width, rect.height);
          final dx = (localPos.dx >= panStartOffset!.dx) ? side : -side;
          final dy = (localPos.dy >= panStartOffset!.dy) ? side : -side;
          rect = Rect.fromPoints(
            panStartOffset!,
            Offset(panStartOffset!.dx + dx, panStartOffset!.dy + dy),
          );
        }
        finalRect = rect;
        isValidShape = finalRect.width > 5 && finalRect.height > 5;
      }

      if (isValidShape) {
        final isCurveMode = currentMode == EditorMode.drawCurve;
        final newShape = VectorShape(
          id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
          name: '${_getModeName(currentMode)} $_shapeCounter',
          type: draftShapeType!,
          rect: finalRect,
          isStroked: draftShapeType == ShapeType.line ? true : false,
          isFilled: draftShapeType == ShapeType.line ? false : true,
          isCurved: isCurveMode,
          curvature: isCurveMode ? 35.0 : 0.0,
        );
        _shapeCounter++;
        setState(() {
          shapes.add(newShape);
          selectedShapeIds.clear();
          selectedShapeIds.add(newShape.id);
          currentMode = EditorMode.select;
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
    });
    _saveHistorySnapshot();
  }

  void _deleteSelected() {
    if (selectedShapeIds.isEmpty) return;
    setState(() {
      shapes.removeWhere((s) => selectedShapeIds.contains(s.id));
      selectedShapeIds.clear();
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

  void _pasteClipboard() {
    if (_clipboard.isEmpty) return;
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

  void _zoomIn() {
    final focalPoint = (_isMouseOverCanvas && _lastMouseCanvasPosition != null)
        ? _lastMouseCanvasPosition!
        : _getViewportCanvasCenter();
    setState(() {
      _transformationController.value = CanvasTransformHelper.zoomAtCanvasPoint(
        _transformationController.value,
        focalPoint,
        1.2,
      );
    });
  }

  void _zoomOut() {
    final focalPoint = (_isMouseOverCanvas && _lastMouseCanvasPosition != null)
        ? _lastMouseCanvasPosition!
        : _getViewportCanvasCenter();
    setState(() {
      _transformationController.value = CanvasTransformHelper.zoomAtCanvasPoint(
        _transformationController.value,
        focalPoint,
        1.0 / 1.2,
      );
    });
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
    final svgCode = SvgExportService.generateSvg(shapes);
    showDialog(
      context: context,
      builder: (context) =>
          ExportDialog(svgContent: svgCode, fileName: '$fileName.svg'),
    );
  }

  void _openShortcutsDialog() {
    showDialog(context: context, builder: (context) => const ShortcutsDialog());
  }

  void _openColorPicker(bool isFill) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (selectedShapeIds.isEmpty) return;
    final target = shapes.firstWhere((s) => s.id == selectedShapeIds.first);
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: isFill ? target.fillColor : target.strokeColor,
        onColorSelected: (color) {
          setState(() {
            shapes = List.of(shapes);
            for (final id in selectedShapeIds) {
              final s = shapes.firstWhere((s) => s.id == id);
              if (isFill) {
                s.fillColor = color;
              } else {
                s.strokeColor = color;
              }
            }
          });
          _saveHistorySnapshot();
        },
      ),
    );
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
    setState(() {
      selectedShapeIds.clear();
      selectedShapeIds.add(id);
      isPropertiesPanelOpen = true;
    });
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) return false;
    final context = focus.context!;
    if (context.widget is EditableText ||
        context.widget is TextField ||
        context.widget is TextFormField) {
      return true;
    }
    if (context.findAncestorWidgetOfExactType<EditableText>() != null ||
        context.findAncestorWidgetOfExactType<TextField>() != null ||
        context.findAncestorWidgetOfExactType<TextFormField>() != null) {
      return true;
    }
    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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

    if (_isTextInputFocused()) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      final isCtrl =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (isCtrl) {
        if (event.logicalKey == LogicalKeyboardKey.keyA) {
          setState(() {
            selectedShapeIds.clear();
            selectedShapeIds.addAll(shapes.map((s) => s.id));
          });
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
          _undo();
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
        }
      } else {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() {
            selectedShapeIds.clear();
            currentMode = EditorMode.select;
          });
          return KeyEventResult.handled;
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
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
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
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body: Column(
          children: [
            // Dynamic Top Navigation Bar adhering to cross-platform tokens
            TopNavigationBar(
              fileName: fileName,
              onFileNameChanged: (val) {
                setState(() => fileName = val);
                ref.read(workspaceSettingsProvider.notifier).setFileName(val);
              },
              onUndo: _undo,
              onRedo: _redo,
              canUndo: _undoRedoManager.canUndo,
              canRedo: _undoRedoManager.canRedo,
              snapToGrid: snapToGrid,
              onSnapToGridChanged: (val) {
                setState(() => snapToGrid = val);
                ref.read(workspaceSettingsProvider.notifier).setSnapToGrid(val);
              },
              onExportSvg: _openExportDialog,
              onImportImage: _importImageFromDevice,
              onClearCanvas: () {
                setState(() {
                  shapes.clear();
                  selectedShapeIds.clear();
                });
                _saveHistorySnapshot();
              },
              onShowShortcuts: _openShortcutsDialog,
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
              showLayers: isLayersPanelOpen ?? (!isCompact),
              onToggleLayers: (val) {
                setState(() => isLayersPanelOpen = val);
                ref
                    .read(workspaceSettingsProvider.notifier)
                    .toggleLayersPanel(val);
              },
              showProperties: isPropertiesPanelOpen ?? (!isCompact),
              onToggleProperties: (val) {
                setState(() => isPropertiesPanelOpen = val);
                ref
                    .read(workspaceSettingsProvider.notifier)
                    .togglePropertiesPanel(val);
              },
            ),

            // Main Editor Workbench Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showLayers = isLayersPanelOpen ?? (!isCompact);
                  final showProperties = isPropertiesPanelOpen ?? (!isCompact);

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
                        LayersSidebar(
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
                              final s = shapes.firstWhere((s) => s.id == id);
                              s.isVisible = !s.isVisible;
                            });
                            _saveHistorySnapshot();
                          },
                          onToggleLock: (id) {
                            setState(() {
                              final s = shapes.firstWhere((s) => s.id == id);
                              s.isLocked = !s.isLocked;
                            });
                            _saveHistorySnapshot();
                          },
                          onDeleteShape: (id) {
                            setState(() {
                              shapes.removeWhere((s) => s.id == id);
                              selectedShapeIds.remove(id);
                            });
                            _saveHistorySnapshot();
                          },
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
                              panStartOffset: panStartOffset,
                              panCurrentOffset: panCurrentOffset,
                              marqueeRect: marqueeRect,
                              snapGuidelineX: snapGuidelineX,
                              snapGuidelineY: snapGuidelineY,
                              gridSpacing: gridSpacing,
                              isPanningWithMouse: _isPanningWithMouse,
                              isSpacePressed: isSpacePressed,
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
                                    onDeleteShape: (id) {
                                      setState(() {
                                        shapes.removeWhere((s) => s.id == id);
                                        selectedShapeIds.remove(id);
                                      });
                                      _saveHistorySnapshot();
                                    },
                                    onBringForward: _bringForward,
                                    onSendBackward: _sendBackward,
                                    onRenameShape: (id, newName) {
                                      setState(() {
                                        shapes
                                                .firstWhere((s) => s.id == id)
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
                                        shapes = displayList.reversed.toList();
                                      });
                                      _saveHistorySnapshot();
                                    },
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
                                  child: PropertiesSidebar(
                                    width:
                                        ResponsiveLayoutTokens.getCompactDrawerWidth(
                                          constraints.maxWidth,
                                        ),
                                    selectedShape: selectedShape,
                                    onShapeChanged: _onPropertiesShapeChanged,
                                    onShapeChangeEnd:
                                        _onPropertiesShapeChangeEnd,
                                    onOpenColorPickerFill: () =>
                                        _openColorPicker(true),
                                    onOpenColorPickerStroke: () =>
                                        _openColorPicker(false),
                                    onDuplicateShape: _duplicateSelected,
                                    onDeleteSelected: _deleteSelected,
                                    onAlignShape: _alignShapes,
                                  ),
                                ),
                              ),

                            // Center Bottom Dynamic Floating Tool Bar
                            Positioned(
                              bottom:
                                  ResponsiveLayoutTokens.getFloatingToolbarBottomMargin(
                                    context,
                                  ),
                              left: 0,
                              right: 0,
                              child: Center(
                                child: FloatingToolBar(
                                  currentMode: currentMode,
                                  onModeChanged: (mode) {
                                    setState(() => currentMode = mode);
                                  },
                                  onExportSvg: _openExportDialog,
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
                        PropertiesSidebar(
                          width: effectivePropertiesWidth,
                          selectedShape: selectedShape,
                          onShapeChanged: _onPropertiesShapeChanged,
                          onShapeChangeEnd: _onPropertiesShapeChangeEnd,
                          onOpenColorPickerFill: () => _openColorPicker(true),
                          onOpenColorPickerStroke: () =>
                              _openColorPicker(false),
                          onDuplicateShape: _duplicateSelected,
                          onDeleteSelected: _deleteSelected,
                          onAlignShape: _alignShapes,
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
