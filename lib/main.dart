import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:nixsvg/providers/preferences_provider.dart';
import 'package:nixsvg/providers/project_provider.dart';
import 'package:nixsvg/providers/theme_provider.dart';
import 'package:nixsvg/services/preferences_service.dart';
import 'package:nixsvg/theme/app_theme.dart';
import 'package:nixsvg/theme/components/mui_component_theme.dart';
import 'package:nixsvg/ui/home/home_screen.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:responsive_scaler/responsive_scaler.dart';

export 'package:nixsvg/models/project_model.dart';
export 'package:nixsvg/ui/home/home_screen.dart';
export 'package:nixsvg/ui/workspace/figma_workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureFilePickerInitialized();

  // Initialize persistent preferences with SharedPreferences
  final preferencesService = await PreferencesService.create();

  // Initialize ResponsiveScaler for dynamic cross-platform scaling
  ResponsiveScaler.instance.init(
    designWidth: 1280,
    designHeight: 800,
    minScale: 1.0,
    maxScale: 1.25,
  );

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
      ],
      child: const NixSvgApp(),
    ),
  );
}

/// The root application widget subscribing dynamically to Riverpod [themeProvider].
class NixSvgApp extends StatelessWidget {
  final Widget? home;
  final bool? startInWorkspace;

  const NixSvgApp({
    super.key,
    this.home,
    this.startInWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    Widget app = _NixSvgAppView(
      home: home,
      startInWorkspace: startInWorkspace,
    );
    try {
      ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      app = ProviderScope(child: app);
    }
    return app;
  }
}

class _NixSvgAppView extends ConsumerWidget {
  final Widget? home;
  final bool? startInWorkspace;

  const _NixSvgAppView({
    this.home,
    this.startInWorkspace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ResponsiveScaler.instance.isInitialized) {
      ResponsiveScaler.instance.init(
        designWidth: 1280,
        designHeight: 800,
        minScale: 1.0,
        maxScale: 1.25,
      );
    }

    // Watch dynamic reactive theme state managed by Riverpod & SharedPreferences
    final themeState = ref.watch(themeProvider);
    final seedColor = themeState.seedColor;

    return MaterialApp(
      title: 'nixSVG - Vector Studio',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en', 'US')],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        mui.DefaultMaterialLocalizations.delegate,
      ],
      themeMode: themeState.themeMode,
      theme: AppTheme.buildTheme(
        brightness: Brightness.light,
        seedColor: seedColor,
      ),
      darkTheme: AppTheme.buildTheme(
        brightness: Brightness.dark,
        seedColor: seedColor,
      ),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return mui.Theme(
          data: NixSvgMuiTheme.createTheme(
            brightness: brightness,
            seedColor: seedColor,
          ),
          child: ResponsiveScaler.scale(
            context: context,
            child: child!,
            useMaxAccessibility: true,
          ),
        );
      },
      home: SafeArea(
        child: _buildResolvedHome(ref),
      ),
    );
  }

  Widget _buildResolvedHome(WidgetRef ref) {
    if (home != null) {
      return home!;
    }

    final projectsState = ref.watch(projectsProvider);
    final activeProject = projectsState.activeProject;
    final hasActiveSession = projectsState.hasActiveSession;

    final shouldShowWorkspace = startInWorkspace != null
        ? (startInWorkspace! || hasActiveSession || activeProject != null)
        : (hasActiveSession || activeProject != null);

    if (shouldShowWorkspace) {
      return FigmaWorkspace(
        initialProject: activeProject,
        onGoToHome: () {
          ref.read(projectsProvider.notifier).closeActiveProject();
        },
      );
    }

    return HomeScreen(
      onOpenProject: (proj) {
        ref.read(projectsProvider.notifier).openProject(proj);
      },
    );
  }
}
