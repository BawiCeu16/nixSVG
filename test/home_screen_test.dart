import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/main.dart';
import 'package:nixsvg/providers/preferences_provider.dart';
import 'package:nixsvg/providers/project_provider.dart';
import 'package:nixsvg/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen & Project Flow Tests', () {
    testWidgets('Renders HomeScreen with startup template cards and Mac style header', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefsService = PreferencesService.fallback();
      await prefsService.setHasActiveSession(false);
      await prefsService.setActiveProjectId(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefsService),
          ],
          child: const NixSvgApp(startInWorkspace: false),
        ),
      );
      await tester.pumpAndSettle();

      // Check HomeScreen is rendered
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('New File'), findsOneWidget);
      expect(find.text('Blank Canvas'), findsOneWidget);
      expect(find.text('Start a New Design'), findsOneWidget);
    });

    testWidgets('Opening preset navigates from HomeScreen to FigmaWorkspace', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefsService = PreferencesService.fallback();
      await prefsService.setHasActiveSession(false);
      await prefsService.setActiveProjectId(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefsService),
          ],
          child: const NixSvgApp(startInWorkspace: false),
        ),
      );
      await tester.pumpAndSettle();

      // Find Blank Canvas card and tap it
      final blankCanvasCard = find.text('Blank Canvas');
      expect(blankCanvasCard, findsOneWidget);
      await tester.tap(blankCanvasCard);
      await tester.pumpAndSettle();

      // Verify workspace transitioned
      expect(find.byType(FigmaWorkspace), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Clearing recents via ProjectsNotifier removes recent items', (WidgetTester tester) async {
      final prefsService = PreferencesService.fallback();
      final sample = ProjectModel.createNew(name: 'Test Design');
      await prefsService.saveRecentProject(sample);

      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(projectsProvider).recentProjects.length, 1);
      await container.read(projectsProvider.notifier).clearRecentProjects();
      expect(container.read(projectsProvider).recentProjects.isEmpty, isTrue);
    });
  });
}
