import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_color_scheme/m3e_color_scheme.dart';
import 'package:m3e_typography/m3e_typography.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/models/undo_redo_manager.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/grid_painter.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:nixsvg/widgets/color_picker_dialog.dart';
import 'package:nixsvg/widgets/export_dialog.dart';
import 'package:nixsvg/widgets/floating_tool_bar.dart';
import 'package:nixsvg/widgets/layers_sidebar.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';
import 'package:nixsvg/widgets/shortcuts_dialog.dart';
import 'package:nixsvg/widgets/top_navigation_bar.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

void _ensureFilePickerInitialized() {
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _ensureFilePickerInitialized();
  ResponsiveScaler.instance.init(
    designWidth: 1280,
    designHeight: 800,
    minScale: 1.0,
    maxScale: 1.25,
  );
  runApp(const NixSvgApp());
}

class NixSvgApp extends StatelessWidget {
  const NixSvgApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveScaler.instance.isInitialized) {
      ResponsiveScaler.instance.init(
        designWidth: 1280,
        designHeight: 800,
        minScale: 1.0,
        maxScale: 1.25,
      );
    }

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final seedColor = themeController.seedColor;

        final m3eLight = M3EColorScheme.light(
          seedColor: seedColor,
          variant: M3EColorVariant.vibrant,
        );

        final m3eDark = M3EColorScheme.dark(
          seedColor: seedColor,
          variant: M3EColorVariant.vibrant,
        );

        final lightScheme = ColorScheme(
          brightness: Brightness.light,
          primary: m3eLight.primary,
          onPrimary: m3eLight.onPrimary,
          primaryContainer: m3eLight.primaryContainer,
          onPrimaryContainer: m3eLight.onPrimaryContainer,
          secondary: m3eLight.secondary,
          onSecondary: m3eLight.onSecondary,
          secondaryContainer: m3eLight.secondaryContainer,
          onSecondaryContainer: m3eLight.onSecondaryContainer,
          tertiary: m3eLight.tertiary,
          onTertiary: m3eLight.onTertiary,
          tertiaryContainer: m3eLight.tertiaryContainer,
          onTertiaryContainer: m3eLight.onTertiaryContainer,
          error: m3eLight.error,
          onError: m3eLight.onError,
          errorContainer: m3eLight.errorContainer,
          onErrorContainer: m3eLight.onErrorContainer,
          surface: m3eLight.surface,
          onSurface: m3eLight.onSurface,
          onSurfaceVariant: m3eLight.onSurfaceVariant,
          surfaceContainerLowest: m3eLight.surfaceContainerLowest,
          surfaceContainerLow: m3eLight.surfaceContainerLow,
          surfaceContainer: m3eLight.surfaceContainer,
          surfaceContainerHigh: m3eLight.surfaceContainerHigh,
          surfaceContainerHighest: m3eLight.surfaceContainerHighest,
          outline: m3eLight.outline,
          outlineVariant: m3eLight.outlineVariant,
          inverseSurface: m3eLight.inverseSurface,
          onInverseSurface: m3eLight.onInverseSurface,
          inversePrimary: m3eLight.inversePrimary,
          scrim: m3eLight.scrim,
          shadow: m3eLight.shadow,
          surfaceTint: m3eLight.surfaceTint,
        );

        final darkScheme = ColorScheme(
          brightness: Brightness.dark,
          primary: m3eDark.primary,
          onPrimary: m3eDark.onPrimary,
          primaryContainer: m3eDark.primaryContainer,
          onPrimaryContainer: m3eDark.onPrimaryContainer,
          secondary: m3eDark.secondary,
          onSecondary: m3eDark.onSecondary,
          secondaryContainer: m3eDark.secondaryContainer,
          onSecondaryContainer: m3eDark.onSecondaryContainer,
          tertiary: m3eDark.tertiary,
          onTertiary: m3eDark.onTertiary,
          tertiaryContainer: m3eDark.tertiaryContainer,
          onTertiaryContainer: m3eDark.onTertiaryContainer,
          error: m3eDark.error,
          onError: m3eDark.onError,
          errorContainer: m3eDark.errorContainer,
          onErrorContainer: m3eDark.onErrorContainer,
          surface: m3eDark.surface,
          onSurface: m3eDark.onSurface,
          onSurfaceVariant: m3eDark.onSurfaceVariant,
          surfaceContainerLowest: m3eDark.surfaceContainerLowest,
          surfaceContainerLow: m3eDark.surfaceContainerLow,
          surfaceContainer: m3eDark.surfaceContainer,
          surfaceContainerHigh: m3eDark.surfaceContainerHigh,
          surfaceContainerHighest: m3eDark.surfaceContainerHighest,
          outline: m3eDark.outline,
          outlineVariant: m3eDark.outlineVariant,
          inverseSurface: m3eDark.inverseSurface,
          onInverseSurface: m3eDark.onInverseSurface,
          inversePrimary: m3eDark.inversePrimary,
          scrim: m3eDark.scrim,
          shadow: m3eDark.shadow,
          surfaceTint: m3eDark.surfaceTint,
        );

        final lightBase = Typography.material2021().black.apply(
          bodyColor: lightScheme.onSurface,
          displayColor: lightScheme.onSurface,
        );
        final lightTextTheme = M3ETypography.emphasized(lightBase);

        final darkBase = Typography.material2021().white.apply(
          bodyColor: darkScheme.onSurface,
          displayColor: darkScheme.onSurface,
        );
        final darkTextTheme = M3ETypography.emphasized(darkBase);

        return MaterialApp(
          title: 'nixSVG - Vector Studio',
          debugShowCheckedModeBanner: false,

          supportedLocales: const [Locale('en', 'US')],

          themeMode: themeController.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: lightScheme,
            scaffoldBackgroundColor: lightScheme.surface,
            textTheme: lightTextTheme,
            shadowColor: Colors.transparent,
            dividerTheme: DividerThemeData(
              color: lightScheme.outlineVariant.withValues(alpha: 0.3),
              thickness: 1,
            ),
            iconTheme: IconThemeData(
              color: lightScheme.onSurfaceVariant,
              size: 20,
            ),
            primaryIconTheme: IconThemeData(
              color: lightScheme.primary,
              size: 20,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: lightScheme.primary,
                foregroundColor: lightScheme.onPrimary,
                disabledBackgroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: lightTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: lightScheme.surfaceContainerLow,
                foregroundColor: lightScheme.primary,
                disabledBackgroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: lightTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                foregroundColor: lightScheme.primary,
                disabledForegroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                side: BorderSide(
                  color: lightScheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: lightTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                foregroundColor: lightScheme.primary,
                disabledForegroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: lightTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: lightScheme.onSurfaceVariant,
                disabledForegroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                hoverColor: lightScheme.surfaceContainerHighest,
                highlightColor: lightScheme.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: SegmentedButton.styleFrom(
                backgroundColor: lightScheme.surfaceContainerLow,
                foregroundColor: lightScheme.onSurfaceVariant,
                selectedBackgroundColor: lightScheme.primary,
                selectedForegroundColor: lightScheme.onPrimary,
                disabledBackgroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: lightScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: lightScheme.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
                textStyle: lightTextTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              disabledElevation: 0,
              backgroundColor: lightScheme.primaryContainer,
              foregroundColor: lightScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            chipTheme: ChipThemeData(
              elevation: 0,
              pressElevation: 0,
              shadowColor: Colors.transparent,
              backgroundColor: lightScheme.surfaceContainerLow,
              selectedColor: lightScheme.primary,
              labelStyle: lightTextTheme.labelMedium?.copyWith(
                color: lightScheme.onSurfaceVariant,
              ),
              secondaryLabelStyle: lightTextTheme.labelMedium?.copyWith(
                color: lightScheme.onPrimary,
              ),
              side: BorderSide(
                color: lightScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            popupMenuTheme: PopupMenuThemeData(
              color: lightScheme.surfaceContainerHigh,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: lightScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            dialogTheme: DialogThemeData(
              elevation: 0,
              backgroundColor: lightScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkScheme.surface,
            textTheme: darkTextTheme,
            shadowColor: Colors.transparent,
            dividerTheme: DividerThemeData(
              color: darkScheme.outlineVariant.withValues(alpha: 0.3),
              thickness: 1,
            ),
            iconTheme: IconThemeData(
              color: darkScheme.onSurfaceVariant,
              size: 20,
            ),
            primaryIconTheme: IconThemeData(
              color: darkScheme.primary,
              size: 20,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: darkScheme.primary,
                foregroundColor: darkScheme.onPrimary,
                disabledBackgroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: darkTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: darkScheme.surfaceContainerHigh,
                foregroundColor: darkScheme.primary,
                disabledBackgroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: darkTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                foregroundColor: darkScheme.primary,
                disabledForegroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                side: BorderSide(
                  color: darkScheme.outlineVariant.withValues(alpha: 0.8),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: darkTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                foregroundColor: darkScheme.primary,
                disabledForegroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: darkTextTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: darkScheme.onSurfaceVariant,
                disabledForegroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                hoverColor: darkScheme.surfaceContainerHighest,
                highlightColor: darkScheme.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: SegmentedButton.styleFrom(
                backgroundColor: darkScheme.surfaceContainerHigh,
                foregroundColor: darkScheme.onSurfaceVariant,
                selectedBackgroundColor: darkScheme.primary,
                selectedForegroundColor: darkScheme.onPrimary,
                disabledBackgroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: darkScheme.onSurface.withValues(
                  alpha: 0.38,
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: darkScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
                textStyle: darkTextTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              disabledElevation: 0,
              backgroundColor: darkScheme.primaryContainer,
              foregroundColor: darkScheme.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            chipTheme: ChipThemeData(
              elevation: 0,
              pressElevation: 0,
              shadowColor: Colors.transparent,
              backgroundColor: darkScheme.surfaceContainerHigh,
              selectedColor: darkScheme.primary,
              labelStyle: darkTextTheme.labelMedium?.copyWith(
                color: darkScheme.onSurfaceVariant,
              ),
              secondaryLabelStyle: darkTextTheme.labelMedium?.copyWith(
                color: darkScheme.onPrimary,
              ),
              side: BorderSide(
                color: darkScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            popupMenuTheme: PopupMenuThemeData(
              color: darkScheme.surfaceContainerHigh,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: darkScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            dialogTheme: DialogThemeData(
              elevation: 0,
              backgroundColor: darkScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final muiScheme = isDark ? m3eDark : m3eLight;
            return mui.Theme(
              data: mui.ThemeData(
                useMaterial3: true,
                brightness: isDark ? Brightness.dark : Brightness.light,
                colorScheme: muiScheme,
                shadowColor: Colors.transparent,
                filledButtonTheme: mui.FilledButtonThemeData(
                  style: mui.FilledButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    backgroundColor: muiScheme.primary,
                    foregroundColor: muiScheme.onPrimary,
                  ),
                ),
                elevatedButtonTheme: mui.ElevatedButtonThemeData(
                  style: mui.ElevatedButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    backgroundColor: muiScheme.surfaceContainerHigh,
                    foregroundColor: muiScheme.primary,
                  ),
                ),
                outlinedButtonTheme: mui.OutlinedButtonThemeData(
                  style: mui.OutlinedButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    foregroundColor: muiScheme.primary,
                    side: mui.BorderSide(color: muiScheme.outlineVariant),
                  ),
                ),
                textButtonTheme: mui.TextButtonThemeData(
                  style: mui.TextButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    foregroundColor: muiScheme.primary,
                  ),
                ),
                iconButtonTheme: mui.IconButtonThemeData(
                  style: mui.IconButton.styleFrom(
                    foregroundColor: muiScheme.onSurfaceVariant,
                    hoverColor: muiScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              child: ResponsiveScaler.scale(
                context: context,
                child: child!,
                useMaxAccessibility: true,
              ),
            );
          },
          home: SafeArea(child: const FigmaWorkspace()),
        );
      },
    );
  }
}

class FigmaWorkspace extends StatefulWidget {
  const FigmaWorkspace({super.key});

  @override
  State<FigmaWorkspace> createState() => FigmaWorkspaceState();
}

class FigmaWorkspaceState extends State<FigmaWorkspace> {
  // Canvas State
  final TransformationController _transformationController =
      TransformationController();
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
  Offset? snapGuidelineX;
  Offset? snapGuidelineY;
  bool _isPanningWithMouse = false;
  Offset? _lastPanPosition;

  // Creation Draft
  ShapeType? draftShapeType;
  int _shapeCounter = 1;

  @override
  void initState() {
    super.initState();
    _loadSampleDemoShapes();
    _saveHistorySnapshot();
  }

  @override
  void dispose() {
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

  // Hit Testing Methods
  bool _hitTestShape(Offset point, VectorShape shape) {
    if (!shape.isVisible || shape.isLocked) return false;

    // Generous touch / pointer padding (especially for lines which have zero height)
    if (shape.type == ShapeType.line && !shape.isStroked) return false;
    final padding = shape.type == ShapeType.line ? 16.0 : 8.0;
    final effectiveRect = Rect.fromLTRB(
      math.min(shape.rect.left, shape.rect.right) - padding,
      math.min(shape.rect.top, shape.rect.bottom) - padding,
      math.max(shape.rect.left, shape.rect.right) + padding,
      math.max(shape.rect.top, shape.rect.bottom) + padding,
    );

    if (shape.rotation == 0.0 && shape.type != ShapeType.line) {
      return effectiveRect.contains(point);
    }

    // Transform query point into shape's unrotated coordinate system
    final center = shape.rect.center;
    final rad = -shape.rotation * math.pi / 180.0;
    final cosVal = math.cos(rad);
    final sinVal = math.sin(rad);
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final unrotatedPoint = Offset(
      center.dx + dx * cosVal - dy * sinVal,
      center.dy + dx * sinVal + dy * cosVal,
    );

    if (shape.type == ShapeType.line) {
      final p = unrotatedPoint;
      final v = shape.rect.topLeft;
      final w = shape.rect.bottomRight;
      final l2 = (w.dx - v.dx) * (w.dx - v.dx) + (w.dy - v.dy) * (w.dy - v.dy);
      double distance;
      if (l2 == 0.0) {
        distance = (p - v).distance;
      } else {
        var t =
            ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) /
            l2;
        t = math.max(0.0, math.min(1.0, t));
        final projection = Offset(
          v.dx + t * (w.dx - v.dx),
          v.dy + t * (w.dy - v.dy),
        );
        distance = (p - projection).distance;
      }
      return distance <= padding;
    }

    return effectiveRect.contains(unrotatedPoint);
  }

  Offset _snapLinePoint(Offset start, Offset current) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return current;
    final angle = math.atan2(dy, dx);
    final snapAngle = (angle / (math.pi / 4)).round() * (math.pi / 4);
    return start +
        Offset(distance * math.cos(snapAngle), distance * math.sin(snapAngle));
  }

  ResizeHandle _hitTestHandle(Offset pos, VectorShape shape) {
    final rect = shape.rect;
    const double hitSize = 28.0; // Touch and mouse friendly handle size

    Offset testPos = pos;
    if (shape.rotation != 0.0) {
      final center = shape.rect.center;
      final rad = -shape.rotation * math.pi / 180.0;
      final cosVal = math.cos(rad);
      final sinVal = math.sin(rad);
      final dx = pos.dx - center.dx;
      final dy = pos.dy - center.dy;
      testPos = Offset(
        center.dx + dx * cosVal - dy * sinVal,
        center.dy + dx * sinVal + dy * cosVal,
      );
    }

    if (shape.type == ShapeType.line) {
      if (Rect.fromCenter(
        center: rect.topLeft,
        width: hitSize,
        height: hitSize,
      ).contains(testPos)) {
        return ResizeHandle.topLeft;
      }
      if (Rect.fromCenter(
        center: rect.bottomRight,
        width: hitSize,
        height: hitSize,
      ).contains(testPos)) {
        return ResizeHandle.bottomRight;
      }
      if (shape.isCurved || shape.curvature != 0.0) {
        final startPt = rect.topLeft;
        final endPt = rect.bottomRight;
        final mid = Offset(
          (startPt.dx + endPt.dx) / 2,
          (startPt.dy + endPt.dy) / 2,
        );
        final dx = endPt.dx - startPt.dx;
        final dy = endPt.dy - startPt.dy;
        final len = math.sqrt(dx * dx + dy * dy);
        final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
        final controlPt = mid + perp * shape.curvature;
        if (Rect.fromCenter(
          center: controlPt,
          width: hitSize,
          height: hitSize,
        ).contains(testPos)) {
          return ResizeHandle.topCenter;
        }
      }
      return ResizeHandle.none;
    }

    // Rotation Handle (located 24px above top center)
    if (Rect.fromCenter(
      center: Offset(rect.topCenter.dx, rect.topCenter.dy - 24),
      width: hitSize + 4,
      height: hitSize + 4,
    ).contains(testPos)) {
      return ResizeHandle.rotation;
    }

    // Corner Handles
    if (Rect.fromCenter(
      center: rect.topLeft,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.topLeft;
    }
    if (Rect.fromCenter(
      center: rect.topRight,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.topRight;
    }
    if (Rect.fromCenter(
      center: rect.bottomLeft,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomLeft;
    }
    if (Rect.fromCenter(
      center: rect.bottomRight,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomRight;
    }

    // Edge Midpoint Handles
    if (Rect.fromCenter(
      center: rect.topCenter,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.topCenter;
    }
    if (Rect.fromCenter(
      center: rect.bottomCenter,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.bottomCenter;
    }
    if (Rect.fromCenter(
      center: rect.centerLeft,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.centerLeft;
    }
    if (Rect.fromCenter(
      center: rect.centerRight,
      width: hitSize,
      height: hitSize,
    ).contains(testPos)) {
      return ResizeHandle.centerRight;
    }

    return ResizeHandle.none;
  }

  // Pointer Down / Move / Up / Cancel Gestures
  void _onPointerDown(PointerDownEvent event) {
    final isSpacePressed = HardwareKeyboard.instance.logicalKeysPressed
        .contains(LogicalKeyboardKey.space);
    final isMiddleButton = (event.buttons & kMiddleMouseButton) != 0;

    if (isSpacePressed || isMiddleButton) {
      _isPanningWithMouse = true;
      _lastPanPosition = event.position;
      return;
    }

    final localPos = event.localPosition;
    panStartOffset = localPos;
    panCurrentOffset = localPos;

    if (currentMode == EditorMode.select) {
      // 1. Check if hit resize or rotation handle of single selected shape
      if (selectedShapeIds.length == 1) {
        final singleSelected = shapes.firstWhere(
          (s) => s.id == selectedShapeIds.first,
        );
        if (!singleSelected.isLocked) {
          activeResizeHandle = _hitTestHandle(localPos, singleSelected);
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
        if (_hitTestShape(localPos, shape)) {
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
            // If clicking a shape not yet in selection, select only this shape
            if (!selectedShapeIds.contains(matchedShape.id)) {
              selectedShapeIds.clear();
              selectedShapeIds.add(matchedShape.id);
            }
            // If already in selection, maintain selection so whole group moves together
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
      setState(() {
        selectedShapeIds.clear();
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
      final scale = _transformationController.value.getMaxScaleOnAxis();
      final matrix = _transformationController.value.clone();
      matrix.translate(delta.dx / scale, delta.dy / scale);
      setState(() {
        _transformationController.value = matrix;
      });
      return;
    }

    if (panStartOffset == null) return;

    final localPos = event.localPosition;
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
      panCurrentOffset = _snapLinePoint(panStartOffset!, localPos);
    } else {
      panCurrentOffset = localPos;
    }

    setState(() {
      if (currentMode == EditorMode.select) {
        if (marqueeRect != null) {
          marqueeRect = Rect.fromPoints(panStartOffset!, localPos);
          _updateMarqueeSelection();
        } else if (isRotatingShape && selectedShapeIds.length == 1) {
          final target = shapes.firstWhere(
            (s) => s.id == selectedShapeIds.first,
          );
          final center = target.rect.center;
          final angle =
              math.atan2(localPos.dy - center.dy, localPos.dx - center.dx) *
                  180 /
                  math.pi +
              90;
          target.rotation = (angle % 360).roundToDouble();
        } else if (activeResizeHandle != ResizeHandle.none &&
            selectedShapeIds.length == 1 &&
            initialShapeRects != null) {
          final target = shapes.firstWhere(
            (s) => s.id == selectedShapeIds.first,
          );
          final initialRect = initialShapeRects![target.id]!;
          target.rect = _resizeRect(
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
          for (final id in selectedShapeIds) {
            final s = shapes.firstWhere((s) => s.id == id);
            final initR = initialShapeRects![id]!;
            s.rect = initR.shift(delta);
          }
          _updateSnapGuidelines();
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
            ? _snapLinePoint(panStartOffset!, localPos)
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
          // If the user just clicked, create a default sized text box
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
    _onPointerUp(PointerUpEvent(position: event.position));
  }

  void _updateMarqueeSelection() {
    if (marqueeRect == null) return;
    final normalizedMarquee = Rect.fromLTRB(
      math.min(marqueeRect!.left, marqueeRect!.right),
      math.min(marqueeRect!.top, marqueeRect!.bottom),
      math.max(marqueeRect!.left, marqueeRect!.right),
      math.max(marqueeRect!.top, marqueeRect!.bottom),
    );
    for (final shape in shapes) {
      if (shape.isVisible && !shape.isLocked) {
        if (normalizedMarquee.overlaps(shape.rect.inflate(8.0))) {
          selectedShapeIds.add(shape.id);
        }
      }
    }
  }

  void _updateSnapGuidelines() {
    snapGuidelineX = null;
    snapGuidelineY = null;
    if (selectedShapeIds.length != 1) return;
    final target = shapes.firstWhere((s) => s.id == selectedShapeIds.first);

    for (final s in shapes) {
      if (s.id == target.id || !s.isVisible) continue;
      if ((target.rect.center.dx - s.rect.center.dx).abs() < 5) {
        snapGuidelineX = Offset(s.rect.center.dx, 0);
      }
      if ((target.rect.center.dy - s.rect.center.dy).abs() < 5) {
        snapGuidelineY = Offset(0, s.rect.center.dy);
      }
    }
  }

  Rect _resizeRect(
    Rect initial,
    Offset start,
    Offset current,
    ResizeHandle handle, {
    bool isLine = false,
  }) {
    double left = initial.left;
    double top = initial.top;
    double right = initial.right;
    double bottom = initial.bottom;

    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    const double minSize = 10.0;

    if (isLine) {
      final isShiftPressed =
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftLeft,
          ) ||
          HardwareKeyboard.instance.logicalKeysPressed.contains(
            LogicalKeyboardKey.shiftRight,
          );

      Offset startPoint = initial.topLeft;
      Offset endPoint = initial.bottomRight;

      switch (handle) {
        case ResizeHandle.topLeft:
          final rawStart = Offset(initial.left + dx, initial.top + dy);
          final anchor = endPoint;
          startPoint = isShiftPressed
              ? _snapLinePoint(anchor, rawStart)
              : rawStart;
          break;
        case ResizeHandle.bottomRight:
          final rawEnd = Offset(initial.right + dx, initial.bottom + dy);
          final anchor = startPoint;
          endPoint = isShiftPressed ? _snapLinePoint(anchor, rawEnd) : rawEnd;
          break;
        case ResizeHandle.topRight:
          final rawPoint = Offset(initial.right + dx, initial.top + dy);
          final anchor = initial.bottomLeft;
          final snapped = isShiftPressed
              ? _snapLinePoint(anchor, rawPoint)
              : rawPoint;
          endPoint = Offset(snapped.dx, endPoint.dy);
          startPoint = Offset(startPoint.dx, snapped.dy);
          break;
        case ResizeHandle.bottomLeft:
          final rawPoint = Offset(initial.left + dx, initial.bottom + dy);
          final anchor = initial.topRight;
          final snapped = isShiftPressed
              ? _snapLinePoint(anchor, rawPoint)
              : rawPoint;
          startPoint = Offset(snapped.dx, startPoint.dy);
          endPoint = Offset(endPoint.dx, snapped.dy);
          break;
        default:
          break;
      }
      return Rect.fromLTRB(
        startPoint.dx,
        startPoint.dy,
        endPoint.dx,
        endPoint.dy,
      );
    }

    switch (handle) {
      case ResizeHandle.topLeft:
        left = math.min(initial.left + dx, right - minSize);
        top = math.min(initial.top + dy, bottom - minSize);
        break;
      case ResizeHandle.topRight:
        right = math.max(initial.right + dx, left + minSize);
        top = math.min(initial.top + dy, bottom - minSize);
        break;
      case ResizeHandle.bottomLeft:
        left = math.min(initial.left + dx, right - minSize);
        bottom = math.max(initial.bottom + dy, top + minSize);
        break;
      case ResizeHandle.bottomRight:
        right = math.max(initial.right + dx, left + minSize);
        bottom = math.max(initial.bottom + dy, top + minSize);
        break;
      case ResizeHandle.topCenter:
        top = math.min(initial.top + dy, bottom - minSize);
        break;
      case ResizeHandle.bottomCenter:
        bottom = math.max(initial.bottom + dy, top + minSize);
        break;
      case ResizeHandle.centerLeft:
        left = math.min(initial.left + dx, right - minSize);
        break;
      case ResizeHandle.centerRight:
        right = math.max(initial.right + dx, left + minSize);
        break;
      case ResizeHandle.rotation:
      case ResizeHandle.none:
        break;
    }

    return Rect.fromLTRB(left, top, right, bottom);
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
    if (selectedShapeIds.isEmpty) return;
    final first = shapes.firstWhere((s) => s.id == selectedShapeIds.first);
    final bounds = first.rect;

    setState(() {
      for (final id in selectedShapeIds) {
        final shape = shapes.firstWhere((s) => s.id == id);
        double left = shape.rect.left;
        double top = shape.rect.top;

        switch (align) {
          case 'left':
            left = bounds.left;
            break;
          case 'center':
            left = bounds.center.dx - shape.rect.width / 2;
            break;
          case 'right':
            left = bounds.right - shape.rect.width;
            break;
          case 'top':
            top = bounds.top;
            break;
          case 'middle':
            top = bounds.center.dy - shape.rect.height / 2;
            break;
          case 'bottom':
            top = bounds.bottom - shape.rect.height;
            break;
        }
        shape.rect = Rect.fromLTWH(
          left,
          top,
          shape.rect.width,
          shape.rect.height,
        );
      }
    });
    _saveHistorySnapshot();
  }

  void _bringForward() {
    if (selectedShapeIds.length != 1) return;
    final id = selectedShapeIds.first;
    final index = shapes.indexWhere((s) => s.id == id);
    if (index < shapes.length - 1) {
      setState(() {
        final shape = shapes.removeAt(index);
        shapes.insert(index + 1, shape);
      });
      _saveHistorySnapshot();
    }
  }

  void _sendBackward() {
    if (selectedShapeIds.length != 1) return;
    final id = selectedShapeIds.first;
    final index = shapes.indexWhere((s) => s.id == id);
    if (index > 0) {
      setState(() {
        final shape = shapes.removeAt(index);
        shapes.insert(index - 1, shape);
      });
      _saveHistorySnapshot();
    }
  }

  Future<void> _importImageFromDevice() async {
    try {
      _ensureFilePickerInitialized();
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
    if (selectedShapeIds.isEmpty) return;
    final target = shapes.firstWhere((s) => s.id == selectedShapeIds.first);
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: isFill ? target.fillColor : target.strokeColor,
        onColorSelected: (color) {
          setState(() {
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

  // Keyboard Shortcuts Handler
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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
        } else if (event.logicalKey == LogicalKeyboardKey.keyV ||
            event.logicalKey == LogicalKeyboardKey.keyH) {
          setState(() => currentMode = EditorMode.select);
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
    final double zoomScale = _transformationController.value
        .getMaxScaleOnAxis();
    final selectedShape = selectedShapeIds.length == 1
        ? shapes.firstWhere((s) => s.id == selectedShapeIds.first)
        : null;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            // Top Navigation Bar
            TopNavigationBar(
              fileName: fileName,
              onFileNameChanged: (val) => setState(() => fileName = val),
              onUndo: _undo,
              onRedo: _redo,
              canUndo: _undoRedoManager.canUndo,
              canRedo: _undoRedoManager.canRedo,
              snapToGrid: snapToGrid,
              onSnapToGridChanged: (val) => setState(() => snapToGrid = val),
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
              onZoomIn: () {
                setState(() {
                  _transformationController.value =
                      _transformationController.value *
                      Matrix4.diagonal3Values(1.2, 1.2, 1.0);
                });
              },
              onZoomOut: () {
                setState(() {
                  _transformationController.value =
                      _transformationController.value *
                      Matrix4.diagonal3Values(0.8, 0.8, 1.0);
                });
              },
              onResetZoom: () {
                setState(() {
                  _transformationController.value = Matrix4.identity();
                });
              },
              showLayers:
                  isLayersPanelOpen ??
                  (MediaQuery.sizeOf(context).width >= 900.0),
              onToggleLayers: (val) => setState(() => isLayersPanelOpen = val),
              showProperties:
                  isPropertiesPanelOpen ??
                  (MediaQuery.sizeOf(context).width >= 900.0),
              onToggleProperties: (val) =>
                  setState(() => isPropertiesPanelOpen = val),
            ),

            // Main Editor Workbench Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 900.0;
                  final showLayers = isLayersPanelOpen ?? (!isCompact);
                  final showProperties = isPropertiesPanelOpen ?? (!isCompact);

                  final maxSidebarWidth = (constraints.maxWidth * 0.35).clamp(
                    180.0,
                    400.0,
                  );
                  final effectiveLayersWidth = layersSidebarWidth.clamp(
                    160.0,
                    maxSidebarWidth,
                  );
                  final effectivePropertiesWidth = propertiesSidebarWidth.clamp(
                    180.0,
                    maxSidebarWidth,
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
                        _SidebarResizeHandle(
                          onDragUpdate: (deltaDx) {
                            setState(() {
                              layersSidebarWidth =
                                  (layersSidebarWidth + deltaDx).clamp(
                                    160.0,
                                    maxSidebarWidth,
                                  );
                            });
                          },
                          onDoubleTapReset: () {
                            setState(() {
                              layersSidebarWidth = 270.0;
                            });
                          },
                        ),
                      ],

                      // Center Workspace Interactive Canvas
                      Expanded(
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              panEnabled: HardwareKeyboard
                                  .instance
                                  .logicalKeysPressed
                                  .contains(LogicalKeyboardKey.space),
                              scaleEnabled: true,
                              maxScale: 10.0,
                              minScale: 0.1,
                              boundaryMargin: const EdgeInsets.all(2000.0),
                              child: MouseRegion(
                                cursor:
                                    HardwareKeyboard.instance.logicalKeysPressed
                                        .contains(LogicalKeyboardKey.space)
                                    ? (_isPanningWithMouse
                                          ? SystemMouseCursors.grabbing
                                          : SystemMouseCursors.grab)
                                    : SystemMouseCursors.basic,
                                child: Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: _onPointerDown,
                                  onPointerMove: _onPointerMove,
                                  onPointerUp: _onPointerUp,
                                  onPointerCancel: _onPointerCancel,
                                  onPointerSignal: (pointerSignal) {
                                    if (pointerSignal is PointerScrollEvent) {
                                      final isCtrlPressed =
                                          HardwareKeyboard
                                              .instance
                                              .isControlPressed ||
                                          HardwareKeyboard
                                              .instance
                                              .isMetaPressed;
                                      if (isCtrlPressed) {
                                        final double zoomFactor =
                                            pointerSignal.scrollDelta.dy < 0
                                            ? 1.15
                                            : 0.85;
                                        final Offset position =
                                            pointerSignal.localPosition;
                                        final Matrix4 matrix =
                                            _transformationController.value
                                                .clone();
                                        matrix.translate(
                                          position.dx,
                                          position.dy,
                                        );
                                        matrix.scale(zoomFactor, zoomFactor);
                                        matrix.translate(
                                          -position.dx,
                                          -position.dy,
                                        );
                                        setState(() {
                                          _transformationController.value =
                                              matrix;
                                        });
                                      } else {
                                        final Offset delta =
                                            pointerSignal.scrollDelta;
                                        final scale = _transformationController
                                            .value
                                            .getMaxScaleOnAxis();
                                        final Matrix4 matrix =
                                            _transformationController.value
                                                .clone();
                                        matrix.translate(
                                          -delta.dx / scale,
                                          -delta.dy / scale,
                                        );
                                        setState(() {
                                          _transformationController.value =
                                              matrix;
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    width: 3200,
                                    height: 2400,
                                    color: colorScheme.surface,
                                    child: Stack(
                                      children: [
                                        // Grid Background layer with RepaintBoundary
                                        RepaintBoundary(
                                          child: CustomPaint(
                                            size: const Size(3200, 2400),
                                            painter: GridPainter(
                                              gridSpacing: gridSpacing,
                                              gridColor: colorScheme.onSurface
                                                  .withValues(alpha: 0.08),
                                              isDotGrid: true,
                                            ),
                                          ),
                                        ),

                                        // Vector Canvas Painter with RepaintBoundary for high 60fps performance
                                        RepaintBoundary(
                                          child: CustomPaint(
                                            size: const Size(3200, 2400),
                                            painter: VectorCanvasPainter(
                                              shapes: shapes,
                                              selectedShapeIds:
                                                  selectedShapeIds,
                                              draftStartPoint: panStartOffset,
                                              draftCurrentPoint:
                                                  panCurrentOffset,
                                              draftShapeType: draftShapeType,
                                              marqueeRect: marqueeRect,
                                              currentMode: currentMode,
                                              snapGuidelineX: snapGuidelineX,
                                              snapGuidelineY: snapGuidelineY,
                                              colorScheme: colorScheme,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                                width: (constraints.maxWidth * 0.75).clamp(
                                  220.0,
                                  320.0,
                                ),
                                child: Material(
                                  elevation: 8,
                                  color: colorScheme.surfaceContainer,
                                  child: LayersSidebar(
                                    width: (constraints.maxWidth * 0.75).clamp(
                                      220.0,
                                      320.0,
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
                                width: (constraints.maxWidth * 0.78).clamp(
                                  240.0,
                                  340.0,
                                ),
                                child: Material(
                                  elevation: 8,
                                  color: colorScheme.surfaceContainer,
                                  child: PropertiesSidebar(
                                    width: (constraints.maxWidth * 0.78).clamp(
                                      240.0,
                                      340.0,
                                    ),
                                    selectedShape: selectedShape,
                                    onShapeChanged: (updated) {
                                      setState(() {
                                        final index = shapes.indexWhere(
                                          (s) => s.id == updated.id,
                                        );
                                        if (index != -1) {
                                          shapes[index] = updated;
                                        }
                                      });
                                      _saveHistorySnapshot();
                                    },
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

                            // Center Bottom Floating Tool Bar
                            Positioned(
                              bottom: 24,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: FloatingToolBar(
                                  currentMode: currentMode,
                                  onModeChanged: (mode) {
                                    setState(() => currentMode = mode);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Properties Inspector Sidebar (Docked when wide & enabled)
                      if (!isCompact && showProperties) ...[
                        _SidebarResizeHandle(
                          onDragUpdate: (deltaDx) {
                            setState(() {
                              propertiesSidebarWidth =
                                  (propertiesSidebarWidth - deltaDx).clamp(
                                    180.0,
                                    maxSidebarWidth,
                                  );
                            });
                          },
                          onDoubleTapReset: () {
                            setState(() {
                              propertiesSidebarWidth = 280.0;
                            });
                          },
                        ),
                        PropertiesSidebar(
                          width: effectivePropertiesWidth,
                          selectedShape: selectedShape,
                          onShapeChanged: (updated) {
                            setState(() {
                              final index = shapes.indexWhere(
                                (s) => s.id == updated.id,
                              );
                              if (index != -1) {
                                shapes[index] = updated;
                              }
                            });
                            _saveHistorySnapshot();
                          },
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
        return null;
    }
  }

  String _getModeName(EditorMode mode) {
    switch (mode) {
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

class _SidebarResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDoubleTapReset;

  const _SidebarResizeHandle({
    required this.onDragUpdate,
    required this.onDoubleTapReset,
  });

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onDoubleTapReset,
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) =>
            widget.onDragUpdate(details.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragCancel: () => setState(() => _isDragging = false),
        child: Tooltip(
          message: 'Drag to resize sidebar (double-tap to reset)',
          waitDuration: const Duration(milliseconds: 700),
          child: Container(
            width: 8,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: (_isHovered || _isDragging) ? 3 : 1,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _isDragging
                    ? colorScheme.primary
                    : _isHovered
                    ? colorScheme.primary.withValues(alpha: 0.7)
                    : colorScheme.outlineVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
