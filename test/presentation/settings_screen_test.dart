import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/app.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/ports/catalog_repository.dart';
import 'package:haidonggumdo/domain/ports/settings_repository.dart';
import 'package:haidonggumdo/presentation/providers.dart';
import 'package:haidonggumdo/presentation/selection/selection_screen.dart';
import 'package:haidonggumdo/presentation/settings/settings_screen.dart';
import 'package:haidonggumdo/presentation/strings_es.dart';

import '../domain/fakes/fake_screen_wake_lock.dart';
import '../domain/fakes/fake_voice_announcer.dart';
import '../domain/fakes/manual_clock.dart';
import '../domain/fakes/seeded_random_source.dart';
import 'fakes/in_memory_settings_repository.dart';

final class _AssetFileRepository implements CatalogRepository {
  @override
  Future<Catalog> load() async => const CatalogJsonMapper().fromJsonString(
    File('assets/catalog/catalog.json').readAsStringSync(),
  );
}

final class _ThrowingLoadRepository implements SettingsRepository {
  @override
  Future<ExerciseParameters?> load() async => throw StateError('falla');

  @override
  Future<void> save(ExerciseParameters parameters) async {}
}

const _custom = ExerciseParameters(
  duration: Duration(seconds: 75),
  maxRepeats: 1,
  warningTime: Duration(milliseconds: 330),
  cutSpeed: Duration(milliseconds: 500),
  attackInterval: Duration(milliseconds: 2500),
);

/// Monta la app completa (selección como raíz) con la configuración ya
/// cargada desde [settings], como hace `main` (research R5).
Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  SettingsRepository settings, {
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settings),
      catalogRepositoryProvider.overrideWithValue(_AssetFileRepository()),
      elapsedClockProvider.overrideWithValue(ManualClock()),
      randomSourceProvider.overrideWithValue(SeededRandomSource(1)),
      voiceAnnouncerProvider.overrideWithValue(FakeVoiceAnnouncer()),
      screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(exerciseParametersProvider.notifier).load();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const HaidongGumdoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('settingsButton')));
  await tester.pumpAndSettle();
  expect(find.byType(SettingsScreen), findsOneWidget);
}

/// Toca el botón con [key] después de hacerlo visible en la lista.
Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _value(WidgetTester tester, String field) =>
    tester.widget<Text>(find.byKey(Key('value-$field'))).data!;

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed != null;

String _summary(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(SelectionScreen),
        matching: find.byType(Text),
      ),
    )
    .map((t) => t.data ?? '')
    .firstWhere((t) => t.startsWith('Nivel '));

void main() {
  group('US1: ajustar y guardar (Spec 005)', () {
    testWidgets('CONFIGURACIÓN muestra los valores guardados (US1-1)', (
      tester,
    ) async {
      await _pumpApp(tester, InMemorySettingsRepository());
      await _openSettings(tester);
      expect(_value(tester, 'duration'), '30 s');
      expect(_value(tester, 'maxRepeats'), '5');
      expect(_value(tester, 'warningTime'), '0.7 s');
      expect(_value(tester, 'cutSpeed'), '0.5 s');
      expect(_value(tester, 'attackInterval'), '2.5 s');
    });

    testWidgets('− y + avanzan un paso y se desactivan en los límites '
        '(US1-2, US1-3, FR-004a)', (tester) async {
      await _pumpApp(tester, InMemorySettingsRepository());
      await _openSettings(tester);

      for (var i = 0; i < 3; i++) {
        await _tap(tester, 'inc-duration');
      }
      expect(_value(tester, 'duration'), '1 min 15 s');
      for (var i = 0; i < 7; i++) {
        await _tap(tester, 'inc-duration');
      }
      expect(_value(tester, 'duration'), '3 min');
      expect(_enabled(tester, 'inc-duration'), isFalse);
      expect(_enabled(tester, 'dec-duration'), isTrue);

      while (_enabled(tester, 'dec-warningTime')) {
        await _tap(tester, 'dec-warningTime');
      }
      expect(_value(tester, 'warningTime'), '0.33 s');
    });

    testWidgets('GUARDAR guarda y el resumen usa la duración nueva (US1-5)', (
      tester,
    ) async {
      final repo = InMemorySettingsRepository();
      await _pumpApp(tester, repo);
      expect(_summary(tester), endsWith('· 30 s'));
      await _openSettings(tester);

      for (var i = 0; i < 10; i++) {
        await _tap(tester, 'inc-duration');
      }
      await _tap(tester, 'saveButton');

      expect(find.byType(SettingsScreen), findsNothing);
      expect(_summary(tester), endsWith('· 3 min'));
      expect(repo.stored?.duration, const Duration(minutes: 3));
    });

    testWidgets('error al guardar: aviso, sigue en la pantalla y no cambia '
        'nada (FR-013)', (tester) async {
      final repo = InMemorySettingsRepository()..failOnSave = true;
      await _pumpApp(tester, repo);
      await _openSettings(tester);

      await _tap(tester, 'inc-duration');
      expect(find.byKey(const Key('saveError')), findsNothing);
      await _tap(tester, 'saveButton');

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byKey(const Key('saveError')), findsOneWidget);
      expect(_value(tester, 'duration'), '45 s');
      expect(repo.stored, isNull);

      // El siguiente cambio borra el aviso.
      await _tap(tester, 'inc-duration');
      expect(find.byKey(const Key('saveError')), findsNothing);

      // Atrás del sistema.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_summary(tester), endsWith('· 30 s'));
    });

    testWidgets('al reabrir la app se carga la configuración guardada '
        '(US1-7, SC-002, CA7)', (tester) async {
      final repo = InMemorySettingsRepository(stored: _custom);
      final container = await _pumpApp(tester, repo);
      expect(container.read(exerciseParametersProvider), _custom);
      expect(_summary(tester), endsWith('· 1 min 15 s'));

      await _openSettings(tester);
      expect(_value(tester, 'duration'), '1 min 15 s');
      expect(_value(tester, 'maxRepeats'), '1');
      expect(_value(tester, 'warningTime'), '0.33 s');
    });

    testWidgets('si la carga falla se usan los valores por defecto (FR-012)', (
      tester,
    ) async {
      final container = await _pumpApp(tester, _ThrowingLoadRepository());
      expect(
        container.read(exerciseParametersProvider),
        ExerciseParameters.defaults(),
      );
      expect(_summary(tester), endsWith('· 30 s'));
    });
  });

  group('US2: invariante de tiempos al editar (Spec 005)', () {
    String range(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('intervalRange'))).data!;

    Finder notice() => find.byKey(const Key('intervalAdjustedNotice'));

    testWidgets('el rango del sorteo sigue al intervalo (FR-005, US2-2)', (
      tester,
    ) async {
      await _pumpApp(tester, InMemorySettingsRepository());
      await _openSettings(tester);
      expect(range(tester), 'Cada ataque: entre 1.0 s y 2.5 s, al azar');

      while (_enabled(tester, 'dec-attackInterval')) {
        await _tap(tester, 'dec-attackInterval');
      }
      expect(_value(tester, 'attackInterval'), '1.0 s');
      expect(range(tester), 'Cada ataque: 1.0 s');
    });

    testWidgets('subir el corte ajusta el intervalo y lo avisa; bajar el '
        'corte no lo cambia; tocar el intervalo borra el aviso '
        '(US2-1, US2-4, US2-6, FR-008, FR-009)', (tester) async {
      final repo = InMemorySettingsRepository();
      await _pumpApp(tester, repo);
      await _openSettings(tester);
      while (_enabled(tester, 'dec-attackInterval')) {
        await _tap(tester, 'dec-attackInterval');
      }
      expect(notice(), findsNothing);

      for (var i = 0; i < 6; i++) {
        await _tap(tester, 'inc-cutSpeed');
      }
      expect(_value(tester, 'cutSpeed'), '0.8 s');
      expect(_value(tester, 'attackInterval'), '1.3 s');
      expect(notice(), findsOneWidget);
      expect(
        find.descendant(
          of: notice(),
          matching: find.text(
            'Intervalo ajustado a 1.3 s: debe ser al menos la velocidad del '
            'corte + 0.5 s',
          ),
        ),
        findsOneWidget,
      );
      expect(_enabled(tester, 'saveButton'), isTrue);

      await _tap(tester, 'dec-cutSpeed');
      expect(_value(tester, 'attackInterval'), '1.3 s');
      expect(notice(), findsOneWidget);

      await _tap(tester, 'inc-attackInterval');
      expect(notice(), findsNothing);
      expect(_value(tester, 'attackInterval'), '1.4 s');

      await _tap(tester, 'saveButton');
      expect(repo.stored, isNotNull);
      expect(repo.stored!.validate(), isEmpty);
      expect(repo.stored!.cutSpeed, const Duration(milliseconds: 750));
      expect(repo.stored!.attackInterval, const Duration(milliseconds: 1400));
    });

    testWidgets('en 4:3 el aviso queda a la vista al editar el corte', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        InMemorySettingsRepository(),
        size: const Size(1024, 768),
      );
      await _openSettings(tester);
      while (_enabled(tester, 'dec-attackInterval')) {
        await _tap(tester, 'dec-attackInterval');
      }
      // Volver arriba de la lista y subir el corte desde ahí.
      await tester.ensureVisible(find.byKey(const Key('param-duration')));
      await tester.pumpAndSettle();
      await _tap(tester, 'inc-cutSpeed');

      expect(notice(), findsOneWidget);
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      final rect = tester.getRect(notice());
      expect(
        viewport.top <= rect.top && rect.bottom <= viewport.bottom,
        isTrue,
        reason: 'aviso $rect fuera de la lista $viewport',
      );
    });
  });

  group('US3: cancelar y restablecer (Spec 005)', () {
    const stored = ExerciseParameters(
      duration: Duration(seconds: 60),
      maxRepeats: 1,
      warningTime: Duration(milliseconds: 330),
      cutSpeed: Duration(milliseconds: 1000),
      attackInterval: Duration(milliseconds: 5000),
    );

    Future<void> editDurationAndWarning(WidgetTester tester) async {
      await _tap(tester, 'inc-duration');
      await _tap(tester, 'dec-warningTime');
      expect(_value(tester, 'duration'), '45 s');
      expect(_value(tester, 'warningTime'), '0.65 s');
    }

    Future<void> expectUnchanged(
      WidgetTester tester,
      InMemorySettingsRepository repo,
    ) async {
      expect(find.byType(SettingsScreen), findsNothing);
      expect(_summary(tester), endsWith('· 30 s'));
      expect(repo.saveCalls, 0);
      await _openSettings(tester);
      expect(_value(tester, 'duration'), '30 s');
      expect(_value(tester, 'warningTime'), '0.7 s');
    }

    testWidgets('CANCELAR descarta los cambios (US3-1)', (tester) async {
      final repo = InMemorySettingsRepository();
      await _pumpApp(tester, repo);
      await _openSettings(tester);
      await editDurationAndWarning(tester);
      await _tap(tester, 'cancelButton');
      await expectUnchanged(tester, repo);
    });

    testWidgets('Atrás del sistema descarta los cambios (FR-002)', (
      tester,
    ) async {
      final repo = InMemorySettingsRepository();
      await _pumpApp(tester, repo);
      await _openSettings(tester);
      await editDurationAndWarning(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await expectUnchanged(tester, repo);
    });

    testWidgets('RESTABLECER cambia solo el borrador; CANCELAR lo descarta; '
        'GUARDAR lo guarda (US3-2, US3-3, US3-4)', (tester) async {
      final repo = InMemorySettingsRepository(stored: stored);
      await _pumpApp(tester, repo);
      await _openSettings(tester);

      await _tap(tester, 'resetButton');
      expect(_value(tester, 'duration'), '30 s');
      expect(_value(tester, 'maxRepeats'), '5');
      expect(_value(tester, 'warningTime'), '0.7 s');
      expect(_value(tester, 'cutSpeed'), '0.5 s');
      expect(_value(tester, 'attackInterval'), '2.5 s');
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(repo.stored, stored);
      expect(repo.saveCalls, 0);

      await _tap(tester, 'cancelButton');
      expect(repo.stored, stored);
      expect(_summary(tester), endsWith('· 1 min'));

      await _openSettings(tester);
      expect(_value(tester, 'duration'), '1 min');
      await _tap(tester, 'resetButton');
      await _tap(tester, 'saveButton');
      expect(find.byType(SettingsScreen), findsNothing);
      expect(repo.stored, ExerciseParameters.defaults());
      expect(_summary(tester), endsWith('· 30 s'));
    });

    testWidgets('RESTABLECER borra el aviso de ajuste y el error de guardar', (
      tester,
    ) async {
      final repo = InMemorySettingsRepository()..failOnSave = true;
      await _pumpApp(tester, repo);
      await _openSettings(tester);
      while (_enabled(tester, 'dec-attackInterval')) {
        await _tap(tester, 'dec-attackInterval');
      }
      await _tap(tester, 'inc-cutSpeed');
      await _tap(tester, 'saveButton');
      expect(find.byKey(const Key('intervalAdjustedNotice')), findsOneWidget);
      expect(find.byKey(const Key('saveError')), findsOneWidget);

      await _tap(tester, 'resetButton');
      expect(find.byKey(const Key('intervalAdjustedNotice')), findsNothing);
      expect(find.byKey(const Key('saveError')), findsNothing);
    });

    testWidgets('ajuste automático y luego CANCELAR: el intervalo guardado no '
        'cambia', (tester) async {
      const saved = ExerciseParameters(
        duration: Duration(seconds: 30),
        maxRepeats: 5,
        warningTime: Duration(milliseconds: 700),
        cutSpeed: Duration(milliseconds: 500),
        attackInterval: Duration(milliseconds: 1000),
      );
      final repo = InMemorySettingsRepository(stored: saved);
      final container = await _pumpApp(tester, repo);
      await _openSettings(tester);
      for (var i = 0; i < 6; i++) {
        await _tap(tester, 'inc-cutSpeed');
      }
      expect(_value(tester, 'attackInterval'), '1.3 s');
      await _tap(tester, 'cancelButton');

      expect(repo.stored, saved);
      expect(repo.saveCalls, 0);
      expect(container.read(exerciseParametersProvider), saved);
      await _openSettings(tester);
      expect(_value(tester, 'attackInterval'), '1.0 s');
      expect(find.byKey(const Key('intervalAdjustedNotice')), findsNothing);
    });
  });

  group('disposición (FR-019, FR-001)', () {
    const sizes = {
      '4:3': Size(1024, 768),
      '16:10': Size(1280, 800),
      '20:9': Size(2400, 1080),
    };

    void expectInside(WidgetTester tester, Finder finder, Rect screen) {
      final rect = tester.getRect(finder);
      expect(
        screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
        isTrue,
        reason: '$finder en $rect fuera de $screen',
      );
    }

    for (final MapEntry(key: ratio, value: size) in sizes.entries) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('$ratio con letra ×$scale: sin desbordes, acciones a la '
            'vista y lista desplazable', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await _pumpApp(tester, InMemorySettingsRepository(), size: size);
          final screen = Offset.zero & size;

          // Selección: CONFIGURACIÓN e INICIAR dentro y sin superponerse.
          expect(tester.takeException(), isNull);
          final settings = find.byKey(const Key('settingsButton'));
          final start = find.widgetWithText(FilledButton, StringsEs.start);
          expectInside(tester, settings, screen);
          expectInside(tester, start, screen);
          expect(
            tester.getRect(settings).overlaps(tester.getRect(start)),
            isFalse,
          );

          await _openSettings(tester);
          expect(tester.takeException(), isNull);
          for (final key in ['saveButton', 'cancelButton', 'resetButton']) {
            expectInside(tester, find.byKey(Key(key)), screen);
          }

          // La fila del intervalo se alcanza desplazando la lista.
          final interval = find.byKey(const Key('param-attackInterval'));
          await tester.ensureVisible(interval);
          await tester.pumpAndSettle();
          final viewport = tester.getRect(find.byType(SingleChildScrollView));
          final row = tester.getRect(interval);
          expect(
            viewport.top <= row.top + 0.5 &&
                row.bottom <= viewport.bottom + 0.5,
            isTrue,
            reason: 'fila $row fuera de la lista $viewport',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
