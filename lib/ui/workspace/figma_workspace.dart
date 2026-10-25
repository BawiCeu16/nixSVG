import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:nixsvg/services/safe_file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:nixsvg/services/svg_import_service.dart';
import 'package:nixsvg/theme/components/responsive_layout_tokens.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:cross_file/cross_file.dart';
import 'package:nixsvg/services/file_import_service.dart';
import 'package:nixsvg/ui/canvas/interactive_canvas.dart';
import 'package:nixsvg/ui/widgets/sidebar_resize_handle.dart';
import 'package:nixsvg/widgets/nix_file_drop_zone.dart';
import 'package:nixsvg/widgets/color_picker_dialog.dart';
import 'package:nixsvg/widgets/context_menu/figma_context_menu.dart';
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

class FigmaWorkspaceState extends ConsumerState<FigmaWorkspace>
    with WidgetsBindingObserver {
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
  Size canvasSize = const Size(3200, 2400);

  void _selectAll() {
    if (shapes.isEmpty) return;
    setState(() {
      selectedShapeIds.clear();
      selectedShapeIds.addAll(shapes.map((s) => s.id));
    });
  }

  void _resetZoom() {
    _lastWorkspaceZoomScale = 1.0;
    setState(() => _transformationController.value = Matrix4.identity());
  }

  void _handleMatrixChanged() {
    final currentScale = CanvasTransformHelper.getScale(
      _transformationController.value,
    );
    if ((currentScale - _lastWorkspaceZoomScale).abs() >= 0.005) {
      _lastWorkspaceZoomScale = currentScale;
      setState(() {});
    }
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
  List<VectorShape> _activeSelectedShapes = [];
  double _lastWorkspaceZoomScale = 1.0;
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

  // Pen Tool Drawing State (Bézier nodes)
  final List<PathNode> _penNodes = [];
  bool _isPenDraggingHandle = false;
  bool _isClosingNode = false;

  // Vector Node Edit Mode State (Figma-style vector editing)
  String? _editingPathShapeId;
  List<PathNode>? _editingPathNodes;
  final Set<int> _selectedPathNodeIndices = {};
  int? _hoveredPathNodeIndex;
  int? _activeDraggingNodeIndex;
  int? _activeHandleNodeIndex;
  int? _activeHandleType; // 1: handleIn, 2: handleOut
  Offset? _nodeDragStartPos;
  Map<int, PathNode>? _initialDraggingNodes;
  bool _isEditingPathClosed = false;
  Map<String, List<PathNode>>? _initialShapeNodes;

  bool get _isPenHoveringStart {
    if (currentMode != EditorMode.drawPen ||
        _penNodes.length < 2 ||
        _lastMouseCanvasPosition == null) {
      return false;
    }
    final zoomScale = CanvasTransformHelper.getScale(
      _transformationController.value,
    );
    final closeThreshold = 14.0 / (zoomScale > 0 ? zoomScale : 1.0);
    return (_lastMouseCanvasPosition! - _penNodes.first.position).distance <=
        closeThreshold;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialProject != null) {
      fileName = widget.initialProject!.name;
      shapes = widget.initialProject!.shapes.map((s) => s.copyWith()).toList();
      canvasSize = widget.initialProject!.canvasSize;
    } else {
      _loadSampleDemoShapes();
    }
    _decodeShapeImages();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _persistCurrentProject();
    }
  }

  void _decodeShapeImages() {
    for (final shape in shapes) {
      if (shape.type == ShapeType.image &&
          shape.decodedImage == null &&
          shape.imageBytes != null &&
          shape.imageBytes!.isNotEmpty) {
        shape.ensureImageDecoded(onDecoded: () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        (widget.initialProject ??
                ProjectModel.createNew(name: fileName, size: canvasSize))
            .copyWith(
              name: fileName,
              lastModified: DateTime.now(),
              shapes: shapes.map((s) => s.copyWith()).toList(),
              canvasSize: canvasSize,
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
      _decodeShapeImages();
      _persistCurrentProject();
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
      _decodeShapeImages();
      _persistCurrentProject();
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

  void _handlePenPointerDown(Offset localPos) {
    final zoomScale = CanvasTransformHelper.getScale(
      _transformationController.value,
    );
    final closeThreshold = 14.0 / (zoomScale > 0 ? zoomScale : 1.0);

    panStartOffset = localPos;
    panCurrentOffset = localPos;
    _lastMouseCanvasPosition = localPos;

    if (_penNodes.isEmpty) {
      _penNodes.add(PathNode(position: localPos));
      _isPenDraggingHandle = true;
      _isClosingNode = false;
      setState(() {});
      return;
    }

    // Check if clicked near start point to close path
    if (_penNodes.length >= 2 &&
        (localPos - _penNodes.first.position).distance <= closeThreshold) {
      _isClosingNode = true;
      _isPenDraggingHandle = true;
      setState(() {});
      return;
    }

    // Check click on last placed node to complete open path
    final finishThreshold = 10.0 / (zoomScale > 0 ? zoomScale : 1.0);
    if ((localPos - _penNodes.last.position).distance < finishThreshold) {
      _commitPenPath(isClosed: false);
      return;
    }

    // Add new anchor node
    _penNodes.add(PathNode(position: localPos));
    _isPenDraggingHandle = true;
    _isClosingNode = false;
    setState(() {});
  }

  void _commitPenPath({bool isClosed = false}) {
    if (_penNodes.length < 2) {
      setState(() {
        _penNodes.clear();
        _isPenDraggingHandle = false;
        _isClosingNode = false;
        panStartOffset = null;
        panCurrentOffset = null;
      });
      return;
    }

    final path = CanvasGeometry.nodesToPath(_penNodes, isClosed: isClosed);
    final bounds = path.getBounds();
    final safeBounds = Rect.fromLTWH(
      bounds.left,
      bounds.top,
      math.max(bounds.width, 4.0),
      math.max(bounds.height, 4.0),
    );
    final svgData = CanvasGeometry.nodesToSvgData(
      _penNodes,
      isClosed: isClosed,
    );
    final appSettings = ref.read(appSettingsProvider);

    final newShape = VectorShape(
      id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Path $_shapeCounter',
      type: ShapeType.path,
      rect: safeBounds,
      customPath: path,
      pathData: svgData,
      pathNodes: _penNodes.map((n) => n.copyWith()).toList(),
      isClosed: isClosed,
      isStroked: true,
      isFilled: isClosed,
      strokeWidth: appSettings.defaultStrokeWidth,
    );
    _shapeCounter++;

    setState(() {
      shapes.add(newShape);
      selectedShapeIds.clear();
      selectedShapeIds.add(newShape.id);
      _penNodes.clear();
      _isPenDraggingHandle = false;
      _isClosingNode = false;
      panStartOffset = null;
      panCurrentOffset = null;
      if (appSettings.autoSwitchToSelect) {
        currentMode = EditorMode.select;
      }
    });
    _saveHistorySnapshot();
  }

  // Vector Node Edit Mode Methods
  void _enterPathEditMode(VectorShape shape) {
    if (shape.isLocked || !shape.isVisible) return;
    if (_editingTextShapeId != null) {
      _stopTextEditing(commit: true);
    }
    final nodes = shape.getOrGeneratePathNodes();
    if (nodes.isEmpty) return;

    setState(() {
      _editingPathShapeId = shape.id;
      _editingPathNodes = nodes.map((n) => n.copyWith()).toList();
      _selectedPathNodeIndices.clear();
      _hoveredPathNodeIndex = null;
      _activeDraggingNodeIndex = null;
      _activeHandleNodeIndex = null;
      _activeHandleType = null;
      _isEditingPathClosed = shape.isClosed;
      selectedShapeIds.clear();
      selectedShapeIds.add(shape.id);
      currentMode = EditorMode.select;
    });
  }

  void _commitPathEdit() {
    if (_editingPathShapeId == null || _editingPathNodes == null) return;
    final shapeIndex = shapes.indexWhere((s) => s.id == _editingPathShapeId);
    if (shapeIndex != -1 && _editingPathNodes!.isNotEmpty) {
      final s = shapes[shapeIndex];
      s.updateFromPathNodes(_editingPathNodes!, closed: _isEditingPathClosed);
      _saveHistorySnapshot();
    }
    setState(() {
      _editingPathShapeId = null;
      _editingPathNodes = null;
      _selectedPathNodeIndices.clear();
      _hoveredPathNodeIndex = null;
      _activeDraggingNodeIndex = null;
      _activeHandleNodeIndex = null;
      _activeHandleType = null;
      _initialDraggingNodes = null;
    });
    _workspaceFocusNode.requestFocus();
  }

  void _syncEditingNodesToShape() {
    if (_editingPathShapeId == null || _editingPathNodes == null) return;
    final shapeIndex = shapes.indexWhere((s) => s.id == _editingPathShapeId);
    if (shapeIndex != -1 && _editingPathNodes!.isNotEmpty) {
      shapes[shapeIndex].updateFromPathNodes(
        _editingPathNodes!,
        closed: _isEditingPathClosed,
      );
    }
  }

  // Pointer Down / Move / Up / Cancel Gestures
  void _onPointerDown(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
    _workspaceFocusNode.requestFocus();
    if ((event.buttons & kSecondaryMouseButton) != 0) {
      return;
    }
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

    // Check Vector Node Edit Mode interactions
    if (_editingPathShapeId != null && _editingPathNodes != null) {
      final zoomScale = CanvasTransformHelper.getScale(
        _transformationController.value,
      );

      // 1. Check if clicked a handle of any selected node
      for (final nodeIdx in _selectedPathNodeIndices) {
        if (nodeIdx < _editingPathNodes!.length) {
          final handleType = CanvasGeometry.hitTestPathHandle(
            localPos,
            _editingPathNodes![nodeIdx],
            zoomScale: zoomScale,
          );
          if (handleType != 0) {
            _activeHandleNodeIndex = nodeIdx;
            _activeHandleType = handleType;
            _nodeDragStartPos = localPos;
            setState(() {});
            return;
          }
        }
      }

      // 2. Check if clicked an anchor node
      final hitNodeIdx = CanvasGeometry.hitTestPathNodes(
        localPos,
        _editingPathNodes!,
        zoomScale: zoomScale,
      );

      if (hitNodeIdx != null) {
        final now = DateTime.now();
        final isDouble =
            _lastPointerDownTime != null &&
            now.difference(_lastPointerDownTime!) <
                const Duration(milliseconds: 350) &&
            _lastPointerDownPos != null &&
            (localPos - _lastPointerDownPos!).distance < 16.0;
        _lastPointerDownTime = now;
        _lastPointerDownPos = localPos;

        final isAlt = HardwareKeyboard.instance.isAltPressed;

        if (isDouble || isAlt) {
          // Toggle corner vs smooth curve
          final node = _editingPathNodes![hitNodeIdx];
          if (node.isCorner) {
            final tangent = CanvasGeometry.calculateDefaultTangent(
              _editingPathNodes!,
              hitNodeIdx,
              isClosed: _isEditingPathClosed,
            );
            node.isCorner = false;
            node.handleOut = node.position + tangent;
            node.handleIn = node.position - tangent;
          } else {
            node.isCorner = true;
            node.handleIn = null;
            node.handleOut = null;
          }
          _syncEditingNodesToShape();
          _saveHistorySnapshot();
          setState(() {});
          return;
        }

        final isShift = HardwareKeyboard.instance.isShiftPressed;
        if (isShift) {
          if (_selectedPathNodeIndices.contains(hitNodeIdx)) {
            _selectedPathNodeIndices.remove(hitNodeIdx);
          } else {
            _selectedPathNodeIndices.add(hitNodeIdx);
          }
        } else {
          if (!_selectedPathNodeIndices.contains(hitNodeIdx)) {
            _selectedPathNodeIndices.clear();
            _selectedPathNodeIndices.add(hitNodeIdx);
          }
        }

        _activeDraggingNodeIndex = hitNodeIdx;
        _nodeDragStartPos = localPos;
        _initialDraggingNodes = {
          for (final idx in _selectedPathNodeIndices)
            if (idx < _editingPathNodes!.length)
              idx: _editingPathNodes![idx].copyWith(),
        };
        setState(() {});
        return;
      }

      // 3. Check if clicked near a path segment to insert a new anchor node
      final segIdx = CanvasGeometry.findNearestSegmentIndex(
        localPos,
        _editingPathNodes!,
        isClosed: _isEditingPathClosed,
        zoomScale: zoomScale,
      );
      if (segIdx != null) {
        final newNode = PathNode(position: localPos, isCorner: true);
        final insertIdx = segIdx + 1;
        _editingPathNodes!.insert(insertIdx, newNode);
        _selectedPathNodeIndices.clear();
        _selectedPathNodeIndices.add(insertIdx);
        _activeDraggingNodeIndex = insertIdx;
        _nodeDragStartPos = localPos;
        _initialDraggingNodes = {insertIdx: newNode.copyWith()};
        _syncEditingNodesToShape();
        _saveHistorySnapshot();
        setState(() {});
        return;
      }

      // Clicked outside active editing path: commit and exit vector edit mode
      _commitPathEdit();
    }

    // Detect double-click on text or path/line shape to edit like Figma
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
      VectorShape? hitPathShape;
      for (int i = shapes.length - 1; i >= 0; i--) {
        final s = shapes[i];
        if (s.isLocked || !s.isVisible) continue;
        if (CanvasHitTester.hitTestShape(localPos, s)) {
          if (s.type == ShapeType.text && hitTextShape == null) {
            hitTextShape = s;
          } else if ((s.type == ShapeType.path || s.type == ShapeType.line) &&
              hitPathShape == null) {
            hitPathShape = s;
          }
        }
      }
      if (hitTextShape != null) {
        _startTextEditing(hitTextShape, isNew: false, selectAll: true);
        return;
      }
      if (hitPathShape != null) {
        _enterPathEditMode(hitPathShape);
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

    if (currentMode == EditorMode.drawPen) {
      _handlePenPointerDown(localPos);
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
            _activeSelectedShapes = [singleSelected];
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
            _activeSelectedShapes = shapes
                .where((s) => selectedShapeIds.contains(s.id))
                .toList();
            initialShapeRects = {
              for (final s in _activeSelectedShapes) s.id: s.rect,
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
            final groupMembers = (matchedShape.groupId != null)
                ? shapes
                      .where((s) => s.groupId == matchedShape.groupId)
                      .map((s) => s.id)
                      .toSet()
                : {matchedShape.id};
            final allSelected = groupMembers.every(
              (id) => selectedShapeIds.contains(id),
            );
            if (allSelected) {
              selectedShapeIds.removeAll(groupMembers);
            } else {
              selectedShapeIds.addAll(groupMembers);
            }
          } else {
            if (matchedShape.groupId != null) {
              final groupMembers = shapes
                  .where((s) => s.groupId == matchedShape.groupId)
                  .map((s) => s.id)
                  .toSet();
              if (!selectedShapeIds.containsAll(groupMembers)) {
                selectedShapeIds.clear();
                selectedShapeIds.addAll(groupMembers);
              }
            } else {
              if (!selectedShapeIds.contains(matchedShape.id)) {
                selectedShapeIds.clear();
                selectedShapeIds.add(matchedShape.id);
              }
            }
          }

          if (selectedShapeIds.isNotEmpty) {
            final isAltPressed = HardwareKeyboard.instance.isAltPressed;
            if (isAltPressed) {
              _duplicateSelected(offset: Offset.zero);
            }
            isMovingShapes = true;
            _activeSelectedShapes = shapes
                .where((s) => selectedShapeIds.contains(s.id))
                .toList();
            initialShapeRects = {
              for (final s in _activeSelectedShapes) s.id: s.rect,
            };
            _initialShapeNodes = {
              for (final s in _activeSelectedShapes)
                if (s.pathNodes != null)
                  s.id: s.pathNodes!.map((n) => n.copyWith()).toList(),
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
      if (currentMode == EditorMode.drawPen && _penNodes.isNotEmpty) {
        setState(() {});
      } else if (_editingPathShapeId != null && _editingPathNodes != null) {
        final zoomScale = CanvasTransformHelper.getScale(
          _transformationController.value,
        );
        final hIdx = CanvasGeometry.hitTestPathNodes(
          event.localPosition,
          _editingPathNodes!,
          zoomScale: zoomScale,
        );
        if (hIdx != _hoveredPathNodeIndex) {
          setState(() => _hoveredPathNodeIndex = hIdx);
        }
      }
      return;
    }

    final localPos = event.localPosition;
    _lastMouseCanvasPosition = localPos;

    if (_editingPathShapeId != null && _editingPathNodes != null) {
      if (_activeHandleNodeIndex != null && _activeHandleType != null) {
        if (_activeHandleNodeIndex! < _editingPathNodes!.length) {
          final node = _editingPathNodes![_activeHandleNodeIndex!];
          final center = node.position;
          final isShift = HardwareKeyboard.instance.isShiftPressed;
          final isAlt = HardwareKeyboard.instance.isAltPressed;

          Offset targetPos = localPos;
          if (isShift) {
            targetPos = CanvasGeometry.calculateHandleSnapAngle(center, localPos);
          }

          if (_activeHandleType == 2) {
            // Dragging handleOut
            node.handleOut = targetPos;
            node.isCorner = false;
            if (!isAlt) {
              node.handleIn = center - (targetPos - center);
            }
          } else if (_activeHandleType == 1) {
            // Dragging handleIn
            node.handleIn = targetPos;
            node.isCorner = false;
            if (!isAlt) {
              node.handleOut = center - (targetPos - center);
            }
          }
          _syncEditingNodesToShape();
          setState(() {});
        }
        return;
      }

      if (_activeDraggingNodeIndex != null && _nodeDragStartPos != null) {
        final delta = localPos - _nodeDragStartPos!;
        for (final idx in _selectedPathNodeIndices) {
          if (idx < _editingPathNodes!.length) {
            final initNode = _initialDraggingNodes?[idx] ?? _editingPathNodes![idx];
            _editingPathNodes![idx] = initNode.copyWith(
              position: initNode.position + delta,
              handleIn: initNode.handleIn != null ? initNode.handleIn! + delta : null,
              handleOut: initNode.handleOut != null ? initNode.handleOut! + delta : null,
            );
          }
        }
        _syncEditingNodesToShape();
        setState(() {});
        return;
      }

      final zoomScale = CanvasTransformHelper.getScale(
        _transformationController.value,
      );
      final hIdx = CanvasGeometry.hitTestPathNodes(
        localPos,
        _editingPathNodes!,
        zoomScale: zoomScale,
      );
      if (hIdx != _hoveredPathNodeIndex) {
        setState(() => _hoveredPathNodeIndex = hIdx);
      }
      return;
    }

    if (currentMode == EditorMode.drawPen) {
      if (_penNodes.isNotEmpty && _isPenDraggingHandle) {
        final targetIndex = _isClosingNode ? 0 : _penNodes.length - 1;
        final targetNode = _penNodes[targetIndex];
        final center = targetNode.position;
        final isShiftPressed =
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.shiftLeft,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.shiftRight,
            );
        final isAltPressed = HardwareKeyboard.instance.isAltPressed;

        Offset handleOutPos = localPos;
        if (isShiftPressed) {
          handleOutPos = CanvasGeometry.calculateHandleSnapAngle(
            center,
            localPos,
          );
        }

        final dragDelta = handleOutPos - center;
        if (dragDelta.distance >= 2.0) {
          targetNode.isCorner = false;
          targetNode.handleOut = handleOutPos;
          if (!isAltPressed) {
            // Symmetrical mirrored tangent handle
            targetNode.handleIn = center - (handleOutPos - center);
          }
        } else {
          // Sharp corner anchor point
          targetNode.isCorner = true;
          targetNode.handleOut = null;
          if (!isAltPressed) {
            targetNode.handleIn = null;
          }
        }
        setState(() {});
      }
      return;
    }
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
              if (target.type == ShapeType.star ||
                  target.type == ShapeType.polygon) {
                final dy = testPos.dy - (rect.center.dy - maxRadius);
                dragDistance = dy;
              } else {
                final dx = testPos.dx - rect.left;
                final dy = testPos.dy - rect.top;
                dragDistance = (dx + dy) / 2;
              }
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

          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
          final isAltPressed = HardwareKeyboard.instance.isAltPressed;

          double newRadius;
          if (isShiftPressed) {
            // Snaps in increments of 10: 0, 10, 20, 30, 40, 50, etc.
            newRadius = (dragDistance / 10.0).roundToDouble() * 10.0;
          } else {
            newRadius = dragDistance.roundToDouble();
          }
          if (target.type == ShapeType.star ||
              target.type == ShapeType.polygon) {
            newRadius = newRadius.clamp(0.0, maxRadius * 0.48);
          } else {
            newRadius = newRadius.clamp(0.0, maxRadius);
          }

          if (target.type == ShapeType.rectangle && newRadius > 0.0) {
            target.type = ShapeType.roundedRectangle;
          }

          if (isAltPressed) {
            // Only that held corner point changes
            if (!target.hasIndependentCorners) {
              target.topLeftRadius = target.cornerRadius;
              target.topRightRadius = target.cornerRadius;
              target.bottomLeftRadius = target.cornerRadius;
              target.bottomRightRadius = target.cornerRadius;
            }
            switch (activeResizeHandle) {
              case ResizeHandle.radiusTopLeft:
                target.topLeftRadius = newRadius;
                break;
              case ResizeHandle.radiusTopRight:
                target.topRightRadius = newRadius;
                break;
              case ResizeHandle.radiusBottomLeft:
                target.bottomLeftRadius = newRadius;
                break;
              case ResizeHandle.radiusBottomRight:
                target.bottomRightRadius = newRadius;
                break;
              default:
                break;
            }
          } else {
            // All corners change together
            target.cornerRadius = newRadius;
            target.topLeftRadius = null;
            target.topRightRadius = null;
            target.bottomLeftRadius = null;
            target.bottomRightRadius = null;
          }

          target.invalidateCache();
        } else if (activeResizeHandle.isRatio && selectedShapeIds.length == 1) {
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
          if (maxRadius > 0) {
            final center = rect.center;
            final dist = (testPos - center).distance;
            double newRatio = dist / maxRadius;

            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
            if (isShiftPressed) {
              // Holding Shift snaps in increments of 10% (0.1, 0.2, 0.3, etc.)
              newRatio = (newRatio * 10).roundToDouble() / 10.0;
            } else {
              // Standard precision percentage increments
              newRatio = (newRatio * 100).roundToDouble() / 100.0;
            }

            target.innerRadiusRatio = newRatio.clamp(0.05, 0.95);
            target.invalidateCache();
          }
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
            final oldRect = target.rect;
            target.rect = CanvasGeometry.resizeRect(
              initialRect,
              panStartOffset!,
              unrotatedCurrent,
              activeResizeHandle,
              isLine: target.type == ShapeType.line,
            );
            if (target.pathNodes != null) {
              target.scaleNodes(oldRect, target.rect);
            }
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
            for (int i = 0; i < _activeSelectedShapes.length; i++) {
              final s = _activeSelectedShapes[i];
              final initR = initialShapeRects![s.id];
              if (initR != null) {
                final relLeft = (initR.left - initialCombined.left) * scaleX;
                final relTop = (initR.top - initialCombined.top) * scaleY;
                final newW = initR.width * scaleX;
                final newH = initR.height * scaleY;
                final oldR = s.rect;
                s.rect = Rect.fromLTWH(
                  newCombined.left + relLeft,
                  newCombined.top + relTop,
                  math.max(4.0, newW),
                  math.max(4.0, newH),
                );
                if (s.pathNodes != null) {
                  s.scaleNodes(oldR, s.rect);
                }
                s.invalidateCache();
              }
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
          for (int i = 0; i < _activeSelectedShapes.length; i++) {
            final s = _activeSelectedShapes[i];
            final initR = initialShapeRects![s.id];
            if (initR != null) {
              s.rect = initR.shift(delta);
              if (_initialShapeNodes?[s.id] != null) {
                s.pathNodes = _initialShapeNodes![s.id]!
                    .map((n) => n.copyWith(
                          position: n.position + delta,
                          handleIn: n.handleIn != null ? n.handleIn! + delta : null,
                          handleOut: n.handleOut != null ? n.handleOut! + delta : null,
                        ))
                    .toList();
                s.customPath = CanvasGeometry.nodesToPath(
                  s.pathNodes!,
                  isClosed: s.isClosed,
                );
              }
              s.invalidateCache();
            }
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

    if (_editingPathShapeId != null) {
      if (_activeHandleNodeIndex != null || _activeDraggingNodeIndex != null) {
        _activeHandleNodeIndex = null;
        _activeHandleType = null;
        _activeDraggingNodeIndex = null;
        _nodeDragStartPos = null;
        _initialDraggingNodes = null;
        _saveHistorySnapshot();
        setState(() {});
      }
      panStartOffset = null;
      panCurrentOffset = null;
      return;
    }

    if (currentMode == EditorMode.drawPen) {
      if (_isClosingNode && _penNodes.length >= 2) {
        _commitPenPath(isClosed: true);
        return;
      }
      setState(() {
        panStartOffset = null;
        panCurrentOffset = null;
        _isPenDraggingHandle = false;
        _isClosingNode = false;
      });
      return;
    }

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
        final newShape = VectorShape(
          id: 'shape-${DateTime.now().millisecondsSinceEpoch}',
          name: '${_getModeName(currentMode)} $_shapeCounter',
          type: draftShapeType!,
          rect: finalRect,
          textContent: isText ? '' : 'Text Element',
          isStroked: draftShapeType == ShapeType.line ? true : false,
          isFilled: draftShapeType == ShapeType.line ? false : true,
          strokeWidth: appSettings.defaultStrokeWidth,
          cornerRadius: draftShapeType == ShapeType.roundedRectangle
              ? appSettings.defaultCornerRadius
              : 0.0,
          cornerSmoothing: draftShapeType == ShapeType.roundedRectangle
              ? appSettings.defaultCornerSmoothing
              : 0.0,
          isCurved: isCurveMode,
          curvature: isCurveMode ? 35.0 : 0.0,
          pointCount: draftShapeType == ShapeType.polygon ? 6 : 5,
          innerRadiusRatio: 0.4,
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
      _initialShapeNodes = null;
      _activeSelectedShapes.clear();
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
    final groupMapping = <String, (String id, String name)>{};

    for (final id in selectedShapeIds) {
      final orig = shapes.firstWhere((s) => s.id == id);
      String? dupGroupId;
      String? dupGroupName;
      if (orig.groupId != null) {
        final mapped = groupMapping.putIfAbsent(orig.groupId!, () {
          final newGid =
              'group_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
          final newGname = orig.groupName != null
              ? '${orig.groupName} Copy'
              : 'Group';
          return (newGid, newGname);
        });
        dupGroupId = mapped.$1;
        dupGroupName = mapped.$2;
      }

      final dup = orig.copyWith(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}',
        name: '${orig.name} Copy',
        rect: orig.rect.shift(offset),
        groupId: dupGroupId,
        groupName: dupGroupName,
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

  void _groupSelected() {
    if (selectedShapeIds.isEmpty) return;
    final selectedShapes = shapes
        .where((s) => selectedShapeIds.contains(s.id))
        .toList();
    if (selectedShapes.isEmpty) return;

    final existingGroups = shapes
        .map((s) => s.groupName)
        .whereType<String>()
        .toSet();
    int nextGroupNum = 1;
    while (existingGroups.contains('Group $nextGroupNum')) {
      nextGroupNum++;
    }
    final newGroupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final newGroupName = 'Group $nextGroupNum';

    setState(() {
      for (final shape in selectedShapes) {
        shape.groupId = newGroupId;
        shape.groupName = newGroupName;
      }
    });
    _saveHistorySnapshot();
    _showFeedbackMessage('Grouped as $newGroupName');
  }

  void _ungroupSelected() {
    if (selectedShapeIds.isEmpty) return;
    final groupIdsToClear = shapes
        .where((s) => selectedShapeIds.contains(s.id) && s.groupId != null)
        .map((s) => s.groupId!)
        .toSet();

    if (groupIdsToClear.isEmpty) return;

    setState(() {
      for (final s in shapes) {
        if (s.groupId != null && groupIdsToClear.contains(s.groupId)) {
          s.groupId = null;
          s.groupName = null;
        }
      }
    });
    _saveHistorySnapshot();
    _showFeedbackMessage('Ungrouped selection');
  }

  void _showFeedbackMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _alignShapes(String align, {bool? toCanvas}) {
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    CanvasGeometry.alignShapes(
      shapes: shapes,
      selectedIds: selectedShapeIds,
      align: align,
      canvasFrame: Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      alignToCanvas: toCanvas ?? isAlt,
    );
    setState(() {});
    _saveHistorySnapshot();
  }

  void _bringToFront() {
    if (selectedShapeIds.isEmpty) return;
    final selectedShapes = shapes
        .where((s) => selectedShapeIds.contains(s.id))
        .toList();
    if (selectedShapes.isEmpty) return;
    setState(() {
      shapes.removeWhere((s) => selectedShapeIds.contains(s.id));
      shapes.addAll(selectedShapes);
    });
    _saveHistorySnapshot();
  }

  void _sendToBack() {
    if (selectedShapeIds.isEmpty) return;
    final selectedShapes = shapes
        .where((s) => selectedShapeIds.contains(s.id))
        .toList();
    if (selectedShapes.isEmpty) return;
    setState(() {
      shapes.removeWhere((s) => selectedShapeIds.contains(s.id));
      shapes.insertAll(0, selectedShapes);
    });
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

  Future<void> _copySelectedAsSvg() async {
    if (selectedShapeIds.isEmpty) return;
    try {
      final svgCode = SvgExportService.generateSvg(
        shapes,
        canvasSize: canvasSize,
        selectedShapeIds: selectedShapeIds,
        scope: SvgExportScope.selection,
      );
      await Clipboard.setData(ClipboardData(text: svgCode));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SVG code copied to clipboard'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _copyShapeAsSvgById(String id) async {
    try {
      final svgCode = SvgExportService.generateSvg(
        shapes,
        canvasSize: canvasSize,
        selectedShapeIds: {id},
        scope: SvgExportScope.selection,
      );
      await Clipboard.setData(ClipboardData(text: svgCode));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layer SVG copied to clipboard'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _duplicateShapeById(String id) {
    final index = shapes.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final orig = shapes[index];
    final dup = orig.copyWith(
      id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}',
      name: '${orig.name} Copy',
      rect: orig.rect.shift(const Offset(20, 20)),
    );
    setState(() {
      shapes.insert(index + 1, dup);
      selectedShapeIds.clear();
      selectedShapeIds.add(dup.id);
    });
    _saveHistorySnapshot();
  }

  void _handleSelectShapes(Set<String> ids) {
    setState(() {
      selectedShapeIds.clear();
      selectedShapeIds.addAll(ids);
    });
  }

  String _getShapeTypeName(ShapeType type) {
    switch (type) {
      case ShapeType.rectangle:
        return 'Rectangle';
      case ShapeType.roundedRectangle:
        return 'Rounded Rect';
      case ShapeType.ellipse:
        return 'Ellipse';
      case ShapeType.line:
        return 'Line';
      case ShapeType.star:
        return 'Star';
      case ShapeType.polygon:
        return 'Polygon';
      case ShapeType.path:
        return 'Vector Path';
      case ShapeType.text:
        return 'Text';
      case ShapeType.image:
        return 'Image';
    }
  }

  void _addShapeAt(ShapeType type, Offset center) {
    final appSettings = ref.read(appSettingsProvider);
    const size = Size(120, 120);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    final name = '${_getShapeTypeName(type)} $_shapeCounter';
    _shapeCounter++;
    final newShape = VectorShape(
      id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1000)}',
      name: name,
      type: type,
      rect: rect,
      isFilled: type != ShapeType.line,
      strokeWidth: appSettings.defaultStrokeWidth,
      cornerRadius: type == ShapeType.roundedRectangle
          ? appSettings.defaultCornerRadius
          : 0.0,
      cornerSmoothing: type == ShapeType.roundedRectangle
          ? appSettings.defaultCornerSmoothing
          : 0.0,
      pointCount: 5,
      innerRadiusRatio: 0.4,
    );
    setState(() {
      shapes.add(newShape);
      selectedShapeIds.clear();
      selectedShapeIds.add(newShape.id);
    });
    _saveHistorySnapshot();
  }

  void _handleCanvasContextMenu(Offset globalPos, Offset canvasPos) {
    VectorShape? hitShape;
    for (final shape in shapes.reversed) {
      if (!shape.isVisible) continue;
      if (CanvasHitTester.hitTestShape(canvasPos, shape)) {
        hitShape = shape;
        break;
      }
    }
    if (hitShape == null) {
      for (final shape in shapes.reversed) {
        if (!shape.isVisible) continue;
        if (shape.getBoundingBox().inflate(8.0).contains(canvasPos)) {
          hitShape = shape;
          break;
        }
      }
    }

    if (hitShape != null) {
      if (!selectedShapeIds.contains(hitShape.id)) {
        setState(() {
          selectedShapeIds.clear();
          selectedShapeIds.add(hitShape!.id);
        });
      }
      _showCanvasShapeContextMenu(globalPos, hitShape);
    } else {
      _showEmptyCanvasContextMenu(globalPos, canvasPos);
    }
  }

  void _showCanvasShapeContextMenu(Offset globalPos, VectorShape targetShape) {
    final isAnyLocked = shapes
        .where((s) => selectedShapeIds.contains(s.id))
        .any((s) => s.isLocked);
    final isAnyVisible = shapes
        .where((s) => selectedShapeIds.contains(s.id))
        .any((s) => s.isVisible);

    showFigmaContextMenu(
      context: context,
      globalPosition: globalPos,
      items: [
        FigmaMenuItem(
          label: 'Cut',
          icon: Icons.content_cut_rounded,
          shortcut: '⌘X',
          onTap: _cutSelected,
        ),
        FigmaMenuItem(
          label: 'Copy',
          icon: Icons.content_copy_rounded,
          shortcut: '⌘C',
          onTap: _copySelected,
        ),
        FigmaMenuItem(
          label: 'Copy as SVG',
          icon: Icons.code_rounded,
          shortcut: '⇧⌘C',
          onTap: _copySelectedAsSvg,
        ),
        FigmaMenuItem(
          label: 'Paste',
          icon: Icons.content_paste_rounded,
          shortcut: '⌘V',
          onTap: _pasteClipboard,
        ),
        FigmaMenuItem(
          label: 'Duplicate',
          icon: Icons.copy_rounded,
          shortcut: '⌘D',
          onTap: _duplicateSelected,
        ),
        FigmaMenuItem(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          shortcut: '⌫',
          isDestructive: true,
          onTap: _deleteSelected,
        ),
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: 'Group Selection',
          icon: Icons.folder_outlined,
          shortcut: '⌘G',
          onTap: _groupSelected,
        ),
        if (shapes
            .where((s) => selectedShapeIds.contains(s.id))
            .any((s) => s.groupId != null))
          FigmaMenuItem(
            label: 'Ungroup Selection',
            icon: Icons.folder_open_outlined,
            shortcut: '⇧⌘G',
            onTap: _ungroupSelected,
          ),
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: 'Bring to Front',
          icon: Icons.vertical_align_top_rounded,
          shortcut: ']',
          onTap: _bringToFront,
        ),
        FigmaMenuItem(
          label: 'Bring Forward',
          icon: Icons.keyboard_arrow_up_rounded,
          shortcut: '⌘]',
          onTap: _bringForward,
        ),
        FigmaMenuItem(
          label: 'Send Backward',
          icon: Icons.keyboard_arrow_down_rounded,
          shortcut: '⌘[',
          onTap: _sendBackward,
        ),
        FigmaMenuItem(
          label: 'Send to Back',
          icon: Icons.vertical_align_bottom_rounded,
          shortcut: '[',
          onTap: _sendToBack,
        ),
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: 'Flip Horizontal',
          icon: Icons.flip_rounded,
          shortcut: '⇧H',
          onTap: _flipHorizontal,
        ),
        FigmaMenuItem(
          label: 'Flip Vertical',
          icon: Icons.flip_rounded,
          shortcut: '⇧V',
          onTap: _flipVertical,
        ),
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: isAnyLocked ? 'Unlock Selection' : 'Lock Selection',
          icon: isAnyLocked
              ? Icons.lock_open_rounded
              : Icons.lock_outline_rounded,
          shortcut: '⌘L',
          onTap: () {
            setState(() {
              final newLock = !isAnyLocked;
              for (final id in selectedShapeIds) {
                final s = shapes.firstWhere((x) => x.id == id);
                s.setLocked(newLock);
              }
            });
            _saveHistorySnapshot();
          },
        ),
        FigmaMenuItem(
          label: isAnyVisible ? 'Hide Selection' : 'Show Selection',
          icon: isAnyVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          shortcut: '⌘H',
          onTap: () {
            setState(() {
              final newVis = !isAnyVisible;
              for (final id in selectedShapeIds) {
                final s = shapes.firstWhere((x) => x.id == id);
                s.setVisible(newVis);
              }
              if (!newVis) {
                selectedShapeIds.clear();
              }
            });
            _saveHistorySnapshot();
          },
        ),
        if (selectedShapeIds.length >= 2) ...[
          const FigmaMenuDivider(),
          FigmaMenuItem(
            label: 'Boolean Union',
            icon: Icons.grain_rounded,
            shortcut: '⌥⌘U',
            onTap: () => _executeBooleanOperation(PathOperation.union),
          ),
          FigmaMenuItem(
            label: 'Boolean Subtract',
            icon: Icons.remove_circle_outline_rounded,
            shortcut: '⌥⌘S',
            onTap: () => _executeBooleanOperation(PathOperation.difference),
          ),
          FigmaMenuItem(
            label: 'Boolean Intersect',
            icon: Icons.pie_chart_outline_rounded,
            shortcut: '⌥⌘I',
            onTap: () => _executeBooleanOperation(PathOperation.intersect),
          ),
          FigmaMenuItem(
            label: 'Boolean Exclude',
            icon: Icons.contrast_rounded,
            shortcut: '⌥⌘X',
            onTap: () => _executeBooleanOperation(PathOperation.xor),
          ),
        ],
        if (selectedShapeIds.length >= 3) ...[
          const FigmaMenuDivider(),
          FigmaMenuItem(
            label: 'Distribute Horizontally',
            icon: Icons.horizontal_distribute,
            shortcut: '⌥⌘H',
            onTap: () => _distributeShapes('horizontal'),
          ),
          FigmaMenuItem(
            label: 'Distribute Vertically',
            icon: Icons.vertical_distribute,
            shortcut: '⌥⌘V',
            onTap: () => _distributeShapes('vertical'),
          ),
        ],
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: 'Select All',
          icon: Icons.select_all_rounded,
          shortcut: '⌘A',
          onTap: _selectAll,
        ),
        FigmaMenuItem(
          label: 'Export Selection...',
          icon: Icons.file_upload_outlined,
          shortcut: '⇧⌘E',
          onTap: _openExportDialog,
        ),
      ],
    );
  }

  void _showEmptyCanvasContextMenu(Offset globalPos, Offset canvasPos) {
    showFigmaContextMenu(
      context: context,
      globalPosition: globalPos,
      items: [
        FigmaMenuItem(
          label: 'Paste Here',
          icon: Icons.content_paste_rounded,
          shortcut: '⌘V',
          onTap: _pasteClipboard,
        ),
        FigmaMenuItem(
          label: 'Select All',
          icon: Icons.select_all_rounded,
          shortcut: '⌘A',
          onTap: _selectAll,
        ),
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: 'Add Rectangle',
          icon: Icons.crop_din_rounded,
          shortcut: 'R',
          onTap: () => _addShapeAt(ShapeType.rectangle, canvasPos),
        ),
        FigmaMenuItem(
          label: 'Add Ellipse',
          icon: Icons.circle_outlined,
          shortcut: 'O',
          onTap: () => _addShapeAt(ShapeType.ellipse, canvasPos),
        ),
        FigmaMenuItem(
          label: 'Add Star',
          icon: Icons.star_border_rounded,
          shortcut: 'S',
          onTap: () => _addShapeAt(ShapeType.star, canvasPos),
        ),
        FigmaMenuItem(
          label: 'Add Polygon',
          icon: Icons.hexagon_outlined,
          shortcut: 'Y',
          onTap: () => _addShapeAt(ShapeType.polygon, canvasPos),
        ),
        FigmaMenuItem(
          label: 'Import SVG / Image...',
          icon: Icons.file_download_outlined,
          shortcut: '⌘I',
          onTap: _importFileFromDevice,
        ),
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: 'Zoom In',
          icon: Icons.zoom_in_rounded,
          shortcut: '⌘+',
          onTap: _zoomIn,
        ),
        FigmaMenuItem(
          label: 'Zoom Out',
          icon: Icons.zoom_out_rounded,
          shortcut: '⌘-',
          onTap: _zoomOut,
        ),
        FigmaMenuItem(
          label: 'Zoom to Fit',
          icon: Icons.fit_screen_rounded,
          shortcut: '⇧0',
          onTap: _zoomToFit,
        ),
        const FigmaMenuDivider(),
        FigmaMenuItem(
          label: 'Canvas Settings',
          icon: Icons.tune_rounded,
          shortcut: '⌘,',
          onTap: _openSettingsDialog,
        ),
        FigmaMenuItem(
          label: 'Export Canvas SVG...',
          icon: Icons.file_upload_outlined,
          shortcut: '⌘E',
          onTap: _openExportDialog,
        ),
      ],
    );
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

        final trimmed = text.trim();
        if (trimmed.contains('<svg') ||
            (trimmed.startsWith('<') &&
                (trimmed.contains('<path') ||
                    trimmed.contains('<rect') ||
                    trimmed.contains('<circle') ||
                    trimmed.contains('<g')))) {
          final importedShapes = SvgImportService.parseSvg(
            trimmed,
            targetOrigin: focalPoint,
          );
          if (importedShapes.isNotEmpty) {
            setState(() {
              shapes.addAll(importedShapes);
              selectedShapeIds.clear();
              selectedShapeIds.addAll(importedShapes.map((s) => s.id));
            });
            _saveHistorySnapshot();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pasted ${importedShapes.length} vector shape(s) from SVG clipboard',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
        }

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

  void _executeBooleanOperation(PathOperation operation) {
    if (selectedShapeIds.length < 2) return;
    _shapeCounter++;
    final combined = CanvasGeometry.combineShapes(
      shapes: shapes,
      selectedIds: selectedShapeIds,
      operation: operation,
      shapeCounter: _shapeCounter,
    );
    if (combined == null) return;

    int minIndex = shapes.length;
    for (int i = 0; i < shapes.length; i++) {
      if (selectedShapeIds.contains(shapes[i].id)) {
        minIndex = math.min(minIndex, i);
      }
    }

    setState(() {
      shapes.removeWhere((s) => selectedShapeIds.contains(s.id));
      shapes.insert(minIndex.clamp(0, shapes.length), combined);
      selectedShapeIds.clear();
      selectedShapeIds.add(combined.id);
    });
    _saveHistorySnapshot();

    String opName = 'Union';
    if (operation == PathOperation.difference) opName = 'Subtract';
    if (operation == PathOperation.intersect) opName = 'Intersect';
    if (operation == PathOperation.xor) opName = 'Exclude';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created Boolean $opName vector shape'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _distributeShapes(String direction) {
    if (selectedShapeIds.length < 3) return;
    setState(() {
      CanvasGeometry.distributeShapes(
        shapes: shapes,
        selectedIds: selectedShapeIds,
        direction: direction,
      );
    });
    _saveHistorySnapshot();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Distributed shapes ${direction == 'horizontal' ? 'horizontally' : 'vertically'}',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final canvasWidth = canvasSize.width;
    final canvasHeight = canvasSize.height;
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

  Future<void> _importFileFromDevice() async {
    try {
      ensureFilePickerInitialized();
      final result = await SafeFilePicker.pickFiles(
        context: context,
        allowedExtensions: FileImportService.supportedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final focalPoint =
            (_isMouseOverCanvas && _lastMouseCanvasPosition != null)
            ? _lastMouseCanvasPosition!
            : _getViewportCanvasCenter();

        final addedShapes = <VectorShape>[];
        for (int i = 0; i < result.files.length; i++) {
          final file = result.files[i];
          final bytes = file.bytes;
          if (bytes != null) {
            final targetPoint = focalPoint + Offset(i * 32.0, i * 32.0);
            final imported = await FileImportService.importFileFromBytes(
              fileName: file.name,
              bytes: bytes,
              targetCanvasPoint: targetPoint,
            );
            if (imported.isSuccess && imported.shapes.isNotEmpty) {
              addedShapes.addAll(imported.shapes);
            }
          }
        }

        if (addedShapes.isNotEmpty) {
          setState(() {
            shapes.addAll(addedShapes);
            selectedShapeIds.clear();
            selectedShapeIds.addAll(addedShapes.map((s) => s.id));
          });
          _saveHistorySnapshot();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Imported ${addedShapes.length} element(s) into canvas',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error importing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handles drag-and-drop file imports from desktop, web, or mobile.
  /// Translates screen drop location into canvas vector coordinates and
  /// places imported assets exactly where dropped.
  Future<void> _handleFilesDropped(
    List<XFile> files,
    Offset localDropPosition,
  ) async {
    if (files.isEmpty) return;

    try {
      final canvasPoint = CanvasTransformHelper.screenToCanvas(
        _transformationController.value,
        localDropPosition,
      );

      final results = await FileImportService.importDropItems(
        files,
        targetCanvasPoint: canvasPoint,
      );

      final addedShapes = <VectorShape>[];
      for (final result in results) {
        if (result.isSuccess && result.shapes.isNotEmpty) {
          addedShapes.addAll(result.shapes);
        }
      }

      if (addedShapes.isNotEmpty) {
        setState(() {
          shapes.addAll(addedShapes);
          selectedShapeIds.clear();
          selectedShapeIds.addAll(addedShapes.map((s) => s.id));
        });
        _saveHistorySnapshot();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Dropped & imported ${addedShapes.length} element(s) at (${canvasPoint.dx.toInt()}, ${canvasPoint.dy.toInt()})',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling dropped files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing dropped files: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openExportDialog() {
    final settings = ref.read(appSettingsProvider);
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        shapes: shapes,
        selectedShapeIds: selectedShapeIds,
        canvasSize: canvasSize,
        fileName: '$fileName.svg',
        initialIncludeXml: settings.svgIncludeXml,
        initialPrettyPrint: settings.svgPrettyPrint,
        initialExportScale: settings.exportScale,
      ),
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
    if (!mounted) return;
    void applyUpdate() {
      if (!mounted) return;
      setState(() {
        final index = shapes.indexWhere((s) => s.id == updated.id);
        if (index != -1) {
          shapes = List.of(shapes);
          shapes[index] = updated;
        }
      });
    }

    if (WidgetsBinding.instance.buildOwner?.debugBuilding == true ||
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
    } else {
      applyUpdate();
    }
  }

  void _onPropertiesShapeChangeEnd(VectorShape updated) {
    if (!mounted) return;
    void applyUpdate() {
      if (!mounted) return;
      setState(() {
        final index = shapes.indexWhere((s) => s.id == updated.id);
        if (index != -1) {
          shapes = List.of(shapes);
          shapes[index] = updated;
        }
      });
      _saveHistorySnapshot();
    }

    if (WidgetsBinding.instance.buildOwner?.debugBuilding == true ||
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
    } else {
      applyUpdate();
    }
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

    if (_editingPathShapeId != null) {
      if (event is KeyDownEvent) {
        final isCtrl =
            HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed;
        if (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _commitPathEdit();
          return KeyEventResult.handled;
        } else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyA) {
          if (_editingPathNodes != null) {
            _selectedPathNodeIndices.clear();
            for (int i = 0; i < _editingPathNodes!.length; i++) {
              _selectedPathNodeIndices.add(i);
            }
            setState(() {});
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_selectedPathNodeIndices.isNotEmpty &&
              _editingPathNodes != null &&
              _editingPathNodes!.length - _selectedPathNodeIndices.length >= 2) {
            final sorted = _selectedPathNodeIndices.toList()
              ..sort((a, b) => b.compareTo(a));
            for (final idx in sorted) {
              if (idx >= 0 && idx < _editingPathNodes!.length) {
                _editingPathNodes!.removeAt(idx);
              }
            }
            _selectedPathNodeIndices.clear();
            _syncEditingNodesToShape();
            _saveHistorySnapshot();
            setState(() {});
          }
          return KeyEventResult.handled;
        } else if (_selectedPathNodeIndices.isNotEmpty &&
            _editingPathNodes != null &&
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
          for (final idx in _selectedPathNodeIndices) {
            if (idx < _editingPathNodes!.length) {
              final n = _editingPathNodes![idx];
              _editingPathNodes![idx] = n.copyWith(
                position: n.position + delta,
                handleIn: n.handleIn != null ? n.handleIn! + delta : null,
                handleOut: n.handleOut != null ? n.handleOut! + delta : null,
              );
            }
          }
          _syncEditingNodesToShape();
          _saveHistorySnapshot();
          setState(() {});
          return KeyEventResult.handled;
        }
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
      final isAlt = HardwareKeyboard.instance.isAltPressed;

      if (isCtrl && isAlt) {
        if (event.logicalKey == LogicalKeyboardKey.keyU) {
          _executeBooleanOperation(PathOperation.union);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          _executeBooleanOperation(PathOperation.difference);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyI) {
          _executeBooleanOperation(PathOperation.intersect);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyX) {
          _executeBooleanOperation(PathOperation.xor);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
          _distributeShapes('horizontal');
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyV) {
          _distributeShapes('vertical');
          return KeyEventResult.handled;
        }
      }

      if (isCtrl) {
        if (event.logicalKey == LogicalKeyboardKey.keyI) {
          _importFileFromDevice();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
          if (shapes.isNotEmpty) {
            _selectAll();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _copySelectedAsSvg();
          } else {
            _copySelected();
          }
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          if (selectedShapeIds.isNotEmpty) {
            final anyLocked = shapes
                .where((s) => selectedShapeIds.contains(s.id))
                .any((s) => s.isLocked);
            setState(() {
              for (final id in selectedShapeIds) {
                shapes.firstWhere((s) => s.id == id).setLocked(!anyLocked);
              }
            });
            _saveHistorySnapshot();
          }
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
        } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _ungroupSelected();
          } else {
            _groupSelected();
          }
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
        if (currentMode == EditorMode.drawPen && _penNodes.isNotEmpty) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            _commitPenPath(isClosed: false);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            setState(() {
              _penNodes.clear();
              _isPenDraggingHandle = false;
              _isClosingNode = false;
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            setState(() {
              _penNodes.removeLast();
              if (_penNodes.isEmpty) {
                _isPenDraggingHandle = false;
                _isClosingNode = false;
              }
            });
            return KeyEventResult.handled;
          }
        }

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
            if (selected != null) {
              if (selected.type == ShapeType.text) {
                _startTextEditing(selected, isNew: false, selectAll: true);
                return KeyEventResult.handled;
              } else if (selected.type == ShapeType.path ||
                  selected.type == ShapeType.line) {
                _enterPathEditMode(selected);
                return KeyEventResult.handled;
              }
            }
          }
        } else if (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) {
          _deleteSelected();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.bracketRight) {
          _bringToFront();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
          _sendToBack();
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
              s.shiftPosition(delta);
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
            event.logicalKey == LogicalKeyboardKey.keyB) {
          setState(() => currentMode = EditorMode.drawCurve);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
          if (selectedShapeIds.length == 1) {
            final selected = shapes.cast<VectorShape?>().firstWhere(
              (s) => s?.id == selectedShapeIds.first,
              orElse: () => null,
            );
            if (selected != null &&
                (selected.type == ShapeType.path ||
                    selected.type == ShapeType.line)) {
              _enterPathEditMode(selected);
              return KeyEventResult.handled;
            }
          }
          setState(() => currentMode = EditorMode.drawPen);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          setState(() => currentMode = EditorMode.drawStar);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
          setState(() => currentMode = EditorMode.drawPolygon);
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
                  onImportImage: _importFileFromDevice,
                  onBooleanOperation: _executeBooleanOperation,
                  selectedShapesCount: selectedShapeIds.length,
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
                  showLayers:
                      isLayersPanelOpen ??
                      appSettings.showLayers ??
                      (!isCompact),
                  onToggleLayers: (val) {
                    setState(() => isLayersPanelOpen = val);
                    ref.read(appSettingsProvider.notifier).setShowLayers(val);
                  },
                  showProperties:
                      isPropertiesPanelOpen ??
                      appSettings.showProperties ??
                      (!isCompact),
                  onToggleProperties: (val) {
                    setState(() => isPropertiesPanelOpen = val);
                    ref
                        .read(appSettingsProvider.notifier)
                        .setShowProperties(val);
                  },
                ),
              ),

              // Main Editor Workbench Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showLayers =
                        isLayersPanelOpen ??
                        appSettings.showLayers ??
                        (!isCompact);
                    final showProperties =
                        isPropertiesPanelOpen ??
                        appSettings.showProperties ??
                        (!isCompact);

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
                                  s.setVisible(!s.isVisible);
                                  if (!s.isVisible) {
                                    selectedShapeIds.remove(id);
                                  }
                                });
                                _saveHistorySnapshot();
                              },
                              onToggleLock: (id) {
                                setState(() {
                                  final s = shapes.firstWhere(
                                    (s) => s.id == id,
                                  );
                                  s.setLocked(!s.isLocked);
                                });
                                _saveHistorySnapshot();
                              },
                              onDeleteShape: _deleteShapeById,
                              onSelectShapes: _handleSelectShapes,
                              onBringToFront: _bringToFront,
                              onBringForward: _bringForward,
                              onSendBackward: _sendBackward,
                              onSendToBack: _sendToBack,
                              onDuplicateShape: _duplicateShapeById,
                              onCopySvg: _copyShapeAsSvgById,
                              onGroupShapes: _groupSelected,
                              onUngroupShapes: _ungroupSelected,
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

                        // Center Workspace Interactive Canvas with Custom Drag & Drop
                        Expanded(
                          child: NixFileDropZone(
                            onFilesDropped: _handleFilesDropped,
                            child: Stack(
                              children: [
                              InteractiveCanvas(
                                key: _canvasKey,
                                transformationController:
                                    _transformationController,
                                shapes: shapes,
                                selectedShapeIds: selectedShapeIds,
                                currentMode: currentMode,
                                canvasSize: canvasSize,
                                artboardTitle: fileName,
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
                                activePenNodes:
                                    currentMode == EditorMode.drawPen &&
                                        _penNodes.isNotEmpty
                                    ? List.unmodifiable(_penNodes)
                                    : null,
                                activePenCursor:
                                    currentMode == EditorMode.drawPen &&
                                        _penNodes.isNotEmpty
                                    ? _lastMouseCanvasPosition
                                    : null,
                                isPenHoveringStart: _isPenHoveringStart,
                                editingPathShapeId: _editingPathShapeId,
                                editingPathNodes: _editingPathNodes,
                                selectedPathNodeIndices:
                                    _selectedPathNodeIndices,
                                hoveredPathNodeIndex: _hoveredPathNodeIndex,
                                activeHandleNodeIndex: _activeHandleNodeIndex,
                                activeHandleType: _activeHandleType,
                                isPathClosed: _isEditingPathClosed,
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
                                onMatrixChanged: _handleMatrixChanged,
                                onCanvasHoverChanged: (hovered) =>
                                    _isMouseOverCanvas = hovered,
                                onPointerHover: (pos) =>
                                    _lastMouseCanvasPosition = pos,
                                onSecondaryTap: _handleCanvasContextMenu,
                              ),

                              // Backdrop Scrim for Compact Mobile Drawers
                              if (isCompact && (showLayers || showProperties))
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        if (showLayers) {
                                          isLayersPanelOpen = false;
                                          ref
                                              .read(
                                                appSettingsProvider.notifier,
                                              )
                                              .setShowLayers(false);
                                        }
                                        if (showProperties) {
                                          isPropertiesPanelOpen = false;
                                          ref
                                              .read(
                                                appSettingsProvider.notifier,
                                              )
                                              .setShowProperties(false);
                                        }
                                      });
                                    },
                                    child: Container(
                                      color: Colors.black.withValues(
                                        alpha:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 0.45
                                            : 0.25,
                                      ),
                                    ),
                                  ),
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
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: -1.0, end: 0.0),
                                    duration: const Duration(milliseconds: 240),
                                    curve: M3PhysicsSpring.expressiveCurve,
                                    builder: (context, slide, child) {
                                      return FractionalTranslation(
                                        translation: Offset(slide, 0),
                                        child: child,
                                      );
                                    },
                                    child: Material(
                                      elevation: 12,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      color: colorScheme.surfaceContainer,
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                            right: Radius.circular(16),
                                          ),
                                      clipBehavior: Clip.antiAlias,
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
                                              s.setVisible(!s.isVisible);
                                              if (!s.isVisible) {
                                                selectedShapeIds.remove(id);
                                              }
                                            });
                                            _saveHistorySnapshot();
                                          },
                                          onToggleLock: (id) {
                                            setState(() {
                                              final s = shapes.firstWhere(
                                                (s) => s.id == id,
                                              );
                                              s.setLocked(!s.isLocked);
                                            });
                                            _saveHistorySnapshot();
                                          },
                                          onDeleteShape: _deleteShapeById,
                                          onSelectShapes: _handleSelectShapes,
                                          onBringToFront: _bringToFront,
                                          onBringForward: _bringForward,
                                          onSendBackward: _sendBackward,
                                          onSendToBack: _sendToBack,
                                          onDuplicateShape: _duplicateShapeById,
                                          onCopySvg: _copyShapeAsSvgById,
                                          onGroupShapes: _groupSelected,
                                          onUngroupShapes: _ungroupSelected,
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
                                              if (newIndex > oldIndex) {
                                                newIndex--;
                                              }
                                              final displayList = shapes
                                                  .reversed
                                                  .toList();
                                              final shape = displayList
                                                  .removeAt(oldIndex);
                                              displayList.insert(
                                                newIndex,
                                                shape,
                                              );
                                              shapes = displayList.reversed
                                                  .toList();
                                            });
                                            _saveHistorySnapshot();
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Overlay Properties for Compact Mobile Screens
                              if (isCompact && showProperties)
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  right: 0,
                                  width:
                                      ResponsiveLayoutTokens.getCompactDrawerWidth(
                                        constraints.maxWidth,
                                      ),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 1.0, end: 0.0),
                                    duration: const Duration(milliseconds: 240),
                                    curve: M3PhysicsSpring.expressiveCurve,
                                    builder: (context, slide, child) {
                                      return FractionalTranslation(
                                        translation: Offset(slide, 0),
                                        child: child,
                                      );
                                    },
                                    child: Material(
                                      elevation: 12,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      color: colorScheme.surfaceContainer,
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                            left: Radius.circular(16),
                                          ),
                                      clipBehavior: Clip.antiAlias,
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
                                          onOpenColorPickerFill:
                                              ([anchorRect]) =>
                                                  _openColorPicker(
                                                    true,
                                                    anchorRect,
                                                  ),
                                          onOpenColorPickerStroke:
                                              ([anchorRect]) =>
                                                  _openColorPicker(
                                                    false,
                                                    anchorRect,
                                                  ),
                                          onDuplicateShape: _duplicateSelected,
                                          onDeleteSelected: _deleteSelected,
                                          onAlignShape: _alignShapes,
                                          onDistributeShapes: _distributeShapes,
                                          onBooleanOperation:
                                              _executeBooleanOperation,
                                          selectedShapesCount:
                                              selectedShapeIds.length,
                                          onGroupShapes: _groupSelected,
                                          onUngroupShapes: _ungroupSelected,
                                          canGroup: selectedShapeIds.isNotEmpty,
                                          canUngroup: shapes
                                              .where(
                                                (s) => selectedShapeIds
                                                    .contains(s.id),
                                              )
                                              .any((s) => s.groupId != null),
                                          canvasSize: canvasSize,
                                          onCanvasSizeChanged: (newSize) {
                                            setState(
                                              () => canvasSize = newSize,
                                            );
                                            _saveHistorySnapshot();
                                          },
                                          canvasBackgroundColor:
                                              canvasBackgroundColor,
                                          onCanvasBackgroundColorChanged:
                                              (col) {
                                                setState(
                                                  () => canvasBackgroundColor =
                                                      col,
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
                                          if (_editingPathShapeId != null) {
                                            _commitPathEdit();
                                          }
                                          if (currentMode ==
                                                  EditorMode.drawPen &&
                                              _penNodes.length >= 2) {
                                            _commitPenPath(isClosed: false);
                                          } else {
                                            _penNodes.clear();
                                            _isPenDraggingHandle = false;
                                            _isClosingNode = false;
                                          }
                                          setState(() => currentMode = mode);
                                        },
                                        onExportSvg: _openExportDialog,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Vector Edit Mode Floating Banner
                              if (_editingPathShapeId != null)
                                Positioned(
                                  top: appSettings.toolbarPosition == 'top'
                                      ? 72.0
                                      : 16.0,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Material(
                                      elevation: 6,
                                      shadowColor: Colors.black38,
                                      borderRadius: BorderRadius.circular(28),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timeline_rounded,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Vector Edit Mode',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• Drag points/handles, double-click to toggle curve, Del to remove',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            FilledButton(
                                              onPressed: _commitPathEdit,
                                              style: FilledButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 6,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Text(
                                                'Done',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                              onDistributeShapes: _distributeShapes,
                              onBooleanOperation: _executeBooleanOperation,
                              selectedShapesCount: selectedShapeIds.length,
                              onGroupShapes: _groupSelected,
                              onUngroupShapes: _ungroupSelected,
                              canGroup: selectedShapeIds.isNotEmpty,
                              canUngroup: shapes
                                  .where((s) => selectedShapeIds.contains(s.id))
                                  .any((s) => s.groupId != null),
                              canvasSize: canvasSize,
                              onCanvasSizeChanged: (newSize) {
                                setState(() => canvasSize = newSize);
                                _saveHistorySnapshot();
                              },
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
      case EditorMode.drawPen:
        return ShapeType.path;
      case EditorMode.drawStar:
        return ShapeType.star;
      case EditorMode.drawPolygon:
        return ShapeType.polygon;
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
      case EditorMode.drawPen:
        return 'Pen';
      case EditorMode.drawStar:
        return 'Star';
      case EditorMode.drawPolygon:
        return 'Polygon';
      case EditorMode.drawText:
        return 'Text';
      default:
        return 'Shape';
    }
  }
}
