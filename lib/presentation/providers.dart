import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/catalog/asset_catalog_repository.dart';
import '../data/platform/dart_random_source.dart';
import '../data/platform/flutter_tts_voice_announcer.dart';
import '../data/platform/stopwatch_clock.dart';
import '../data/platform/wakelock_plus_screen_wake_lock.dart';
import '../domain/catalog/catalog.dart';
import '../domain/exercise/session.dart';
import '../domain/ports/catalog_repository.dart';
import '../domain/ports/elapsed_clock.dart';
import '../domain/ports/random_source.dart';
import '../domain/ports/screen_wake_lock.dart';
import '../domain/ports/voice_announcer.dart';

// Puertos del dominio. En las pruebas se reemplazan con `overrides`.

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => AssetCatalogRepository(),
);

final randomSourceProvider = Provider<RandomSource>(
  (ref) => DartRandomSource(),
);

final elapsedClockProvider = Provider<ElapsedClock>((ref) => StopwatchClock());

final voiceAnnouncerProvider = Provider<VoiceAnnouncer>(
  (ref) => FlutterTtsVoiceAnnouncer(tts: FlutterTts()),
);

final screenWakeLockProvider = Provider<ScreenWakeLock>(
  (ref) => const WakelockPlusScreenWakeLock(),
);

/// Catálogo cargado una vez desde el repositorio.
final catalogProvider = FutureProvider<Catalog>(
  (ref) => ref.watch(catalogRepositoryProvider).load(),
);

/// Nivel y patrón elegidos en la selección. `null` mientras no hay catálogo.
final selectedSessionProvider =
    NotifierProvider<SelectedSessionNotifier, Session?>(
      SelectedSessionNotifier.new,
    );

final class SelectedSessionNotifier extends Notifier<Session?> {
  /// Por defecto, el primer nivel y el primer patrón (FR-004).
  @override
  Session? build() {
    final catalog = ref.watch(catalogProvider).value;
    if (catalog == null) return null;
    return Session(
      level: catalog.levels.first,
      pattern: catalog.patterns.first,
    );
  }

  void selectLevel(Level level) {
    final current = state;
    if (current == null) return;
    state = Session(level: level, pattern: current.pattern);
  }

  void selectPattern(Pattern pattern) {
    final current = state;
    if (current == null) return;
    state = Session(level: current.level, pattern: pattern);
  }
}
