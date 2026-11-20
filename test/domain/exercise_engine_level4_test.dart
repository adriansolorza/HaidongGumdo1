import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_event.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/exercise/exercise_status.dart';
import 'package:haidonggumdo/domain/exercise/session.dart';
import 'package:haidonggumdo/domain/ports/random_source.dart';

import 'fakes/seeded_random_source.dart';
import 'fakes/test_session.dart';

/// Nivel 4 (Spec 007): todo ataque pide contraataque, el motor no cambia
/// (FR-002, FR-004, FR-005; SC-004, SC-005; research R3).
///
/// El oráculo principal: con la misma fuente de aleatoriedad y la misma
/// configuración, el Nivel 4 produce exactamente los ataques del Nivel 2,
/// salvo `responseType`, porque un nivel con un solo tipo no consume sorteo
/// para el tipo (Spec 006, research R2).

const _exercises = 1000;

/// Más allá del fin de cualquier ejercicio de 180 s con su último corte.
const _afterEverything = Duration(seconds: 200);

const _seeds = [1, 42, 2026];

ExerciseEngine _engine(
  Session session,
  RandomSource random, {
  int maxRepeats = 5,
  Duration duration = const Duration(seconds: 30),
}) {
  final d = ExerciseParameters.defaults();
  return ExerciseEngine(
    session: session,
    parameters: ExerciseParameters.create(
      duration: duration,
      maxRepeats: maxRepeats,
      warningTime: d.warningTime,
      cutSpeed: d.cutSpeed,
      attackInterval: d.attackInterval,
    ),
    random: random,
  );
}

/// Ejercicio completo: el motor procesa todos los instantes pendientes en un
/// solo `advanceTo` (es una línea de tiempo pura).
List<ExerciseEvent> _runToEnd(ExerciseEngine engine) {
  engine.start();
  final events = engine.advanceTo(_afterEverything).events;
  expect(engine.status, ExerciseStatus.finished);
  return events;
}

List<Attack> _attacks(List<ExerciseEvent> events) => [
  for (final e in events)
    if (e is SignalShown) e.attack,
];

int _longestStreak<T>(List<T> values) {
  var longest = 0;
  var current = 0;
  for (var i = 0; i < values.length; i++) {
    current = i > 0 && values[i] == values[i - 1] ? current + 1 : 1;
    if (current > longest) longest = current;
  }
  return longest;
}

/// Todo menos el tipo de respuesta, para comparar con el Nivel 2.
(int, Side, Duration, Duration, Duration, Duration) _timing(Attack a) => (
  a.index,
  a.side,
  a.signalAt,
  a.cutStartAt,
  a.cutEndAt,
  a.nextSignalAt,
);

void main() {
  _level4Tests(
    'Nivel 4 transversal (Spec 007, US1)',
    level4: testLevel4TransversalSession,
    level2: testLevel2TransversalSession,
  );
}

/// Casos (a) a (d) de T013 para [level4], comparando con [level2] (mismo
/// patrón). Los usan el transversal (US1) y el frontal (US2).
void _level4Tests(
  String name, {
  required Session Function() level4,
  required Session Function() level2,
}) {
  group(name, () {
    test('(a) todos los ataques piden contraataque (FR-004)', () {
      for (final seed in _seeds) {
        final attacks = _attacks(
          _runToEnd(_engine(level4(), SeededRandomSource(seed))),
        );
        expect(attacks, isNotEmpty, reason: 'semilla $seed');
        expect(
          {for (final a in attacks) a.responseType},
          {ResponseType.counter},
          reason: 'semilla $seed',
        );
      }
    });

    for (final n in [1, 5]) {
      test('(b) N = $n: mismos lados, instantes y fin que el Nivel 2 con la '
          'misma semilla (research R3)', () {
        for (final seed in _seeds) {
          final a = _runToEnd(
            _engine(level4(), SeededRandomSource(seed), maxRepeats: n),
          );
          final b = _runToEnd(
            _engine(level2(), SeededRandomSource(seed), maxRepeats: n),
          );
          expect(
            [for (final x in _attacks(a)) _timing(x)],
            [for (final x in _attacks(b)) _timing(x)],
            reason: 'semilla $seed',
          );
          expect(
            a.whereType<EndVoice>().single.at,
            b.whereType<EndVoice>().single.at,
            reason: 'semilla $seed',
          );
        }
      });
    }

    for (var n = 1; n <= 5; n++) {
      test('(c) N = $n: en $_exercises ejercicios, ninguna racha de lado '
          'mayor que N (SC-004)', () {
        for (var seed = 0; seed < _exercises; seed++) {
          final attacks = _attacks(
            _runToEnd(
              _engine(
                level4(),
                SeededRandomSource(seed),
                maxRepeats: n,
                duration: const Duration(seconds: 180),
              ),
            ),
          );
          expect(
            _longestStreak([for (final a in attacks) a.side]),
            lessThanOrEqualTo(n),
            reason: 'semilla $seed',
          );
        }
      });
    }

    test('(d) N = 5: lados derechos entre 45 % y 55 %; las secuencias cambian '
        'entre semillas (SC-005, RN1)', () {
      final runs = [
        for (var seed = 0; seed < _exercises; seed++)
          _attacks(
            _runToEnd(
              _engine(
                level4(),
                SeededRandomSource(seed),
                duration: const Duration(seconds: 180),
              ),
            ),
          ),
      ];
      final all = [for (final run in runs) ...run];
      expect(all.length, greaterThanOrEqualTo(10000));
      final right = all.where((a) => a.side == Side.right).length / all.length;
      expect(right, inInclusiveRange(0.45, 0.55));

      String key(List<Attack> run) =>
          run.map((a) => '${a.side.index}').join();
      expect({for (final run in runs) key(run)}.length, greaterThan(1));
    });
  });
}
