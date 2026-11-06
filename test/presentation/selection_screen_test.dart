import 'dart:convert';
import 'dart:io';

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
import 'package:haidonggumdo/presentation/selection/selection_screen.dart';
import 'package:haidonggumdo/presentation/strings_es.dart';

import '../domain/fakes/fake_screen_wake_lock.dart';
import '../domain/fakes/fake_voice_announcer.dart';
import '../domain/fakes/manual_clock.dart';
import '../domain/fakes/seeded_random_source.dart';

final class _FakeRepository implements CatalogRepository {
  _FakeRepository(this._load);

  final Catalog Function() _load;

  @override
  Future<Catalog> load() async => _load();
}

Map<String, Object?> _pose(List<num> hilt, List<num> tip) => {
  'hilt': hilt,
  'tip': tip,
};

/// Catálogo de prueba con 2 niveles y 2 patrones, escritos en orden inverso
/// para comprobar que se muestran por `order` (SC-009).
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
  CatalogRepository repository,
) async {
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
  await tester.pumpAndSettle();
}

ListTile _tile(WidgetTester tester, String title) => tester.widget<ListTile>(
  find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
);

void main() {
  testWidgets(
    'muestra niveles y patrones por order con el primero elegido (FR-004)',
    (tester) async {
      await _pumpSelection(tester, _FakeRepository(_testCatalog));

      for (final text in ['Level 1', 'Level 2', 'Pattern 1', 'Pattern 2']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('Response 1 — Purpose 1'), findsOneWidget);
      expect(find.text('Guard (다) → Stance A (가) → Cut A (나)'), findsOneWidget);
      expect(find.text('Guard (다) → Stance B → Cut B'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Level 1')).dy,
        lessThan(tester.getTopLeft(find.text('Level 2')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Pattern 1')).dy,
        lessThan(tester.getTopLeft(find.text('Pattern 2')).dy),
      );
      expect(_tile(tester, 'Level 1').selected, isTrue);
      expect(_tile(tester, 'Level 2').selected, isFalse);
      expect(_tile(tester, 'Pattern 1').selected, isTrue);
      expect(_tile(tester, 'Pattern 2').selected, isFalse);
    },
  );

  testWidgets(
    'elegir el segundo nivel y patrón e Iniciar abre el ejercicio con esa sesión (FR-005, SC-009)',
    (tester) async {
      final catalog = _testCatalog();
      await _pumpSelection(tester, _FakeRepository(() => catalog));

      await tester.tap(find.text('Level 2'));
      await tester.tap(find.text('Pattern 2'));
      await tester.pump();
      expect(_tile(tester, 'Level 2').selected, isTrue);
      expect(_tile(tester, 'Pattern 2').selected, isTrue);

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

  testWidgets('con el catálogo real muestra romanización y hangul (FR-003)', (
    tester,
  ) async {
    await _pumpSelection(tester, _FakeRepository(_realCatalog));

    expect(
      find.text('Chayôn-se (자연세) → Chochôn-se (초천세) → Chungmyôn begi (정면베기)'),
      findsOneWidget,
    );
  });

  testWidgets(
    'si el catálogo falla, muestra el error e Iniciar queda desactivado',
    (tester) async {
      await _pumpSelection(
        tester,
        _FakeRepository(
          () => throw const CatalogException('patterns[0].cutTermId'),
        ),
      );

      expect(find.text(StringsEs.catalogError), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(StringsEs.start),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'dos patrones reales: frontal preseleccionado y transversal elegible (Spec 002)',
    (tester) async {
      await _pumpSelection(tester, _FakeRepository(_realCatalog));

      expect(find.text('Frontal'), findsOneWidget);
      expect(find.text('Transversal'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Frontal')).dy,
        lessThan(tester.getTopLeft(find.text('Transversal')).dy),
      );
      expect(_tile(tester, 'Frontal').selected, isTrue);
      expect(_tile(tester, 'Transversal').selected, isFalse);
      expect(
        find.text('Chayôn-se (자연세) → Sodose → Hwengdan ilgôm begi (횡단일검베기)'),
        findsOneWidget,
      );

      await tester.tap(find.text('Transversal'));
      await tester.pump();
      expect(_tile(tester, 'Transversal').selected, isTrue);
      expect(_tile(tester, 'Frontal').selected, isFalse);

      await tester.tap(find.text(StringsEs.start));
      // El ejercicio avanza con un Ticker: no se usa pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final screen = tester.widget<ExerciseScreen>(find.byType(ExerciseScreen));
      expect(screen.session.pattern.id, 'transversal');
    },
  );
}
