import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/app.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/ports/catalog_repository.dart';
import 'package:haidonggumdo/presentation/exercise/exercise_screen.dart';
import 'package:haidonggumdo/presentation/exercise/painters/opponent_painter.dart';
import 'package:haidonggumdo/presentation/exercise/painters/signal_painter.dart';
import 'package:haidonggumdo/presentation/providers.dart';
import 'package:haidonggumdo/presentation/selection/selection_screen.dart';
import 'package:haidonggumdo/presentation/strings_es.dart';

import '../domain/fakes/fake_screen_wake_lock.dart';
import '../domain/fakes/fake_voice_announcer.dart';
import '../domain/fakes/manual_clock.dart';
import '../domain/fakes/scripted_random_source.dart';

final class _AssetFileRepository implements CatalogRepository {
  @override
  Future<Catalog> load() async => const CatalogJsonMapper().fromJsonString(
    File('assets/catalog/catalog.json').readAsStringSync(),
  );
}

Duration _ms(int ms) => Duration(milliseconds: ms);

/// Con todos los sorteos en 0 (lados forzados no consumen sorteo, así que el
/// guion no se desalinea): 1.ª señal en 4.0 s, aviso hasta 4.7 s, corte hasta
/// 5.2 s; E = 33 s cae en un aviso y Guman suena en 34.1 s.
const _warningAt = 4300;
const _cutAt = 4900;
const _finishedAt = 35000;

final class _Harness {
  final clock = ManualClock();
  final random = ScriptedRandomSource(List.filled(500, 0));
  final voice = FakeVoiceAnnouncer();
  final wakeLock = FakeScreenWakeLock();

  /// App completa con la selección como raíz; elige [level] y [pattern] si se
  /// indican (por nombre visible) y pulsa Iniciar.
  Future<void> start(
    WidgetTester tester, {
    String? level,
    String? pattern,
  }) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(_AssetFileRepository()),
          elapsedClockProvider.overrideWithValue(clock),
          randomSourceProvider.overrideWithValue(random),
          voiceAnnouncerProvider.overrideWithValue(voice),
          screenWakeLockProvider.overrideWithValue(wakeLock),
        ],
        child: const HaidongGumdoApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (level != null) {
      await tester.tap(find.text(level));
      await tester.pump();
    }
    if (pattern != null) {
      await tester.tap(find.text(pattern));
      await tester.pump();
    }
    await tester.tap(find.text(StringsEs.start));
    // Deja terminar la transición de la ruta (el reloj manual sigue en 0).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Avanza el reloj manual hasta [ms] en pasos de 100 ms, con un cuadro por paso.
  Future<void> advanceTo(WidgetTester tester, int ms) async {
    while (clock.elapsed.inMilliseconds < ms) {
      final next = clock.elapsed.inMilliseconds + 100;
      clock.set(_ms(next > ms ? ms : next));
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  bool get stopped => voice.calls.contains(const StopCall());
}

void _expectBackOnSelection(WidgetTester tester) {
  expect(find.byType(ExerciseScreen), findsNothing);
  expect(find.byType(SelectionScreen), findsOneWidget);
  expect(
    tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
    isFalse,
  );
}

void main() {
  testWidgets(
    '(a) pantalla encendida, Si-jak, Guman y botones finales (FR-028)',
    (tester) async {
      final h = _Harness();
      await h.start(tester);
      expect(h.wakeLock.enabled, isTrue);
      expect(find.text('3'), findsOneWidget);
      expect(find.text(StringsEs.stop), findsOneWidget);

      await h.advanceTo(tester, 2900);
      expect(h.voice.announced, isEmpty);
      await h.advanceTo(tester, 3000);
      expect(h.voice.announced, [VoiceCommand.start]);

      await h.advanceTo(tester, _finishedAt);
      expect(h.voice.announced, [VoiceCommand.start, VoiceCommand.end]);
      expect(h.wakeLock.enabled, isFalse);
      expect(find.text(StringsEs.repeat), findsOneWidget);
      expect(find.text(StringsEs.back), findsOneWidget);
      expect(find.text(StringsEs.stop), findsNothing);
    },
  );

  testWidgets(
    '(b) Detener durante el aviso cancela sin más sonidos (FR-021, FR-023, SC-008)',
    (tester) async {
      final h = _Harness();
      await h.start(tester);
      await h.advanceTo(tester, _warningAt);

      await tester.tap(find.text(StringsEs.stop));
      await tester.pumpAndSettle();

      expect(h.stopped, isTrue);
      expect(h.wakeLock.enabled, isFalse);
      _expectBackOnSelection(tester);

      await h.advanceTo(tester, 40000);
      expect(h.voice.announced, [VoiceCommand.start]);
    },
  );

  testWidgets(
    '(c) hidden y paused durante el corte cancelan y navegan una sola vez (FR-022)',
    (tester) async {
      final h = _Harness();
      await h.start(tester);
      await h.advanceTo(tester, _cutAt);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(h.stopped, isTrue);
      expect(h.wakeLock.enabled, isFalse);
      expect(h.voice.calls.whereType<StopCall>(), hasLength(1));

      // En segundo plano no se dibujan cuadros: la selección se ve al volver.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      _expectBackOnSelection(tester);

      await h.advanceTo(tester, 40000);
      expect(h.voice.announced, [VoiceCommand.start]);
    },
  );

  testWidgets('(d) inactive solo no cancela (R10)', (tester) async {
    final h = _Harness();
    await h.start(tester);
    await h.advanceTo(tester, _warningAt);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await h.advanceTo(tester, 6000);

    expect(h.stopped, isFalse);
    expect(h.wakeLock.enabled, isTrue);
    expect(find.byType(ExerciseScreen), findsOneWidget);
    expect(find.text(StringsEs.stop), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('(e) cancelar en la cuenta regresiva: nunca suena Si-jak', (
    tester,
  ) async {
    final h = _Harness();
    await h.start(tester);
    await h.advanceTo(tester, 1500);

    await tester.tap(find.text(StringsEs.stop));
    await tester.pumpAndSettle();
    await h.advanceTo(tester, 10000);

    expect(h.voice.announced, isEmpty);
    expect(h.stopped, isTrue);
    _expectBackOnSelection(tester);
  });

  testWidgets('(f) Repetir empieza otra cuenta con sorteos nuevos (FR-014)', (
    tester,
  ) async {
    final h = _Harness();
    await h.start(tester);
    await h.advanceTo(tester, _finishedAt);
    final consumedBefore = h.random.consumed;

    await tester.tap(find.text(StringsEs.repeat));
    await tester.pump();
    expect(h.clock.elapsed, Duration.zero);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('3'), findsOneWidget);
    expect(h.wakeLock.enabled, isTrue);

    await h.advanceTo(tester, 3000);
    expect(h.voice.announced, [
      VoiceCommand.start,
      VoiceCommand.end,
      VoiceCommand.start,
    ]);

    await h.advanceTo(tester, 5000);
    expect(h.random.consumed, greaterThan(consumedBefore));
  });

  testWidgets(
    '(g) Repetir conserva el transversal y Volver permite elegir el frontal (Spec 002)',
    (tester) async {
      final h = _Harness();
      await h.start(tester, pattern: 'Transversal');
      String patternId() => tester
          .widget<ExerciseScreen>(find.byType(ExerciseScreen))
          .session
          .pattern
          .id;
      expect(patternId(), 'transversal');

      await h.advanceTo(tester, _finishedAt);
      await tester.tap(find.text(StringsEs.repeat));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('3'), findsOneWidget);
      expect(patternId(), 'transversal');

      await h.advanceTo(tester, _finishedAt);
      await tester.tap(find.text(StringsEs.back));
      await tester.pumpAndSettle();
      _expectBackOnSelection(tester);

      await tester.tap(find.text('Frontal'));
      await tester.pump();
      await tester.tap(find.text(StringsEs.start));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(patternId(), 'frontal');
    },
  );

  testWidgets(
    '(h) Nivel 2 transversal: flecha de evasión del color del oponente, sin '
    'defensa; sin flecha tras el corte (Spec 003, FR-009)',
    (tester) async {
      final h = _Harness();
      await h.start(tester, level: 'Nivel 2', pattern: 'Transversal');
      final session = tester
          .widget<ExerciseScreen>(find.byType(ExerciseScreen))
          .session;
      expect(session.level.id, 'level_2');
      expect(session.pattern.id, 'transversal');

      Iterable<CustomPainter> painters() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<CustomPainter>();

      // Aviso del 1.er ataque (sorteo 0 → right, azul) y corte.
      for (final ms in [_warningAt, _cutAt]) {
        await h.advanceTo(tester, ms);
        final signals = painters().whereType<SignalPainter>().toList();
        final opponent = painters().whereType<OpponentPainter>().single;
        expect(signals, hasLength(1), reason: '$ms ms');
        expect(signals.single.signal.responseType, ResponseType.evasion);
        expect(signals.single.signal.screenSide, Side.right);
        expect(signals.single.saberColor, SaberColor.blue);
        expect(signals.single.saberColor, opponent.saberColor);
      }

      // Corte hasta 5.2 s; la señal siguiente llega en 5.7 s.
      await h.advanceTo(tester, 5400);
      expect(painters().whereType<SignalPainter>(), isEmpty);
    },
  );
}
