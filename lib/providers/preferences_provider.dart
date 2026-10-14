import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nixsvg/services/preferences_service.dart';

/// Provider holding the initialized [PreferencesService] instance.
/// Overridden in [ProviderScope] inside `main.dart`, or defaults to
/// in-memory fallback for test harnesses.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService.fallback();
});
