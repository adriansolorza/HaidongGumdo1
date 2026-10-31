import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog/asset_catalog_repository.dart';
import '../domain/catalog/catalog.dart';
import '../domain/ports/catalog_repository.dart';
import '../domain/ports/elapsed_clock.dart';
import '../domain/ports/random_source.dart';
import '../domain/ports/screen_wake_lock.dart';
import '../domain/ports/voice_announcer.dart';

// Puertos del dominio. En las pruebas se reemplazan con `overrides`.

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => AssetCatalogRepository(),
);

// Los adaptadores de plataforma se conectan en US1 (T033).
final randomSourceProvider = Provider<RandomSource>(
  (ref) => throw UnimplementedError('randomSourceProvider: se conecta en T033'),
);

final elapsedClockProvider = Provider<ElapsedClock>(
  (ref) => throw UnimplementedError('elapsedClockProvider: se conecta en T033'),
);

final voiceAnnouncerProvider = Provider<VoiceAnnouncer>(
  (ref) =>
      throw UnimplementedError('voiceAnnouncerProvider: se conecta en T033'),
);

final screenWakeLockProvider = Provider<ScreenWakeLock>(
  (ref) =>
      throw UnimplementedError('screenWakeLockProvider: se conecta en T033'),
);

/// Catálogo cargado una vez desde el repositorio.
final catalogProvider = FutureProvider<Catalog>(
  (ref) => ref.watch(catalogRepositoryProvider).load(),
);
