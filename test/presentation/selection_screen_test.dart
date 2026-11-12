import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/catalog_exception.dart';
import 'package:haidonggumdo/domain/exercise/session.dart';
import 'package:haidonggumdo/domain/ports/catalog_repository.dart';
import 'package:haidonggumdo/presentation/exercise/exercise_screen.dart';
import 'package:haidonggumdo/presentation/providers.dart';
import 'package:haidonggumdo/presentation/selection/level_icon.dart';
import 'package:haidonggumdo/presentation/selection/pattern_icon_painter.dart';
import 'package:haidonggumdo/presentation/selection/selection_card.dart';
import 'package:haidonggumdo/presentation/selection/selection_screen.dart';
import 'package:haidonggumdo/presentation/strings_es.dart';

import '../domain/fakes/fake_screen_wake_lock.dart';
import '../domain/fakes/fake_voice_announcer.dart';
import '../domain/fakes/manual_clock.dart';
import '../domain/fakes/seeded_random_source.dart';

final class _FakeRepository implements CatalogRepository {
  _FakeRepository(this._load);

  final FutureOr<Catalog> Function() _load;

  @override
  Future<Catalog> load() async => _load();
}

Map<String, Object?> _pose(List<num> hilt, List<num> tip) => {
  'hilt': hilt,
  'tip': tip,
};

/// Catálogo de prueba con 2 niveles y 2 patrones, escritos en orden inverso
/// para comprobar que se muestran por `order` (SC-009). `pattern_b` tiene una
/// postura que no existe en el catálogo real (sable arriba a la derecha).
Catalog _testCatalog() => const CatalogJsonMapper().fromJsonString(
  jsonEncode({
    'version': 1,
    'glossary': [
      {'id': 'start', 'romanization': 'Start', 'meaning': 'Inicio'},
      {'id': 'guard', 'romanization': 'Guard', 'hangul': '다', 'meaning': 'G'},
      {'id': 'end', 'romanization': 'End', 'meaning': 'Fin'},
      {
        'id': 'stance_a',
        'romanization': 'Stance A',
        'hangul': '가',
        'meaning': 'A',
      },
      {'id': 'cut_a', 'romanization': 'Cut A', 'hangul': '나', 'meaning': 'A'},
      {'id': 'stance_b', 'romanization': 'Stance B', 'meaning': 'B'},
      {'id': 'cut_b', 'romanization': 'Cut B', 'meaning': 'B'},
    ],
    'voiceCommands': {'start': 'start', 'end': 'end'},
    'levels': [
      for (final (id, order) in [('level_b', 2), ('level_a', 1)])
        {
          'id': id,
          'order': order,
          'name': 'Level $order',
          'responseLabel': 'Response $order',
          'purpose': 'Purpose $order',
          'responseTypes': ['defense'],
        },
    ],
    'patterns': [
      {
        'id': 'pattern_b',
        'order': 2,
        'name': 'Pattern 2',
        'guardTermId': 'guard',
        'stanceTermId': 'stance_b',
        'cutTermId': 'cut_b',
        'guard': _pose([0, 0.05], [0, -0.3]),
        'cut': {
          'start': _pose([0.5, -0.8], [1.2, -1.4]),
          'end': _pose([-0.3, 0.1], [-1.0, 0.4]),
          'mirroredBySide': true,
        },
      },
      {
        'id': 'pattern_a',
        'order': 1,
        'name': 'Pattern 1',
        'guardTermId': 'guard',
        'stanceTermId': 'stance_a',
        'cutTermId': 'cut_a',
        'guard': _pose([0, 0.05], [0, -0.3]),
        'cut': {
          'start': _pose([0, -0.9], [0, -1.6]),
          'end': _pose([0, -0.2], [0, -0.35]),
          'mirroredBySide': false,
        },
      },
    ],
  }),
);

Catalog _realCatalog() => const CatalogJsonMapper().fromJsonString(
  File('assets/catalog/catalog.json').readAsStringSync(),
);

Future<void> _pumpSelection(
  WidgetTester tester,
  CatalogRepository repository, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(repository),
        elapsedClockProvider.overrideWithValue(ManualClock()),
        randomSourceProvider.overrideWithValue(SeededRandomSource(1)),
        voiceAnnouncerProvider.overrideWithValue(FakeVoiceAnnouncer()),
        screenWakeLockProvider.overrideWithValue(FakeScreenWakeLock()),
      ],
      child: const MaterialApp(home: SelectionScreen()),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Finder _cardFinder(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SelectionCard));

SelectionCard _card(WidgetTester tester, String title) =>
    tester.widget<SelectionCard>(_cardFinder(title));

/// Palomitas dentro de la tarjeta [title].
int _checks(String title) => find
    .descendant(
      of: _cardFinder(title),
      matching: find.byKey(const Key('selection-check')),
    )
    .evaluate()
    .length;

FilledButton _startButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(
    of: find.text(StringsEs.start),
    matching: find.byType(FilledButton),
  ),
);

void main() {
  testWidgets('encabezado y subtítulo (FR-020)', (tester) async {
    await _pumpSelection(tester, _FakeRepository(_realCatalog));
    expect(find.text(StringsEs.appHeader), findsOneWidget);
    expect(find.text(StringsEs.appSubtitle), findsOneWidget);
    expect(find.text(StringsEs.levelHeader), findsOneWidget);
    expect(find.text(StringsEs.patternHeader), findsOneWidget);
  });

  testWidgets(
    'muestra niveles y patrones por order con el primero elegido y su '
    'palomita (Spec 001 FR-004; Spec 004 US4-1, US4-4)',
    (tester) async {
      await _pumpSelection(tester, _FakeRepository(_testCatalog));

      for (final text in ['LEVEL 1', 'LEVEL 2', 'PATTERN 1', 'PATTERN 2']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('Response 1 — Purpose 1'), findsOneWidget);
      expect(find.text('Guard → Stance A → Cut A'), findsOneWidget);
      expect(find.text('다 → 가 → 나'), findsOneWidget);
      expect(find.text('Guard → Stance B → Cut B'), findsOneWidget);
      expect(find.text('다'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('LEVEL 1')).dy,
        lessThan(tester.getTopLeft(find.text('LEVEL 2')).dy),
      );
      expect(
        tester.getTopLeft(find.text('PATTERN 1')).dy,
        lessThan(tester.getTopLeft(find.text('PATTERN 2')).dy),
      );
      expect(_card(tester, 'LEVEL 1').selected, isTrue);
      expect(_card(tester, 'LEVEL 2').selected, isFalse);
      expect(_card(tester, 'PATTERN 1').selected, isTrue);
      expect(_card(tester, 'PATTERN 2').selected, isFalse);
      expect(_checks('LEVEL 1'), 1);
      expect(_checks('LEVEL 2'), 0);
      expect(_checks('PATTERN 1'), 1);
      expect(_checks('PATTERN 2'), 0);
      expect(find.text('Level 1 · Pattern 1 · 30 s'), findsOneWidget);
    },
  );

  testWidgets(
    'elegir el segundo nivel y patrón mueve la palomita, cambia el resumen e '
    'INICIAR abre el ejercicio con esa sesión (FR-005, SC-009)',
    (tester) async {
      final catalog = _testCatalog();
      await _pumpSelection(tester, _FakeRepository(() => catalog));

      await tester.tap(find.text('LEVEL 2'));
      await tester.tap(find.text('PATTERN 2'));
      await tester.pump();
      expect(_card(tester, 'LEVEL 2').selected, isTrue);
      expect(_card(tester, 'PATTERN 2').selected, isTrue);
      expect(_checks('LEVEL 1'), 0);
      expect(_checks('LEVEL 2'), 1);
      expect(find.text('Level 2 · Pattern 2 · 30 s'), findsOneWidget);

      await tester.tap(find.text(StringsEs.start));
      // El ejercicio avanza con un Ticker: no se usa pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final screen = tester.widget<ExerciseScreen>(find.byType(ExerciseScreen));
      expect(
        screen.session,
        Session(level: catalog.levels[1], pattern: catalog.patterns[1]),
      );
    },
  );

  testWidgets(
    'con el catálogo real muestra romanización y una línea de hangul sin '
    'huecos (Spec 001 FR-003; Spec 004 FR-022, caso límite)',
    (tester) async {
      await _pumpSelection(tester, _FakeRepository(_realCatalog));

      expect(
        find.text('Chayôn-se → Chochôn-se → Chungmyôn begi'),
        findsOneWidget,
      );
      expect(find.text('자연세 → 초천세 → 정면베기'), findsOneWidget);
      // Sodose no tiene hangul: no deja hueco en la línea.
      expect(
        find.text('Chayôn-se → Sodose → Hwengdan ilgôm begi'),
        findsOneWidget,
      );
      expect(find.text('자연세 → 횡단일검베기'), findsOneWidget);
    },
  );

  testWidgets('cada tarjeta tiene su ícono: la señal del nivel y la silueta '
      'del patrón (US4-2, US4-3)', (tester) async {
    await _pumpSelection(tester, _FakeRepository(_realCatalog));
    for (final title in ['NIVEL 1', 'NIVEL 2']) {
      expect(
        find.descendant(
          of: _cardFinder(title),
          matching: find.byType(LevelIcon),
        ),
        findsOneWidget,
        reason: title,
      );
    }
    for (final title in ['FRONTAL', 'TRANSVERSAL']) {
      final painters = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: _cardFinder(title),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((w) => w.painter)
          .whereType<PatternIconPainter>();
      expect(painters, hasLength(1), reason: title);
    }
  });

  testWidgets(
    'un patrón que no está en el catálogo real tiene ícono sin cambiar código '
    '(FR-022, caso límite)',
    (tester) async {
      final catalog = _testCatalog();
      await _pumpSelection(tester, _FakeRepository(() => catalog));
      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: _cardFinder('PATTERN 2'),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((w) => w.painter)
          .whereType<PatternIconPainter>()
          .single;
      expect(painter.pattern.id, 'pattern_b');

      // Se pinta: hay píxeles blancos en el lienzo del ícono.
      final white = await tester.runAsync(() async {
        const side = 64;
        final recorder = ui.PictureRecorder();
        painter.paint(ui.Canvas(recorder), const Size(64, 64));
        final image = await recorder.endRecording().toImage(side, side);
        final px = (await image.toByteData())!.buffer.asUint8List();
        image.dispose();
        var n = 0;
        for (var i = 0; i < px.length; i += 4) {
          if (px[i] > 240 &&
              px[i + 1] > 240 &&
              px[i + 2] > 240 &&
              px[i + 3] > 240) {
            n++;
          }
        }
        return n;
      });
      expect(white, greaterThan(0));
    },
  );

  testWidgets('si el catálogo falla, muestra el error e INICIAR queda '
      'desactivado (FR-025)', (tester) async {
    await _pumpSelection(
      tester,
      _FakeRepository(
        () => throw const CatalogException('patterns[0].cutTermId'),
      ),
    );

    expect(find.text(StringsEs.catalogError), findsOneWidget);
    expect(_startButton(tester).onPressed, isNull);
  });

  testWidgets('mientras el catálogo carga, INICIAR queda desactivado '
      '(FR-025)', (tester) async {
    final pending = Completer<Catalog>();
    await _pumpSelection(
      tester,
      _FakeRepository(() => pending.future),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(StringsEs.loadingCatalog), findsOneWidget);
    expect(_startButton(tester).onPressed, isNull);
  });

  testWidgets(
    'dos patrones reales: frontal preseleccionado y transversal elegible '
    '(Spec 002)',
    (tester) async {
      await _pumpSelection(tester, _FakeRepository(_realCatalog));

      expect(find.text('FRONTAL'), findsOneWidget);
      expect(find.text('TRANSVERSAL'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('FRONTAL')).dy,
        lessThan(tester.getTopLeft(find.text('TRANSVERSAL')).dy),
      );
      expect(_card(tester, 'FRONTAL').selected, isTrue);
      expect(_card(tester, 'TRANSVERSAL').selected, isFalse);

      await tester.tap(find.text('TRANSVERSAL'));
      await tester.pump();
      expect(_card(tester, 'TRANSVERSAL').selected, isTrue);
      expect(_card(tester, 'FRONTAL').selected, isFalse);

      await tester.tap(find.text(StringsEs.start));
      // El ejercicio avanza con un Ticker: no se usa pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final screen = tester.widget<ExerciseScreen>(find.byType(ExerciseScreen));
      expect(screen.session.pattern.id, 'transversal');
    },
  );

  testWidgets(
    'dos niveles reales: Nivel 1 preseleccionado y Nivel 2 + Transversal en '
    'tres acciones, con su resumen (Spec 003 SC-001; Spec 004 US4-5, SC-008)',
    (tester) async {
      await _pumpSelection(tester, _FakeRepository(_realCatalog));

      expect(find.text('NIVEL 1'), findsOneWidget);
      expect(find.text('NIVEL 2'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('NIVEL 1')).dy,
        lessThan(tester.getTopLeft(find.text('NIVEL 2')).dy),
      );
      expect(
        find.text('Evasión lateral — Calentamiento / base'),
        findsOneWidget,
      );
      expect(_card(tester, 'NIVEL 1').selected, isTrue);
      expect(_card(tester, 'NIVEL 2').selected, isFalse);
      expect(_card(tester, 'FRONTAL').selected, isTrue);
      expect(find.text('Nivel 1 · Frontal · 30 s'), findsOneWidget);

      // Tres acciones: Nivel 2, Transversal, INICIAR.
      await tester.tap(find.text('NIVEL 2'));
      await tester.pump();
      expect(_card(tester, 'NIVEL 2').selected, isTrue);
      expect(_card(tester, 'NIVEL 1').selected, isFalse);
      await tester.tap(find.text('TRANSVERSAL'));
      await tester.pump();
      expect(find.text('Nivel 2 · Transversal · 30 s'), findsOneWidget);
      await tester.tap(find.text(StringsEs.start));
      // El ejercicio avanza con un Ticker: no se usa pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final screen = tester.widget<ExerciseScreen>(find.byType(ExerciseScreen));
      expect(screen.session.level.id, 'level_2');
      expect(screen.session.pattern.id, 'transversal');
    },
  );
}
